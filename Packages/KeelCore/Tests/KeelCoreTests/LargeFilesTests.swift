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

        let report = LargeFileRemover(home: sandbox.home, policy: LargeFileRemover.policy(home: sandbox.home), remover: remover, log: nil).perform([
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

    @Test func findsAppDataButNotApplesOrTheRestOfLibrary() throws {
        let sandbox = try Sandbox()
        try sandbox.write("Library/Containers/com.docker.docker/Data/vms/0/Docker.raw", bytes: 99_000)
        try sandbox.write("Library/Application Support/Steam/steamapps/game.vpk", bytes: 80_000)
        try sandbox.write("Library/Developer/Xcode/DerivedData/App/Build/big.o", bytes: 70_000)
        try sandbox.write("Library/Containers/com.apple.mail/Data/big", bytes: 99_000)
        try sandbox.write("Library/Group Containers/group.com.apple.notes/big", bytes: 99_000)
        try sandbox.write("Library/Application Support/MobileSync/Backup/1/ab/chunk", bytes: 99_000)
        try sandbox.write("Library/Preferences/big.plist", bytes: 99_000)
        try sandbox.write("Library/Caches/loose.bin", bytes: 99_000)
        try sandbox.write("Downloads/movie.mov", bytes: 60_000)

        let personal = scanner(sandbox).scan()
        #expect(personal.map(\.url.lastPathComponent) == ["movie.mov"])

        let files = LargeFileScanner(home: sandbox.home, minimumBytes: 40_000, includeAppData: true, lastActivity: { _ in nil }).scan()
        #expect(files.map(\.url.lastPathComponent) == ["Docker.raw", "game.vpk", "big.o", "movie.mov"])
        #expect(files.map(\.appData) == [
            AppDataLocation(area: "Containers", owner: "com.docker.docker"),
            AppDataLocation(area: "Application Support", owner: "Steam"),
            AppDataLocation(area: "Developer", owner: "Xcode"),
            nil,
        ])
    }

    @Test func removesAppDataOnlyWhileItsAppIsClosed() throws {
        let sandbox = try Sandbox()
        let docker = try sandbox.write("Library/Containers/com.docker.docker/Data/Docker.raw", bytes: 5_000)
        let steam = try sandbox.write("Library/Application Support/Steam/game.vpk", bytes: 5_000)
        let prefs = try sandbox.write("Library/Preferences/com.example.plist", bytes: 5_000)
        let remover = try RecordingRemover(bin: sandbox.home.appendingPathComponent(".Trash"))
        let files = [docker, steam, prefs].map { url in
            LargeFile(url: url, sizeBytes: 5_000, lastActivity: nil, kind: .other, appData: LargeFileScanner.appDataLocation(of: url, home: sandbox.home))
        }

        let report = LargeFileRemover(home: sandbox.home, policy: LargeFileRemover.policy(home: sandbox.home), remover: remover, log: nil)
            .perform(files, runningBundleIDs: ["com.docker.docker"], runningNames: ["finder"])

        #expect(report.removed.map(\.url) == [steam])
        #expect(report.skipped.map(\.url) == [docker, prefs])
        #expect(FileManager.default.fileExists(atPath: docker.path))
        #expect(FileManager.default.fileExists(atPath: prefs.path))
    }

    @Test func ownersMatchRunningApps() {
        let teams = AppDataLocation(area: "Group Containers", owner: "UBF8T346G9.com.microsoft.teams")
        #expect(teams.belongs(toAnyOf: ["com.microsoft.teams"], names: []))
        #expect(AppDataLocation(area: "Application Support", owner: "Steam").belongs(toAnyOf: [], names: ["steam"]))
        #expect(AppDataLocation(area: "Group Containers", owner: "group.com.docker").belongs(toAnyOf: ["com.docker"], names: []))
        #expect(!AppDataLocation(area: "Containers", owner: "com.docker.docker").belongs(toAnyOf: ["com.docker.cli"], names: ["docker desktop"]))
    }
}
