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

    /// "claude-opus-4-6[1m]" -> "claude-opus-4-6": the standard variant of a
    /// long-context model, which plans often limit separately.
    public static func longContextBase(of model: String) -> String? {
        guard model.hasSuffix("]"), let open = model.lastIndex(of: "[") else { return nil }
        let base = String(model[..<open])
        return base.isEmpty ? nil : base
    }

    public static func isUsageLimit(_ message: String) -> Bool {
        let text = message.lowercased()
        return text.contains("usage limit") || text.contains("rate limit") || text.contains("limit reached")
            || text.contains("hit your limit") || text.contains("429")
    }
}

/// Version numbers that command line tools print, e.g. "2.1.308 (Claude Code)"
/// or "codex-cli 0.130.0", for picking the newest of several installs.
public enum CLIVersion {
    public static func parse(_ text: String) -> [Int]? {
        let scalars = Array(text.unicodeScalars)
        var index = 0
        while index < scalars.count {
            guard CharacterSet.decimalDigits.contains(scalars[index]) else {
                index += 1
                continue
            }
            var parts: [Int] = []
            var current = ""
            while index < scalars.count {
                let scalar = scalars[index]
                if CharacterSet.decimalDigits.contains(scalar) {
                    current.unicodeScalars.append(scalar)
                } else if scalar == ".", !current.isEmpty {
                    parts.append(Int(current) ?? 0)
                    current = ""
                } else {
                    break
                }
                index += 1
            }
            if !current.isEmpty { parts.append(Int(current) ?? 0) }
            // A bare number is not a version; keep looking.
            if parts.count >= 2 { return parts }
        }
        return nil
    }

    /// Whether `a` is newer than `b`; missing parts count as zero.
    public static func isNewer(_ a: [Int], than b: [Int]) -> Bool {
        for index in 0..<max(a.count, b.count) {
            let left = index < a.count ? a[index] : 0
            let right = index < b.count ? b[index] : 0
            if left != right { return left > right }
        }
        return false
    }
}
