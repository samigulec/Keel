import Foundation

/// The only code in Keel that removes files. Kept behind a protocol so tests
/// can observe removals without touching the real Trash.
public protocol FileRemover: Sendable {
    func moveToTrash(_ url: URL) throws
    func deletePermanently(_ url: URL) throws
}

public struct SystemFileRemover: FileRemover {
    public struct TrashUnavailable: Error {}

    public init() {}

    public func moveToTrash(_ url: URL) throws {
        #if os(macOS)
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        #else
        throw TrashUnavailable()
        #endif
    }

    public func deletePermanently(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}
