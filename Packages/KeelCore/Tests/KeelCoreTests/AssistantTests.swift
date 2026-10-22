import Foundation
import Testing
@testable import KeelCore

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Replays scripted SSE responses, one per request, and records the requests.
final class ScriptedTransport: StreamingTransport, @unchecked Sendable {
    private var responses: [[String]]
    private(set) var requests: [URLRequest] = []
    var failWith: (any Error)?

    init(_ responses: [[String]]) {
        self.responses = responses
    }

    func lines(for request: URLRequest) async throws -> AsyncThrowingStream<String, any Error> {
        requests.append(request)
        if let failWith { throw failWith }
        let lines = responses.isEmpty ? [] : responses.removeFirst()
        return AsyncThrowingStream { continuation in
            lines.forEach { continuation.yield($0) }
            continuation.finish()
        }
    }

    func body(_ index: Int) throws -> JSONValue {
        try JSONValue.parse(try #require(requests[index].httpBody))
    }
}

/// Builds Claude stream lines the way the API sends them.
enum ClaudeStream {
    static func event(_ json: String) -> [String] {
        let type = (try? JSONValue.parse(json))?["type"]?.stringValue ?? ""
        return ["event: \(type)", "data: \(json)", ""]
    }

    static func text(_ chunks: [String], stop: String = "end_turn") -> [String] {
        var lines = event(#"{"type":"message_start","message":{"id":"msg_1","model":"claude-opus-5-5","role":"assistant","content":[],"usage":{"input_tokens":1000,"cache_read_input_tokens":9000,"cache_creation_input_tokens":0}}}"#)
        lines += event(#"{"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":"","signature":""}}"#)
        lines += event(#"{"type":"content_block_delta","index":0,"delta":{"type":"signature_delta","signature":"sig-abc"}}"#)
        lines += event(#"{"type":"content_block_stop","index":0}"#)
        lines += event(#"{"type":"content_block_start","index":1,"content_block":{"type":"text","text":""}}"#)
        for chunk in chunks {
            lines += event(#"{"type":"content_block_delta","index":1,"delta":{"type":"text_delta","text":"\#(chunk)"}}"#)
        }
        lines += event(#"{"type":"content_block_stop","index":1}"#)
        lines += event(#"{"type":"message_delta","delta":{"stop_reason":"\#(stop)"},"usage":{"output_tokens":5}}"#)
        lines += event(#"{"type":"message_stop"}"#)
        return lines
    }

    static func toolUse(id: String, name: String, inputFragments: [String]) -> [String] {
        var lines = event(#"{"type":"message_start","message":{"id":"msg_2","role":"assistant","content":[]}}"#)
        lines += event(#"{"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}"#)
        lines += event(#"{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Bakıyorum."}}"#)
        lines += event(#"{"type":"content_block_stop","index":0}"#)
        lines += event(#"{"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"\#(id)","name":"\#(name)","input":{}}}"#)
        for fragment in inputFragments {
            let escaped = JSONValue.string(fragment).encodedString()
            lines += event(#"{"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":\#(escaped)}}"#)
        }
        lines += event(#"{"type":"content_block_stop","index":1}"#)
        lines += event(#"{"type":"message_delta","delta":{"stop_reason":"tool_use"}}"#)
        lines += event(#"{"type":"message_stop"}"#)
        return lines
    }
}

@MainActor
@Suite("Assistant")
struct AssistantTests {
    func engine(_ transport: ScriptedTransport, backend: any ChatBackend = AnthropicBackend(apiKey: "test-key"), tools: [AITool] = []) -> AssistantEngine {
        AssistantEngine(backend: backend, transport: transport, systemPrompt: "You are Keel AI.", tools: tools)
    }

    var statusTool: AITool {
        AITool(
            name: "get_system_status",
            description: "Reads the Mac's status.",
            inputSchema: ["type": "object", "properties": ["detail": ["type": "string"]], "additionalProperties": false],
            run: { input in #"{"memory":"12 GB","detail":"\#(input["detail"]?.stringValue ?? "")"}"# }
        )
    }

    // MARK: Parsing

    @Test func sseParserKeepsEventNamesAndSkipsNoise() {
        var parser = SSEParser()
        #expect(parser.feed(": keep-alive") == nil)
        #expect(parser.feed("event: ping") == nil)
        #expect(parser.feed(#"data: {"type":"ping"}"#) == SSEEvent(event: "ping", data: #"{"type":"ping"}"#))
        #expect(parser.feed("data: [DONE]") == SSEEvent(event: nil, data: "[DONE]"))
    }

    @Test func jsonRoundTripWritesIntegersAndSortedKeys() throws {
        let value: JSONValue = ["b": 64000, "a": [true, nil, 1.5, "x"]]
        #expect(value.encodedString() == #"{"a":[true,null,1.5,"x"],"b":64000}"#)
        #expect(try JSONValue.parse(value.encodedString()) == value)
    }

    // MARK: Claude

    @Test func claudeRequestFollowsTheCurrentAPI() async throws {
        let transport = ScriptedTransport([ClaudeStream.text(["Merhaba"])])
        let engine = engine(transport, tools: [statusTool])
        try await engine.send("Selam") { _ in }

        let request = try #require(transport.requests.first)
        #expect(request.url?.absoluteString == "https://api.anthropic.com/v1/messages")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "test-key")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2026-10-21")
        #expect(request.value(forHTTPHeaderField: "anthropic-beta") == "server-side-fallback-2026-07-01")

        let body = try transport.body(0)
        #expect(body["model"] == "claude-opus-5-5")
        #expect(body["stream"] == true)
        #expect(body["max_tokens"] == 64000)
        #expect(body["fallbacks"] == "default")
        #expect(body["output_config"]?["effort"] == "medium")
        #expect(body["temperature"] == nil)
        #expect(body["thinking"] == nil)
        #expect(body["tools"]?.arrayValue?.first?["eager_input_streaming"] == true)
        #expect(body["system"]?.arrayValue?.first?["text"] == "You are Keel AI.")
    }

    @Test func haikuGetsNoFallbackParameter() async throws {
        let transport = ScriptedTransport([ClaudeStream.text(["ok"])])
        let engine = engine(transport, backend: AnthropicBackend(apiKey: "k", model: "claude-haiku-5-5"))
        try await engine.send("hi") { _ in }
        #expect(transport.requests[0].value(forHTTPHeaderField: "anthropic-beta") == nil)
        #expect(try transport.body(0)["fallbacks"] == nil)
    }

    @Test func streamsTextAndKeepsThinkingForReplay() async throws {
        let transport = ScriptedTransport([ClaudeStream.text(["Mer", "haba!"])])
        let engine = engine(transport)
        var events: [AssistantEvent] = []
        try await engine.send("Selam") { events.append($0) }

        #expect(events.filter { if case .usage = $0 { false } else { true } }
            == [.textDelta("Mer"), .textDelta("haba!"), .stopped(.endTurn)])
        #expect(engine.history.count == 2)
        let content = try #require(engine.history[1]["content"]?.arrayValue)
        #expect(content[0]["type"] == "thinking")
        #expect(content[0]["signature"] == "sig-abc")
        #expect(content[1]["text"] == "Merhaba!")
    }

    @Test func reportsUsageWithEstimatedCost() async throws {
        let engine = engine(ScriptedTransport([ClaudeStream.text(["ok"])]))
        var usage: TurnUsage?
        try await engine.send("?") { if case .usage(let value) = $0 { usage = value } }
        let reported = try #require(usage)
        #expect(reported.model == "claude-opus-5-5")
        #expect(reported.contextTokens == 10_005)
        #expect(reported.contextWindow == 1_000_000)
        // 1000 in x $4 + 9000 cached x $0.20 + 5 out x $20, per million
        #expect(abs((reported.costUSD ?? 0) - 0.0059) < 0.000_001)
    }

    @Test func runsToolsAndSendsResultsBack() async throws {
        let transport = ScriptedTransport([
            ClaudeStream.toolUse(id: "toolu_1", name: "get_system_status", inputFragments: [#"{"det"#, #"ail": "ram"}"#]),
            ClaudeStream.text(["12 GB kullanılıyor."]),
        ])
        let engine = engine(transport, tools: [statusTool])
        var events: [AssistantEvent] = []
        try await engine.send("RAM durumu?") { events.append($0) }

        #expect(events.contains(.toolStarted(id: "toolu_1", name: "get_system_status")))
        #expect(events.contains(.toolFinished(id: "toolu_1", name: "get_system_status", isError: false)))
        // user, assistant(tool_use), user(tool_result), assistant(text)
        #expect(engine.history.map { $0["role"]?.stringValue } == ["user", "assistant", "user", "assistant"])
        let toolUse = try #require(engine.history[1]["content"]?.arrayValue?.last)
        #expect(toolUse["input"] == ["detail": "ram"])
        let result = try #require(engine.history[2]["content"]?.arrayValue?.first)
        #expect(result["type"] == "tool_result")
        #expect(result["tool_use_id"] == "toolu_1")
        #expect(result["content"]?.stringValue?.contains("\"detail\":\"ram\"") == true)

        // The second request carries the first exchange unchanged.
        let second = try transport.body(1)
        #expect(second["messages"]?.arrayValue?.count == 3)
    }

    @Test func invalidToolJSONIsReportedNotRun() async throws {
        var ran = false
        let tool = AITool(name: "get_system_status", description: "", inputSchema: ["type": "object"]) { _ in
            ran = true
            return "{}"
        }
        let transport = ScriptedTransport([
            ClaudeStream.toolUse(id: "toolu_9", name: "get_system_status", inputFragments: [#"{"detail": "ra"#]),
            ClaudeStream.text(["Tekrar deniyorum."]),
        ])
        let engine = engine(transport, tools: [tool])
        try await engine.send("?") { _ in }

        #expect(!ran)
        let result = try #require(engine.history[2]["content"]?.arrayValue?.first)
        #expect(result["is_error"] == true)
        #expect(result["content"]?.stringValue?.contains("INVALID_JSON") == true)
    }

    @Test func refusalStopsWithoutRunningTools() async throws {
        let transport = ScriptedTransport([ClaudeStream.text(["..."], stop: "refusal")])
        let engine = engine(transport)
        var events: [AssistantEvent] = []
        try await engine.send("?") { events.append($0) }
        #expect(events.last == .stopped(.refusal(category: nil)))
        #expect(transport.requests.count == 1)
    }

    @Test func failureRollsBackTheWholeExchange() async throws {
        let transport = ScriptedTransport([ClaudeStream.text(["İlk yanıt"])])
        let engine = engine(transport)
        try await engine.send("Bir") { _ in }
        #expect(engine.history.count == 2)

        transport.failWith = AIError.http(status: 529, message: "Overloaded")
        await #expect(throws: AIError.http(status: 529, message: "Overloaded")) {
            try await engine.send("İki") { _ in }
        }
        #expect(engine.history.count == 2)
    }

    @Test func streamErrorEventThrows() async throws {
        let lines = ClaudeStream.event(#"{"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}"#)
        let engine = engine(ScriptedTransport([lines]))
        await #expect(throws: AIError.stream(type: "overloaded_error", message: "Overloaded")) {
            try await engine.send("?") { _ in }
        }
        #expect(engine.history.isEmpty)
    }

    @Test func errorBodiesYieldTheProviderMessage() {
        #expect(errorMessage(fromBody: #"{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}"#) == "invalid x-api-key")
        #expect(errorMessage(fromBody: #"{"error":{"message":"Incorrect API key provided"}}"#) == "Incorrect API key provided")
        #expect(errorMessage(fromBody: "Bad gateway") == "Bad gateway")
    }

    // MARK: OpenAI-compatible

    @Test func openAICompatibleToolLoop() async throws {
        let first = [
            #"data: {"choices":[{"index":0,"delta":{"role":"assistant","tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"get_system_status","arguments":""}}]}}]}"#,
            #"data: {"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\"detail\":"}}]}}]}"#,
            #"data: {"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"function":{"arguments":"\"cpu\"}"}}]}}]}"#,
            #"data: {"choices":[{"index":0,"delta":{},"finish_reason":"tool_calls"}]}"#,
            "data: [DONE]",
        ]
        let second = [
            #"data: {"choices":[{"index":0,"delta":{"content":"İşlemci "}}]}"#,
            #"data: {"choices":[{"index":0,"delta":{"content":"rahat."},"finish_reason":"stop"}]}"#,
            "data: [DONE]",
        ]
        let transport = ScriptedTransport([first, second])
        let backend = OpenAICompatibleBackend(baseURL: URL(string: "http://localhost:11434/v1")!, apiKey: nil, model: "local-model")
        let engine = engine(transport, backend: backend, tools: [statusTool])
        var text = ""
        try await engine.send("CPU?") { if case .textDelta(let delta) = $0 { text += delta } }

        #expect(text == "İşlemci rahat.")
        #expect(transport.requests[0].url?.absoluteString == "http://localhost:11434/v1/chat/completions")
        #expect(transport.requests[0].value(forHTTPHeaderField: "authorization") == nil)
        let body = try transport.body(0)
        #expect(body["messages"]?.arrayValue?.first?["role"] == "system")
        #expect(body["tools"]?.arrayValue?.first?["function"]?["name"] == "get_system_status")

        #expect(engine.history.map { $0["role"]?.stringValue } == ["user", "assistant", "tool", "assistant"])
        #expect(engine.history[1]["tool_calls"]?.arrayValue?.first?["function"]?["arguments"] == #"{"detail":"cpu"}"#)
        #expect(engine.history[2]["tool_call_id"] == "call_1")
    }

    @Test func openAIKeyGoesInBearerHeader() throws {
        let backend = OpenAICompatibleBackend(baseURL: URL(string: "https://api.openai.com/v1")!, apiKey: "sk-test", model: "m")
        let request = try backend.request(system: "s", history: [], tools: [])
        #expect(request.value(forHTTPHeaderField: "authorization") == "Bearer sk-test")
    }
}

struct StubHTTPClient: HTTPClient {
    let status: Int
    let body: String

    func data(for request: URLRequest) async throws -> (Data, Int) {
        (Data(body.utf8), status)
    }
}

@Suite("ModelCatalog")
struct ModelCatalogTests {
    @Test func listsClaudeModels() async throws {
        let client = StubHTTPClient(status: 200, body: #"{"data":[{"type":"model","id":"claude-opus-5-5","display_name":"Claude Opus 5.5"},{"type":"model","id":"claude-haiku-5-5"}],"has_more":false}"#)
        #expect(try await ModelCatalog.claudeModels(apiKey: "k", client: client) == ["claude-opus-5-5", "claude-haiku-5-5"])
    }

    @Test func badKeyIsAnHTTPError() async throws {
        let client = StubHTTPClient(status: 401, body: #"{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}"#)
        await #expect(throws: AIError.http(status: 401, message: "invalid x-api-key")) {
            try await ModelCatalog.claudeModels(apiKey: "bad", client: client)
        }
    }

    @Test func listsOpenAICompatibleModels() async throws {
        let client = StubHTTPClient(status: 200, body: #"{"object":"list","data":[{"id":"llama3.2","object":"model"}]}"#)
        let models = try await ModelCatalog.openAICompatibleModels(baseURL: URL(string: "http://localhost:11434/v1")!, apiKey: nil, client: client)
        #expect(models == ["llama3.2"])
    }

    @Test func unexpectedBodyIsReported() {
        #expect(throws: AIError.invalidResponse("Model listesi okunamadı")) {
            try ModelCatalog.parseModelIDs(#"{"models":[]}"#)
        }
    }
}
