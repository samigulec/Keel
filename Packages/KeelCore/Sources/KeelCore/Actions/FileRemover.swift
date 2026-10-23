import Foundation

/// The only code in Keel that removes files. Kept behind a protocol so tests
/// can observe removals without touching the real Trash.
public protocol FileRemover: Sendable {
    /// Moves the item to the Trash and returns where it landed, if known,
    /// so it can be put back.
    @discardableResult
    func moveToTrash(_ url: URL) throws -> URL?
    func deletePermanently(_ url: URL) throws
}

public struct SystemFileRemover: FileRemover {
    public struct TrashUnavailable: Error {}

    public init() {}

    @discardableResult
    public func moveToTrash(_ url: URL) throws -> URL? {
        #if os(macOS)
        var landed: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &landed)
        return landed as URL?
        #else
        throw TrashUnavailable()
        #endif
    }

    public func deletePermanently(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}
