import Foundation

/// An item Keel moved to the Trash: where it was and where it is now.
public struct TrashedItem: Codable, Hashable, Sendable {
    public let original: URL
    public let inTrash: URL
    public let bytes: Int64

    public init(original: URL, inTrash: URL, bytes: Int64) {
        self.original = original
        self.inTrash = inTrash
        self.bytes = bytes
    }
}

public struct RestoreReport: Sendable {
    public struct Failure: Sendable {
        public let item: TrashedItem
        public let message: String
    }

    public var restored: [TrashedItem] = []
    public var failed: [Failure] = []

    public init() {}

    public var restoredBytes: Int64 { restored.reduce(0) { $0 + $1.bytes } }
}

/// Keel's undo: puts trashed items back where they were. It only moves
/// items that are still in a Trash folder, and never over something that
/// has taken their place since.
public struct TrashRestorer: Sendable {
    public let log: ActionLog?

    public init(log: ActionLog?) {
        self.log = log
    }

    public func restore(_ items: [TrashedItem], now: @Sendable () -> Date = Date.init) -> RestoreReport {
        var report = RestoreReport()
        let files = FileManager.default

        for item in items {
            func fail(_ message: String) {
                report.failed.append(.init(item: item, message: message))
                try? log?.append(ActionLog.Entry(
                    date: now(), removal: .moveToTrash, path: item.original.path,
                    bytes: item.bytes, outcome: .failed, detail: "undo: \(message)"
                ))
            }

            guard Self.isInTrash(item.inTrash) else {
                fail("Çöp Kutusu'nda değil")
                continue
            }
            guard files.fileExists(atPath: item.inTrash.path) || Self.isLink(item.inTrash) else {
                fail("Çöp Kutusu'nda artık yok")
                continue
            }
            guard !files.fileExists(atPath: item.original.path), !Self.isLink(item.original) else {
                fail("eski yerinde aynı adla bir öğe var")
                continue
            }
            do {
                try files.createDirectory(at: item.original.deletingLastPathComponent(), withIntermediateDirectories: true)
                try files.moveItem(at: item.inTrash, to: item.original)
                report.restored.append(item)
                try? log?.append(ActionLog.Entry(
                    date: now(), removal: .moveToTrash, path: item.original.path,
                    bytes: item.bytes, outcome: .restored
                ))
            } catch {
                fail(error.localizedDescription)
            }
        }
        return report
    }

    /// A user's ~/.Trash or a volume's /.Trashes/<uid>.
    static func isInTrash(_ url: URL) -> Bool {
        url.standardizedFileURL.pathComponents.dropLast().contains { $0 == ".Trash" || $0 == ".Trashes" }
    }

    private static func isLink(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true
    }
}
