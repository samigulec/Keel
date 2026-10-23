import Foundation

/// Append-only record of every removal Keel performs, one JSON object per
/// line in ~/Library/Logs/Keel/actions.log.
public struct ActionLog: Sendable {
    public struct Entry: Codable, Equatable, Sendable {
        public enum Outcome: String, Codable, Sendable {
            case removed
            case skipped
            case failed
            /// Put back from the Trash with Keel's undo.
            case restored
        }

        public let date: Date
        public let removal: Removal
        public let path: String
        public let bytes: Int64
        public let outcome: Outcome
        public let detail: String?

        public init(date: Date, removal: Removal, path: String, bytes: Int64, outcome: Outcome, detail: String? = nil) {
            self.date = date
            self.removal = removal
            self.path = path
            self.bytes = bytes
            self.outcome = outcome
            self.detail = detail
        }
    }

    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func standard(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> ActionLog {
        ActionLog(fileURL: home.appendingPathComponent("Library/Logs/Keel/actions.log"))
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
