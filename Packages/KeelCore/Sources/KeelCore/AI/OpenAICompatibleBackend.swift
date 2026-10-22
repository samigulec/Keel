import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Any service that speaks the OpenAI Chat Completions format: OpenAI,
/// Google Gemini's compatible endpoint, OpenRouter, or a local Ollama / LM Studio.
public struct OpenAICompatibleBackend: ChatBackend {
    public struct Preset: Identifiable, Equatable, Sendable {
        public let id: String
        public let name: String
        public let baseURL: String
        public let needsKey: Bool
        public let modelHint: String
    }

    public static let presets: [Preset] = [
        Preset(id: "openai", name: "OpenAI", baseURL: "https://api.openai.com/v1", needsKey: true, modelHint: "Model adı, örn. OpenAI hesabındaki bir sohbet modeli"),
        Preset(id: "gemini", name: "Google Gemini", baseURL: "https://generativelanguage.googleapis.com/v1beta/openai", needsKey: true, modelHint: "Gemini model adı"),
        Preset(id: "openrouter", name: "OpenRouter", baseURL: "https://openrouter.ai/api/v1", needsKey: true, modelHint: "sağlayıcı/model biçiminde"),
        Preset(id: "ollama", name: "Ollama (yerel)", baseURL: "http://localhost:11434/v1", needsKey: false, modelHint: "Bilgisayarındaki model, örn. `ollama list` çıktısından"),
        Preset(id: "lmstudio", name: "LM Studio (yerel)", baseURL: "http://localhost:1234/v1", needsKey: false, modelHint: "LM Studio'da yüklü model"),
    ]

    public let baseURL: URL
    public let apiKey: String?
    public let model: String

    public init(baseURL: URL, apiKey: String?, model: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
    }

    public func userMessage(_ text: String) -> JSONValue {
        ["role": "user", "content": .string(text)]
    }

    public func request(system: String, history: [JSONValue], tools: [ToolDefinition]) throws -> URLRequest {
        var body: [String: JSONValue] = [
            "model": .string(model),
            "stream": true,
            "messages": .array([["role": "system", "content": .string(system)]] + history),
        ]
        if !tools.isEmpty {
            body["tools"] = .array(tools.map { tool in
                [
                    "type": "function",
                    "function": [
                        "name": .string(tool.name),
                        "description": .string(tool.description),
                        "parameters": tool.inputSchema,
                    ],
                ]
            })
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        if let apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "authorization")
        }
        request.httpBody = try JSONValue.object(body).encoded()
        request.timeoutInterval = 600
        return request
    }

    public func makeAccumulator() -> any TurnAccumulator {
        OpenAIStreamAccumulator()
    }

    public func toolResultMessages(_ results: [ToolResultPayload]) -> [JSONValue] {
        results.map { result in
            [
                "role": "tool",
                "tool_call_id": .string(result.callID),
                "content": .string(result.isError ? "ERROR: \(result.content)" : result.content),
            ]
        }
    }
}

struct OpenAIStreamAccumulator: TurnAccumulator {
    private struct PendingCall {
        var id = ""
        var name = ""
        var arguments = ""
    }

    private var text = ""
    private var calls: [Int: PendingCall] = [:]
    private var finishReason: String?

    mutating func consume(_ event: SSEEvent) throws -> String? {
        guard event.data != "[DONE]", let payload = try? JSONValue.parse(event.data) else { return nil }
        if let error = payload["error"] {
            throw AIError.stream(
                type: error["type"]?.stringValue ?? "error",
                message: error["message"]?.stringValue ?? event.data
            )
        }
        guard let choice = payload["choices"]?.arrayValue?.first else { return nil }
        if let reason = choice["finish_reason"]?.stringValue {
            finishReason = reason
        }
        let delta = choice["delta"]
        for fragment in delta?["tool_calls"]?.arrayValue ?? [] {
            let index = fragment["index"]?.numberValue.map(Int.init) ?? 0
            var call = calls[index] ?? PendingCall()
            if let id = fragment["id"]?.stringValue { call.id = id }
            if let name = fragment["function"]?["name"]?.stringValue { call.name += name }
            if let arguments = fragment["function"]?["arguments"]?.stringValue { call.arguments += arguments }
            calls[index] = call
        }
        guard let content = delta?["content"]?.stringValue, !content.isEmpty else { return nil }
        text += content
        return content
    }

    func finish() throws -> BackendTurn {
        let ordered = calls.keys.sorted().compactMap { calls[$0] }
        let toolCalls = ordered.enumerated().map { offset, call in
            let input = call.arguments.isEmpty ? JSONValue.object([:]) : (try? JSONValue.parse(call.arguments))
            return ToolCall(
                id: call.id.isEmpty ? "call_\(offset)" : call.id,
                name: call.name,
                input: input?.objectValue != nil ? input : nil,
                rawInput: call.arguments
            )
        }

        var message: [String: JSONValue] = ["role": "assistant", "content": text.isEmpty ? .null : .string(text)]
        if !toolCalls.isEmpty {
            message["tool_calls"] = .array(zip(toolCalls, ordered).map { call, pending in
                [
                    "id": .string(call.id),
                    "type": "function",
                    "function": ["name": .string(call.name), "arguments": .string(pending.arguments.isEmpty ? "{}" : pending.arguments)],
                ]
            })
        }

        let reason: StopReason = switch finishReason {
        case "tool_calls", "function_call": .toolUse
        case "length": .maxTokens
        case "content_filter": .refusal(category: nil)
        case "stop", nil: toolCalls.isEmpty ? .endTurn : .toolUse
        case let other?: .other(other)
        }

        return BackendTurn(assistantMessage: .object(message), text: text, toolCalls: toolCalls, stopReason: reason)
    }
}
