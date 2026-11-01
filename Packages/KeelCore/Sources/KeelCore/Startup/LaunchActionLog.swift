import Foundation

extension LaunchItem.Scope: Codable {}

/// Append-only record of every background service Keel switches, one JSON
/// object per line in ~/Library/Logs/Keel/startup.log. Removals have their
/// own log, `ActionLog`. Entries hold the job's label and never its plist
/// path, plist contents or command.
public struct LaunchActionLog: Sendable {
    public struct Entry: Codable, Equatable, Sendable {
        public enum Action: String, Codable, Sendable {
            case enable
            case disable
        }

        public enum Outcome: String, Codable, Sendable {
            case ok
            case failed
            /// Keel would not touch the job; see `LaunchControl.refusal`.
            case refused
            /// The administrator prompt was dismissed.
            case cancelled
        }

        public static let maximumDetailLength = 200

        public let date: Date
        public let label: String
        public let scope: LaunchItem.Scope
        public let action: Action
        public let outcome: Outcome
        public let detail: String?

        public init(date: Date, label: String, scope: LaunchItem.Scope, action: Action, outcome: Outcome, detail: String? = nil) {
            self.date = date
            self.label = label
            self.scope = scope
            self.action = action
            self.outcome = outcome
            self.detail = detail.map { String($0.prefix(Self.maximumDetailLength)) }
        }

        public init(item: LaunchItem, enabled: Bool, outcome: Outcome, detail: String? = nil, date: Date = Date()) {
            self.init(date: date, label: item.label, scope: item.scope, action: enabled ? .enable : .disable, outcome: outcome, detail: detail)
        }

        /// The entry for a job Keel refuses to switch, or nil when it may.
        public static func refused(item: LaunchItem, enabled: Bool, date: Date = Date()) -> Entry? {
            LaunchControl.refusal(for: item).map { Entry(item: item, enabled: enabled, outcome: .refused, detail: $0, date: date) }
        }
    }

    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func standard(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> LaunchActionLog {
        LaunchActionLog(fileURL: home.appendingPathComponent("Library/Logs/Keel/startup.log"))
    }

    public func append(_ entry: Entry) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var line = try encoder.encode(entry)
        line.append(UInt8(ascii: "\n"))

        let fileManager = FileManager.default
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if !fileManager.fileExists(atPath: fileURL.path) {
            guard fileManager.createFile(atPath: fileURL.path, contents: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
        }
        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: line)
    }

    public func entries() throws -> [Entry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try String(contentsOf: fileURL, encoding: .utf8)
            .split(separator: "\n")
            .map { try decoder.decode(Entry.self, from: Data($0.utf8)) }
    }
}
