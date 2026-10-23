import Foundation

/// A conversation as kept on disk: the words only. Tool runs and cleanup
/// cards belong to the moment and are not saved.
struct SavedChat: Codable, Identifiable, Equatable {
    struct Message: Codable, Equatable {
        enum Role: String, Codable {
            case user, assistant, notice
        }

        let role: Role
        let text: String
    }

    let id: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
    var messages: [Message]
}

/// Keel AI's conversations in ~/Library/Application Support/Keel/Chats, one
/// JSON file each. They stay on this Mac.
enum ChatStore {
    static let limit = 50

    static var folder: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Keel/Chats", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Newest first.
    static func list() -> [SavedChat] {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(SavedChat.self, from: Data(contentsOf: $0)) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    static func save(_ chat: SavedChat) {
        guard let data = try? encoder.encode(chat) else { return }
        try? data.write(to: url(for: chat.id), options: .atomic)
        // Keep the newest few dozen.
        for old in list().dropFirst(limit) { delete(old.id) }
    }

    static func delete(_ id: UUID) {
        try? FileManager.default.removeItem(at: url(for: id))
    }

    private static func url(for id: UUID) -> URL {
        folder.appendingPathComponent("\(id.uuidString).json")
    }

    /// "Pilimin durumu nasıl?" → title; long questions are cut at a word.
    static func title(for text: String) -> String {
        let line = text.split(separator: "\n").first.map(String.init) ?? text
        guard line.count > 48 else { return line }
        let cut = line.prefix(48)
        return (cut.lastIndex(of: " ").map { String(cut[..<$0]) } ?? String(cut)) + "…"
    }

    /// The earlier conversation, for a model that did not see it, newest
    /// messages kept when it is long.
    static func transcript(_ messages: [SavedChat.Message], maxCharacters: Int = 6_000) -> String {
        var lines: [String] = []
        var length = 0
        for message in messages.reversed() where message.role != .notice {
            let line = (message.role == .user ? "User: " : "Keel AI: ") + message.text
            if length + line.count > maxCharacters { break }
            lines.insert(line, at: 0)
            length += line.count
        }
        return lines.joined(separator: "\n\n")
    }
}
