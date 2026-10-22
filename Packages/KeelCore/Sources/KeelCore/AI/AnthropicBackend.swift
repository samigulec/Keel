import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Claude through the Messages API, called directly over HTTP.
public struct AnthropicBackend: ChatBackend {
    public struct Model: Identifiable, Equatable, Sendable {
        public let id: String
        public let name: String
        public let summary: String
    }

    /// Current models, most capable everyday choice first.
    public static let models: [Model] = [
        Model(id: "claude-opus-5-5", name: "Claude Opus 5.5", summary: "Önerilen: en iyi denge"),
        Model(id: "claude-sonnet-5-5", name: "Claude Sonnet 5.5", summary: "Hızlı ve daha ucuz"),
        Model(id: "claude-haiku-5-5", name: "Claude Haiku 5.5", summary: "En hızlı, en ucuz"),
        Model(id: "claude-fable-5-1", name: "Claude Fable 5.1", summary: "En güçlü, en pahalı"),
    ]

    public static let defaultModel = "claude-opus-5-5"
    static let apiVersion = "2026-10-21"
    static let fallbackBeta = "server-side-fallback-2026-07-01"
    /// Models that accept `fallbacks: "default"`: a declined request is
    /// re-run on a suitable model instead of simply stopping.
    static let fallbackModels: Set<String> = ["claude-opus-5-5", "claude-fable-5-1", "claude-opus-5", "claude-sonnet-5-5"]

    public let apiKey: String
    public let model: String
    public var baseURL = URL(string: "https://api.anthropic.com/v1")!
    public var maxTokens = 64_000
    public var effort = "medium"

    public init(apiKey: String, model: String = AnthropicBackend.defaultModel) {
        self.apiKey = apiKey
        self.model = model
    }

    public func userMessage(_ text: String) -> JSONValue {
        ["role": "user", "content": .string(text)]
    }

    public func request(system: String, history: [JSONValue], tools: [ToolDefinition]) throws -> URLRequest {
        var body: [String: JSONValue] = [
            "model": .string(model),
            "max_tokens": .number(Double(maxTokens)),
            "stream": true,
            "system": .array([["type": "text", "text": .string(system)]]),
            "messages": .array(history),
            "output_config": ["effort": .string(effort)],
            // Caches the stable prefix (tools, system, earlier turns) across turns.
            "cache_control": ["type": "ephemeral"],
        ]
        if !tools.isEmpty {
            body["tools"] = .array(tools.map { tool in
                [
                    "name": .string(tool.name),
                    "description": .string(tool.description),
                    "input_schema": tool.inputSchema,
                    "eager_input_streaming": true,
                ]
            })
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("messages"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
        if Self.fallbackModels.contains(model) {
            body["fallbacks"] = "default"
            request.setValue(Self.fallbackBeta, forHTTPHeaderField: "anthropic-beta")
        }
        request.httpBody = try JSONValue.object(body).encoded()
        request.timeoutInterval = 600
        return request
    }

    public func makeAccumulator() -> any TurnAccumulator {
        AnthropicStreamAccumulator()
    }

    /// All results of one turn go back together in a single user message.
    public func toolResultMessages(_ results: [ToolResultPayload]) -> [JSONValue] {
        guard !results.isEmpty else { return [] }
        return [[
            "role": "user",
            "content": .array(results.map { result in
                var block: [String: JSONValue] = [
                    "type": "tool_result",
                    "tool_use_id": .string(result.callID),
                    "content": .string(result.content),
                ]
                if result.isError { block["is_error"] = true }
                return .object(block)
            }),
        ]]
    }
}

/// Rebuilds the assistant message from Claude's stream. Every content block
/// (text, thinking with its signature, tool_use, fallback, ...) is kept so it
/// can be sent back unchanged on the next request.
struct AnthropicStreamAccumulator: TurnAccumulator {
    private var blocks: [Int: [String: JSONValue]] = [:]
    private var partialJSON: [Int: String] = [:]
    private var invalidInputs: [Int: String] = [:]
    private var stopReason: String?
    private var refusalCategory: String?

    mutating func consume(_ event: SSEEvent) throws -> String? {
        guard let payload = try? JSONValue.parse(event.data), let type = payload["type"]?.stringValue else { return nil }

        switch type {
        case "content_block_start":
            guard let index = payload["index"]?.numberValue.map(Int.init),
                  let block = payload["content_block"]?.objectValue else { return nil }
            blocks[index] = block
            return nil

        case "content_block_delta":
            guard let index = payload["index"]?.numberValue.map(Int.init),
                  let delta = payload["delta"], var block = blocks[index] else { return nil }
            var visible: String?
            switch delta["type"]?.stringValue {
            case "text_delta":
                let text = delta["text"]?.stringValue ?? ""
                block["text"] = .string((block["text"]?.stringValue ?? "") + text)
                visible = text
            case "thinking_delta":
                block["thinking"] = .string((block["thinking"]?.stringValue ?? "") + (delta["thinking"]?.stringValue ?? ""))
            case "signature_delta":
                block["signature"] = delta["signature"] ?? .string("")
            case "input_json_delta":
                partialJSON[index, default: ""] += delta["partial_json"]?.stringValue ?? ""
            default:
                break
            }
            blocks[index] = block
            return visible

        case "content_block_stop":
            guard let index = payload["index"]?.numberValue.map(Int.init),
                  blocks[index]?["type"]?.stringValue == "tool_use" else { return nil }
            let raw = partialJSON[index] ?? ""
            // Eager input streaming hands over unvalidated JSON: parse strictly.
            if raw.isEmpty {
                blocks[index]?["input"] = .object([:])
            } else if let input = try? JSONValue.parse(raw), input.objectValue != nil {
                blocks[index]?["input"] = input
            } else {
                blocks[index]?["input"] = .object([:])
                invalidInputs[index] = raw
            }
            return nil

        case "message_delta":
            if let reason = payload["delta"]?["stop_reason"]?.stringValue {
                stopReason = reason
            }
            refusalCategory = payload["delta"]?["stop_details"]?["category"]?.stringValue ?? refusalCategory
            return nil

        case "error":
            throw AIError.stream(
                type: payload["error"]?["type"]?.stringValue ?? "error",
                message: payload["error"]?["message"]?.stringValue ?? event.data
            )

        default: // message_start, message_stop, ping
            return nil
        }
    }

    func finish() throws -> BackendTurn {
        let ordered = blocks.keys.sorted().compactMap { blocks[$0] }
        let toolCalls = blocks.keys.sorted().compactMap { index -> ToolCall? in
            guard let block = blocks[index], block["type"]?.stringValue == "tool_use",
                  let id = block["id"]?.stringValue, let name = block["name"]?.stringValue else { return nil }
            let invalid = invalidInputs[index]
            return ToolCall(
                id: id,
                name: name,
                input: invalid == nil ? block["input"] : nil,
                rawInput: invalid ?? partialJSON[index] ?? ""
            )
        }
        let text = ordered.filter { $0["type"]?.stringValue == "text" }
            .compactMap { $0["text"]?.stringValue }
            .joined()

        let reason: StopReason = switch stopReason {
        case "end_turn", "stop_sequence", nil: .endTurn
        case "tool_use": .toolUse
        case "max_tokens": .maxTokens
        case "refusal": .refusal(category: refusalCategory)
        case let other?: .other(other)
        }

        return BackendTurn(
            assistantMessage: ["role": "assistant", "content": .array(ordered.map(JSONValue.object))],
            text: text,
            toolCalls: toolCalls,
            stopReason: reason
        )
    }
}
