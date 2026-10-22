import Foundation
import Testing
@testable import KeelCore

@Suite("CleanupExecutor")
struct CleanupExecutorTests {
    func executor(_ sandbox: Sandbox, remover: RecordingRemover) -> CleanupExecutor {
        CleanupExecutor(
            policy: sandbox.policy,
            trashDirectory: sandbox.home.appendingPathComponent(".Trash"),
            remover: remover,
            log: ActionLog(fileURL: sandbox.home.appendingPathComponent("Library/Logs/Keel/actions.log"))
        )
    }

    func item(_ url: URL, _ removal: Removal = .moveToTrash, bytes: Int64 = 1_000) -> CleanupItem {
        CleanupItem(url: url, category: .userCaches, removal: removal, sizeBytes: bytes)
    }

    @Test func movesScannedItemsToTrashAndLogsThem() async throws {
        let sandbox = try Sandbox()
        try sandbox.write("Library/Caches/com.spotify.client/data", bytes: 30_000)
        let remover = try RecordingRemover(bin: sandbox.outside.appendingPathComponent("bin"))
        let caches = try await sandbox.scanner.scan(context: sandbox.context())[.userCaches]

        let report = executor(sandbox, remover: remover).perform(caches.items)

        #expect(report.removed.count == 1)
        #expect(report.freedBytes == caches.totalBytes)
        #expect(remover.trashed.map(\.lastPathComponent) == ["com.spotify.client"])
        #expect(remover.deleted.isEmpty)
        let entries = try ActionLog(fileURL: sandbox.home.appendingPathComponent("Library/Logs/Keel/actions.log")).entries()
        #expect(entries.map(\.outcome) == [.removed])
        #expect(entries.first?.path.hasSuffix("Library/Caches/com.spotify.client") == true)
    }

    @Test func rechecksPolicyWhenDiskChangedAfterScan() async throws {
        let sandbox = try Sandbox()
        let data = try sandbox.write("Library/Caches/com.spotify.client/data", bytes: 30_000)
        let scanned = item(data)

        // After the scan, the app folder is swapped for a link to precious data.
        try sandbox.write("data", bytes: 30_000, in: sandbox.outside)
        try FileManager.default.removeItem(at: data.deletingLastPathComponent())
        _ = try sandbox.symlink("Library/Caches/com.spotify.client", to: sandbox.outside)

        let remover = try RecordingRemover(bin: sandbox.home.appendingPathComponent("bin"))
        let report = executor(sandbox, remover: remover).perform([scanned])

        #expect(report.removed.isEmpty)
        #expect(report.skipped.map(\.reason) == [.denied(.outsideAllowedRoots)])
        #expect(FileManager.default.fileExists(atPath: sandbox.outside.appendingPathComponent("data").path))
    }

    @Test func refusesPermanentDeletionOutsideTrash() throws {
        let sandbox = try Sandbox()
        let cache = try sandbox.write("Library/Caches/com.spotify.client/data", bytes: 3_000)
        let remover = try RecordingRemover(bin: sandbox.outside.appendingPathComponent("bin"))

        let report = executor(sandbox, remover: remover).perform([item(cache, .deletePermanently)])

        #expect(report.skipped.map(\.reason) == [.permanentDeletionNotAllowed])
        #expect(remover.deleted.isEmpty)
        #expect(FileManager.default.fileExists(atPath: cache.path))
    }

    @Test func emptiesTrashPermanently() throws {
        let sandbox = try Sandbox()
        let old = try sandbox.write(".Trash/old.zip", bytes: 3_000)
        let remover = try RecordingRemover(bin: sandbox.outside.appendingPathComponent("bin"))

        let report = executor(sandbox, remover: remover).perform([item(old, .deletePermanently)])

        #expect(report.removed.count == 1)
        #expect(remover.deleted == [old])
        #expect(!FileManager.default.fileExists(atPath: old.path))
    }

    @Test func oneFailureDoesNotStopTheRest() throws {
        let sandbox = try Sandbox()
        let locked = try sandbox.write("Library/Caches/com.locked.app", bytes: 1_000)
        let fine = try sandbox.write("Library/Caches/com.fine.app", bytes: 1_000)
        let remover = try RecordingRemover(bin: sandbox.outside.appendingPathComponent("bin"))
        remover.failingNames = ["com.locked.app"]

        let report = executor(sandbox, remover: remover).perform([item(locked), item(fine)])

        #expect(report.failed.map(\.item.url) == [locked])
        #expect(report.removed.map(\.url) == [fine])
    }

    @Test func neverTouchesDocuments() throws {
        let sandbox = try Sandbox()
        let thesis = try sandbox.write("Documents/thesis.pages", bytes: 1_000)
        let remover = try RecordingRemover(bin: sandbox.outside.appendingPathComponent("bin"))

        let report = executor(sandbox, remover: remover).perform([item(thesis)])

        #expect(report.removed.isEmpty)
        #expect(FileManager.default.fileExists(atPath: thesis.path))
    }
}
