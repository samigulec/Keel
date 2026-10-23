import Foundation
import Testing
@testable import KeelCore

@Suite("Undo")
struct UndoTests {
    @Test func putsCleanedItemsBack() async throws {
        let sandbox = try Sandbox()
        let data = try sandbox.write("Library/Caches/com.spotify.client/data", bytes: 30_000)
        let remover = try RecordingRemover(bin: sandbox.home.appendingPathComponent(".Trash"))
        let caches = try await sandbox.scanner.scan(context: sandbox.context())[.userCaches]
        let log = ActionLog(fileURL: sandbox.home.appendingPathComponent("Library/Logs/Keel/actions.log"))

        let report = CleanupExecutor(policy: sandbox.policy, trashDirectory: sandbox.home.appendingPathComponent(".Trash"), remover: remover, log: log)
            .perform(caches.items)
        #expect(report.trashed.count == 1)
        #expect(!FileManager.default.fileExists(atPath: data.path))

        let restored = TrashRestorer(log: log).restore(report.trashed)

        #expect(restored.restored.count == 1)
        #expect(restored.failed.isEmpty)
        #expect(FileManager.default.fileExists(atPath: data.path))
        #expect(try log.entries().last?.outcome == .restored)
    }

    @Test func neverOverwritesWhatTookTheItemsPlace() throws {
        let sandbox = try Sandbox()
        let original = try sandbox.write("Library/Caches/com.vendor.app/blob", bytes: 10)
        let remover = try RecordingRemover(bin: sandbox.home.appendingPathComponent(".Trash"))
        let landed = try #require(try remover.moveToTrash(original.deletingLastPathComponent()))
        // Something new appeared at the old place meanwhile.
        try sandbox.write("Library/Caches/com.vendor.app/new", bytes: 10)

        let report = TrashRestorer(log: nil).restore([TrashedItem(original: original.deletingLastPathComponent(), inTrash: landed, bytes: 10)])

        #expect(report.restored.isEmpty)
        #expect(report.failed.map(\.message) == ["eski yerinde aynı adla bir öğe var"])
        #expect(FileManager.default.fileExists(atPath: landed.path))
    }

    @Test func onlyMovesItemsThatAreInATrash() throws {
        let sandbox = try Sandbox()
        let document = try sandbox.file("Documents/notes.txt")
        let report = TrashRestorer(log: nil).restore([
            TrashedItem(original: sandbox.home.appendingPathComponent("Desktop/notes.txt"), inTrash: document, bytes: 1),
        ])
        #expect(report.failed.map(\.message) == ["Çöp Kutusu'nda değil"])
        #expect(FileManager.default.fileExists(atPath: document.path))
    }
}
