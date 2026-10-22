import Foundation
@testable import KeelCore

extension Sandbox {
    @discardableResult
    func write(_ relativePath: String, bytes: Int, in root: URL? = nil, daysOld: Double = 0) throws -> URL {
        let url = (root ?? home).appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(repeating: 0x2A, count: bytes).write(to: url)
        if daysOld > 0 { try age(url, days: daysOld) }
        return url
    }

    func age(_ url: URL, days: Double) throws {
        try FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(-days * 86_400)],
            ofItemAtPath: url.path
        )
    }

    var scanner: CleanupScanner { .standard(home: home) }

    /// Uses modification dates only, so tests do not depend on Spotlight.
    func context(running: Set<String> = []) -> ScanContext {
        ScanContext(runningBundleIDs: running, lastActivity: FileActivity.modificationDate(of:))
    }
}

extension [CategoryScanResult] {
    subscript(_ id: CleanupCategoryID) -> CategoryScanResult {
        first { $0.category.id == id }!
    }
}

extension CategoryScanResult {
    var names: Set<String> { Set(items.map(\.url.lastPathComponent)) }
}

/// Moves "removed" items into a folder of the sandbox and records the calls.
final class RecordingRemover: FileRemover, @unchecked Sendable {
    let bin: URL
    private(set) var trashed: [URL] = []
    private(set) var deleted: [URL] = []
    var failingNames: Set<String> = []

    init(bin: URL) throws {
        self.bin = bin
        try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
    }

    func moveToTrash(_ url: URL) throws {
        if failingNames.contains(url.lastPathComponent) { throw CocoaError(.fileWriteNoPermission) }
        try FileManager.default.moveItem(at: url, to: bin.appendingPathComponent(UUID().uuidString))
        trashed.append(url)
    }

    func deletePermanently(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
        deleted.append(url)
    }
}
