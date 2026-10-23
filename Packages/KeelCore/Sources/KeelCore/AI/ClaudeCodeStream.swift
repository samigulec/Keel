import Foundation

/// Reads `claude -p --output-format stream-json --verbose --include-partial-messages`.
public struct ClaudeCodeStreamParser: Sendable {
    public enum Event: Equatable, Sendable {
        /// The session started; the model is the full id Claude Code resolved.
        case started(model: String)
        case text(String)
        /// Claude Code is retrying a failed API call, e.g. after `overloaded`.
        case retry(attempt: Int, error: String)
        case result(sessionID: String?, isError: Bool, message: String)
        case usage(TurnUsage)
    }

    private var sawText = false

    public init() {}

    public mutating func consume(_ line: String) -> [Event] {
        guard let json = try? JSONValue.parse(line), let type = json["type"]?.stringValue else { return [] }
        switch type {
        case "stream_event":
            let event = json["event"]
            guard event?["type"]?.stringValue == "content_block_delta",
                  event?["delta"]?["type"]?.stringValue == "text_delta",
                  let text = event?["delta"]?["text"]?.stringValue, !text.isEmpty else { return [] }
            sawText = true
            return [.text(text)]

        case "system" where json["subtype"]?.stringValue == "init":
            return json["model"]?.stringValue.map { [.started(model: $0)] } ?? []

        case "system" where json["subtype"]?.stringValue == "api_retry":
            return [.retry(
                attempt: json["attempt"]?.numberValue.map(Int.init) ?? 0,
                error: json["error"]?.stringValue ?? "unknown"
            )]

        case "result":
            let isError = json["is_error"]?.bool ?? (json["subtype"]?.stringValue != "success")
            let message = json["result"]?.stringValue ?? json["subtype"]?.stringValue ?? ""
            var events: [Event] = []
            // Without partial messages there were no deltas; show the final text instead.
            if !sawText, !isError, !message.isEmpty {
                events.append(.text(message))
            }
            events.append(.result(sessionID: json["session_id"]?.stringValue, isError: isError, message: message))
            if let usage = Self.usage(from: json) { events.append(.usage(usage)) }
            return events

        default:
            return []
        }
    }

    /// Cost is Claude Code's own estimate; context is what this answer's
    /// request held, out of the model's window.
    static func usage(from result: JSONValue) -> TurnUsage? {
        let usage = result["usage"]
        func count(_ key: String) -> Int { usage?[key]?.numberValue.map(Int.init) ?? 0 }
        let context = count("input_tokens") + count("cache_read_input_tokens")
            + count("cache_creation_input_tokens") + count("output_tokens")
        // The main model is the one with the most input; helpers may also appear.
        let models = result["modelUsage"]?.objectValue ?? [:]
        let main = models.max { ($0.value["inputTokens"]?.numberValue ?? 0) < ($1.value["inputTokens"]?.numberValue ?? 0) }
        let cost = result["total_cost_usd"]?.numberValue
        guard cost != nil || context > 0 else { return nil }
        return TurnUsage(
            model: main?.key,
            costUSD: cost,
            contextTokens: context > 0 ? context : nil,
            contextWindow: main?.value["contextWindow"]?.numberValue.map(Int.init)
        )
    }
}

extension JSONValue {
    var bool: Bool? {
        if case .bool(let value) = self { value } else { nil }
    }
}

/// Keel AI asks text-only providers to end an answer with fenced blocks
/// when it suggests something: `keel-cleanup` for a cleanup, `keel-action`
/// for anything else (startup items, quitting apps, fans). This hides the
/// blocks from the streamed text and returns their JSON once the answer is
/// complete.
public struct ProposalStreamFilter: Sendable {
    static let marker = "```keel-"

    private var pending = ""
    private var captured: String?

    public init() {}

    /// Returns the part of the chunk that is safe to show now.
    public mutating func feed(_ chunk: String) -> String {
        if captured != nil {
            captured! += chunk
            return ""
        }
        pending += chunk
        if let range = pending.range(of: Self.marker) {
            let visible = String(pending[..<range.lowerBound])
            captured = String(pending[range.upperBound...])
            pending = ""
            return visible
        }
        // Hold back a tail that could still grow into the marker.
        let keep = Self.longestMarkerPrefixSuffix(of: pending)
        let visible = String(pending.dropLast(keep))
        pending = String(pending.suffix(keep))
        return visible
    }

    /// The text still held back, the cleanups and the other actions found.
    public mutating func finish() -> (visible: String, proposals: [JSONValue], actions: [JSONValue]) {
        defer {
            pending = ""
            captured = nil
        }
        guard let captured else { return (pending, [], []) }

        var proposals: [JSONValue] = []
        var actions: [JSONValue] = []
        var trailing = ""
        var rest = Substring(captured)
        while true {
            // "cleanup\n{...}\n```" or "action\n{...}\n```"
            let kind = rest.prefix { $0.isLetter || $0 == "-" }
            rest = rest.dropFirst(kind.count)
            let body: Substring
            if let end = rest.range(of: "```") {
                body = rest[..<end.lowerBound]
                rest = rest[end.upperBound...]
            } else {
                body = rest
                rest = ""
            }
            let objects = Self.objects(in: body)
            switch kind {
            case "cleanup": proposals += objects
            case "action": actions += objects
            default: break
            }
            guard let next = rest.range(of: Self.marker) else {
                trailing += rest
                break
            }
            trailing += rest[..<next.lowerBound]
            rest = rest[next.upperBound...]
        }
        return (trailing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : trailing, proposals, actions)
    }

    private static func objects(in body: Substring) -> [JSONValue] {
        switch try? JSONValue.parse(String(body).trimmingCharacters(in: .whitespacesAndNewlines)) {
        case .object(let object)?: [.object(object)]
        case .array(let array)?: array.filter { $0.objectValue != nil }
        default: []
        }
    }

    private static func longestMarkerPrefixSuffix(of text: String) -> Int {
        let limit = min(text.count, marker.count - 1)
        guard limit > 0 else { return 0 }
        for length in stride(from: limit, through: 1, by: -1) where marker.hasPrefix(String(text.suffix(length))) {
            return length
        }
        return 0
    }
}
