import Foundation

/// Builds a bounded transcript of an earlier conversation for a model that did
/// not see it, keeping the newest messages and middle-truncating a single
/// newest message that exceeds the character budget rather than returning empty.
public enum ChatTranscript: Sendable {
    public struct Message: Codable, Equatable, Sendable {
        public enum Role: String, Codable, Equatable, Sendable {
            case user
            case assistant
            case notice
        }

        public let role: Role
        public let text: String

        public init(role: Role, text: String) {
            self.role = role
            self.text = text
        }
    }

    public static let defaultMaxCharacters = 6_000
    private static let separator = "\n\n"
    private static let truncationMarker = "\n…\n"

    /// Formats the newest non-notice messages within `maxCharacters`, including
    /// speaker prefixes, `"\n\n"` separators, and any `"\n…\n"` marker inside
    /// the budget.
    public static func build(_ messages: [Message], maxCharacters: Int = defaultMaxCharacters) -> String {
        guard maxCharacters > 0 else { return "" }

        var lines: [String] = []
        var length = 0

        for message in messages.reversed() where message.role != .notice {
            let prefix = message.role == .user ? "User: " : "Keel AI: "
            let line = prefix + message.text

            if lines.isEmpty {
                if line.count <= maxCharacters {
                    lines.append(line)
                    length = line.count
                } else {
                    return truncatedLine(prefix: prefix, text: message.text, maxCharacters: maxCharacters)
                }
            } else {
                let needed = separator.count + line.count
                if length + needed > maxCharacters { break }
                lines.insert(line, at: 0)
                length += needed
            }
        }

        return lines.joined(separator: separator)
    }

    /// Wraps a non-empty transcript in `<previous_conversation>` tags; returns
    /// `nil` when empty or whitespace-only so empty tags are never emitted.
    public static func wrap(_ transcript: String) -> String? {
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return "<previous_conversation>\n\(transcript)\n</previous_conversation>"
    }

    /// Prepends a wrapped transcript to `prompt`, or leaves `prompt` untouched
    /// when `transcript` is nil or blank.
    public static func applying(_ transcript: String?, to prompt: String) -> String {
        guard let transcript, let wrapped = wrap(transcript) else { return prompt }
        return "\(wrapped)\n\n\(prompt)"
    }

    private static func truncatedLine(prefix: String, text: String, maxCharacters: Int) -> String {
        let bodyBudget = maxCharacters - prefix.count - truncationMarker.count
        guard bodyBudget > 0 else { return "" }
        let headCount = (bodyBudget + 1) / 2
        let tailCount = bodyBudget - headCount
        let head = text.prefix(headCount)
        let tail = tailCount > 0 ? text.suffix(tailCount) : Substring()
        return prefix + head + truncationMarker + tail
    }
}
