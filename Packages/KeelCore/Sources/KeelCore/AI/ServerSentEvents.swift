import Foundation

public struct SSEEvent: Equatable, Sendable {
    public let event: String?
    public let data: String
}

/// Turns server-sent event lines into events. Each `data:` line is taken as
/// a whole event: both Claude and OpenAI-style APIs send one-line JSON, and
/// line readers such as URLSession's drop the blank separator lines.
public struct SSEParser: Sendable {
    private var pendingEvent: String?

    public init() {}

    public mutating func feed(_ line: String) -> SSEEvent? {
        if line.hasPrefix("event:") {
            pendingEvent = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
            return nil
        }
        guard line.hasPrefix("data:") else { return nil } // comments, ids, retry hints
        let data = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
        defer { pendingEvent = nil }
        return SSEEvent(event: pendingEvent, data: data)
    }
}
