import Foundation

/// Reads `codex exec --json`, one JSON event per line.
public struct CodexStreamParser: Sendable {
    public enum Event: Equatable, Sendable {
        /// The thread to resume for the next message.
        case started(threadID: String)
        /// A finished answer; Codex sends agent messages whole, not as deltas.
        case text(String)
        case usage(TurnUsage)
        /// The turn failed; the message is Codex's own.
        case failed(String)
    }

    /// The last error Codex reported, kept for when the process then exits
    /// without a `turn.failed` event.
    public private(set) var lastError: String?

    public init() {}

    public mutating func consume(_ line: String) -> [Event] {
        guard let json = try? JSONValue.parse(line), let type = json["type"]?.stringValue else { return [] }
        switch type {
        case "thread.started":
            return json["thread_id"]?.stringValue.map { [.started(threadID: $0)] } ?? []

        case "item.completed":
            let item = json["item"]
            switch item?["type"]?.stringValue {
            case "agent_message":
                guard let text = item?["text"]?.stringValue, !text.isEmpty else { return [] }
                return [.text(text)]
            case "error":
                lastError = item?["message"]?.stringValue ?? lastError
                return []
            default:
                return []
            }

        case "turn.completed":
            let usage = json["usage"]
            func count(_ key: String) -> Int { usage?[key]?.numberValue.map(Int.init) ?? 0 }
            let context = count("input_tokens") + count("output_tokens")
            return context > 0 ? [.usage(TurnUsage(contextTokens: context))] : []

        case "turn.failed":
            let message = json["error"]?["message"]?.stringValue ?? lastError ?? "turn failed"
            lastError = message
            return [.failed(message)]

        case "error":
            lastError = json["message"]?.stringValue ?? lastError
            return []

        default:
            return []
        }
    }
}

/// Errors from a provider's command line tool that Keel can act on.
public enum CLIErrorText {
    /// Whether the message says the chosen model is not available to this
    /// account, so retrying with the account's default model may work.
    public static func isModelUnavailable(_ message: String) -> Bool {
        let text = message.lowercased()
        guard text.contains("model") else { return false }
        let signals = [
            "not_found", "not found", "does not exist", "may not exist", "not exist",
            "not supported", "unsupported", "not available", "unavailable",
            "not have access", "no access", "invalid model", "unknown model",
        ]
        return signals.contains { text.contains($0) }
    }

    /// Whether the message says the user has to sign in (again).
    public static func needsLogin(_ message: String) -> Bool {
        let text = message.lowercased()
        let signals = ["not logged in", "log in", "login", "sign in", "unauthorized", "authentication", "401"]
        return signals.contains { text.contains($0) }
    }

    public static func isUsageLimit(_ message: String) -> Bool {
        let text = message.lowercased()
        return text.contains("usage limit") || text.contains("rate limit") || text.contains("limit reached")
            || text.contains("hit your limit") || text.contains("429")
    }
}
