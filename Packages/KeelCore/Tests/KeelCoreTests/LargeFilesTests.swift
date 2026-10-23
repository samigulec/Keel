import Foundation
import Testing
@testable import KeelCore

@Suite("Large files")
struct LargeFilesTests {
    func scanner(_ sandbox: Sandbox) -> LargeFileScanner {
        // Above the 4 KB block a tiny file takes on APFS.
        LargeFileScanner(home: sandbox.home, minimumBytes: 40_000, lastActivity: FileActivity.modificationDate(of:))
    }

    @Test func findsBigFilesOutsideLibraryAndPackages() throws {
        let sandbox = try Sandbox()
        try sandbox.write("Downloads/movie.mov", bytes: 90_000)
        try sandbox.write("Documents/Projects/backup.zip", bytes: 60_000)
        try sandbox.write("Documents/small.txt", bytes: 10)
        try sandbox.write("Library/Caches/big.bin", bytes: 99_000)
        try sandbox.write("Applications/Tool.app/Contents/big", bytes: 99_000)
        try sandbox.write(".hidden/big", bytes: 99_000)
        try sandbox.write("Documents/Thing.app/Contents/big", bytes: 99_000)

        let files = scanner(sandbox).scan()

        #expect(files.map(\.url.lastPathComponent) == ["movie.mov", "backup.zip"])
        #expect(files.map(\.kind) == [.video, .archive])
        #expect(files.allSatisfy { $0.lastActivity != nil })
    }

    @Test func movesChosenFilesToTheTrashAndRefusesTheRest() throws {
        let sandbox = try Sandbox()
        let movie = try sandbox.write("Downloads/movie.mov", bytes: 5_000)
        let cache = try sandbox.write("Library/Caches/big.bin", bytes: 5_000)
        let folder = sandbox.home.appendingPathComponent("Documents/Folder")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let remover = try RecordingRemover(bin: sandbox.home.appendingPathComponent(".Trash"))

        let report = LargeFileRemover(policy: LargeFileRemover.policy(home: sandbox.home), remover: remover, log: nil).perform([
            LargeFile(url: movie, sizeBytes: 5_000, lastActivity: nil, kind: .video),
            LargeFile(url: cache, sizeBytes: 5_000, lastActivity: nil, kind: .other),
            LargeFile(url: folder, sizeBytes: 1, lastActivity: nil, kind: .other),
        ])

        #expect(report.removed.map(\.url) == [movie])
        #expect(report.freedBytes == 5_000)
        #expect(report.trashed.count == 1)
        #expect(report.skipped.count == 2)
        #expect(FileManager.default.fileExists(atPath: cache.path))

        let restored = TrashRestorer(log: nil).restore(report.trashed)
        #expect(restored.restored.count == 1)
        #expect(FileManager.default.fileExists(atPath: movie.path))
    }
}
