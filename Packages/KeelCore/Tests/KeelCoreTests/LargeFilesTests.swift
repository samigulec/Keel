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

    @Test func leavesAppProgramsAndDatabasesOut() throws {
        let sandbox = try Sandbox()
        let tool = try sandbox.write("Library/Application Support/Claude/claude-code/2.1/claude", bytes: 90_000)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tool.path)
        try sandbox.write("Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram/account/postbox/db/db_sqlite", bytes: 90_000)
        try sandbox.write("Library/Application Support/App/store.realm", bytes: 90_000)
        try sandbox.write("Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram/account/media/local-file-1", bytes: 80_000)

        let files = LargeFileScanner(home: sandbox.home, minimumBytes: 40_000, includeAppData: true, lastActivity: { _ in nil }).scan()
        #expect(files.map(\.url.lastPathComponent) == ["local-file-1"])
    }

    @Test func fileGoneSinceTheScanIsReportedNotFailed() throws {
        let sandbox = try Sandbox()
        let gone = sandbox.home.appendingPathComponent("Downloads/Brave-Browser-arm64.dmg")
        let remover = try RecordingRemover(bin: sandbox.home.appendingPathComponent(".Trash"))
        let report = LargeFileRemover(home: sandbox.home, policy: LargeFileRemover.policy(home: sandbox.home), remover: remover, log: nil)
            .perform([LargeFile(url: gone, sizeBytes: 232_000_000, lastActivity: nil, kind: .diskImage)])
        #expect(report.missing.map(\.url) == [gone])
        #expect(report.skipped.isEmpty && report.failed.isEmpty && report.removed.isEmpty)
    }

    @Test func ownersMatchRunningApps() {
        let teams = AppDataLocation(area: "Group Containers", owner: "UBF8T346G9.com.microsoft.teams")
        #expect(teams.belongs(toAnyOf: ["com.microsoft.teams"], names: []))
        #expect(AppDataLocation(area: "Application Support", owner: "Steam").belongs(toAnyOf: [], names: ["steam"]))
        #expect(AppDataLocation(area: "Group Containers", owner: "group.com.docker").belongs(toAnyOf: ["com.docker"], names: []))
        #expect(!AppDataLocation(area: "Containers", owner: "com.docker.docker").belongs(toAnyOf: ["com.docker.cli"], names: ["docker desktop"]))
    }

    @Test func removerRefusesHiddenPathsAndSymlinkToHiddenParent() throws {
        let sandbox = try Sandbox()
        let sshKey = try sandbox.write(".ssh/id_rsa", bytes: 50_000)
        let gpgKey = try sandbox.write(".gnupg/secring.gpg", bytes: 50_000)
        let nestedHidden = try sandbox.write("Documents/.secret/big.bin", bytes: 50_000)
        let dotFile = try sandbox.write("Documents/.hidden_file", bytes: 50_000)
        let secretTarget = try sandbox.write(".secret_dir/key.pem", bytes: 50_000)
        _ = try sandbox.symlink("Documents/alias", to: sandbox.home.appendingPathComponent(".secret_dir"))
        let viaSymlink = sandbox.home.appendingPathComponent("Documents/alias/key.pem")

        let scanned = scanner(sandbox).scan()
        #expect(scanned.isEmpty)

        let log = ActionLog(fileURL: sandbox.home.appendingPathComponent("Library/Logs/Keel/actions.log"))
        let remover = try RecordingRemover(bin: sandbox.home.appendingPathComponent(".Trash"))
        let inputs = [sshKey, gpgKey, nestedHidden, dotFile, viaSymlink].map {
            LargeFile(url: $0, sizeBytes: 50_000, lastActivity: nil, kind: .other)
        }
        let report = LargeFileRemover(home: sandbox.home, policy: LargeFileRemover.policy(home: sandbox.home), remover: remover, log: log)
            .perform(inputs)

        #expect(report.removed.isEmpty)
        #expect(report.skipped.count == 5)
        for url in [sshKey, gpgKey, nestedHidden, dotFile, secretTarget] {
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
        #expect(try log.entries().count == 5)
        #expect(try log.entries().allSatisfy { $0.outcome == .skipped })
    }

    @Test func scannerAndRemoverProtectPackagesWhileAllowingRegularFilesAndDottedFolders() throws {
        let sandbox = try Sandbox()
        let blocked = [
            try sandbox.write("Documents/Vacation.photoslibrary/originals/photo.raw", bytes: 60_000),
            try sandbox.write("Documents/Notes.rtfd/attachment.bin", bytes: 60_000),
            try sandbox.write("VMs/Win.vmwarevm/disk.vmdk", bytes: 60_000),
            try sandbox.write("VMs/Lin.pvm/disk.hdd", bytes: 60_000),
            try sandbox.write("Movies/Edit.fcpbundle/render.mov", bytes: 60_000),
            try sandbox.write("Projects/App.xcodeproj/project.pbxproj", bytes: 60_000),
            try sandbox.write("Documents/Novel.scriv/data.rtf", bytes: 60_000),
            try sandbox.write("Design/Mock.sketch/page.json", bytes: 60_000),
            try sandbox.write("Documents/Dummy.app/big.bin", bytes: 60_000),
        ]
        // Regular files with package-like extensions and ordinary dotted folders must NOT be rejected.
        let allowedRegular = try sandbox.write("Downloads/DesignFile.sketch", bytes: 60_000)
        let allowedDotted = try sandbox.write("Documents/Proje.v2/backup.zip", bytes: 60_000)

        let scanned = scanner(sandbox).scan()
        #expect(Set(scanned.map(\.url.lastPathComponent)) == ["DesignFile.sketch", "backup.zip"])

        let remover = try RecordingRemover(bin: sandbox.home.appendingPathComponent(".Trash"))
        let allInputs = (blocked + [allowedRegular, allowedDotted]).map {
            LargeFile(url: $0, sizeBytes: 60_000, lastActivity: nil, kind: .other)
        }
        let report = LargeFileRemover(home: sandbox.home, policy: LargeFileRemover.policy(home: sandbox.home), remover: remover, log: nil)
            .perform(allInputs)

        #expect(Set(report.removed.map(\.url)) == [allowedRegular, allowedDotted])
        #expect(report.skipped.count == blocked.count)
        for url in blocked {
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
    }

    @Test func appDataOwnerExemptionProtectsRealBundlesAndNestedPackages() throws {
        let sandbox = try Sandbox()
        // Ordinary owner folder named like a bundle ID (no Info.plist): allowed.
        let allowedOwnerData = try sandbox.write("Library/Caches/com.example.app/Contents/data.bin", bytes: 60_000)
        let allowedDocker = try sandbox.write("Library/Containers/com.docker.docker/Data/vms/0/Docker.raw", bytes: 60_000)
        // Genuine bundle sitting as an owner folder: rejected.
        try sandbox.write("Library/Application Support/Real.app/Contents/Info.plist", bytes: 100)
        let realAppInner = try sandbox.write("Library/Application Support/Real.app/Contents/big.bin", bytes: 60_000)
        // Nested packages inside legitimate appData owner folders: rejected.
        let nestedRtfd = try sandbox.write("Library/Application Support/MyApp/Sub.rtfd/big.bin", bytes: 60_000)
        let nestedVm = try sandbox.write("Library/Application Support/MyApp/VM.vmwarevm/disk.vmdk", bytes: 60_000)
        let nestedApp = try sandbox.write("Library/Caches/com.example.app/Helper.app/big.bin", bytes: 60_000)

        let scanned = LargeFileScanner(home: sandbox.home, minimumBytes: 40_000, includeAppData: true, lastActivity: { _ in nil }).scan()
        #expect(Set(scanned.map(\.url.lastPathComponent)) == ["data.bin", "Docker.raw"])

        let remover = try RecordingRemover(bin: sandbox.home.appendingPathComponent(".Trash"))
        let inputs = [allowedOwnerData, allowedDocker, realAppInner, nestedRtfd, nestedVm, nestedApp].map {
            LargeFile(url: $0, sizeBytes: 60_000, lastActivity: nil, kind: .other, appData: LargeFileScanner.appDataLocation(of: $0, home: sandbox.home))
        }
        let report = LargeFileRemover(home: sandbox.home, policy: LargeFileRemover.policy(home: sandbox.home), remover: remover, log: nil)
            .perform(inputs)

        #expect(Set(report.removed.map(\.url)) == [allowedOwnerData, allowedDocker])
        #expect(report.skipped.count == 4)
        for url in [realAppInner, nestedRtfd, nestedVm, nestedApp] {
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
    }

    #if os(macOS)
    @Test func macOSHiddenFlagIsRejectedExceptLibraryRootItself() throws {
        let sandbox = try Sandbox()
        var library = sandbox.home.appendingPathComponent("Library")
        var values = URLResourceValues()
        values.isHidden = true
        try library.setResourceValues(values)

        let vaultFile = try sandbox.write("Documents/Vault/big.bin", bytes: 60_000)
        var vaultFolder = sandbox.home.appendingPathComponent("Documents/Vault")
        try vaultFolder.setResourceValues(values)

        var hiddenFile = try sandbox.write("Documents/hidden.bin", bytes: 60_000)
        try hiddenFile.setResourceValues(values)

        let hiddenSubFile = try sandbox.write("Library/Application Support/Steam/HiddenSub/big.bin", bytes: 60_000)
        var hiddenSub = sandbox.home.appendingPathComponent("Library/Application Support/Steam/HiddenSub")
        try hiddenSub.setResourceValues(values)

        let steamAllowed = try sandbox.write("Library/Application Support/Steam/game.vpk", bytes: 60_000)

        let scanned = LargeFileScanner(home: sandbox.home, minimumBytes: 40_000, includeAppData: true, lastActivity: { _ in nil }).scan()
        #expect(scanned.map(\.url.lastPathComponent) == ["game.vpk"])

        let remover = try RecordingRemover(bin: sandbox.home.appendingPathComponent(".Trash"))
        let inputs = [vaultFile, hiddenFile, hiddenSubFile, steamAllowed].map {
            LargeFile(url: $0, sizeBytes: 60_000, lastActivity: nil, kind: .other, appData: LargeFileScanner.appDataLocation(of: $0, home: sandbox.home))
        }
        let report = LargeFileRemover(home: sandbox.home, policy: LargeFileRemover.policy(home: sandbox.home), remover: remover, log: nil)
            .perform(inputs)

        #expect(report.removed.map(\.url) == [steamAllowed])
        #expect(report.skipped.count == 3)
        for url in [vaultFile, hiddenFile, hiddenSubFile] {
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
    }
    #else
    @Test func linuxFallbackDetectsCustomBundleWithInfoPlist() throws {
        let sandbox = try Sandbox()
        try sandbox.write("Documents/Custom.mybundle/Contents/Info.plist", bytes: 100)
        let inner = try sandbox.write("Documents/Custom.mybundle/Contents/big.bin", bytes: 60_000)

        #expect(scanner(sandbox).scan().isEmpty)

        let remover = try RecordingRemover(bin: sandbox.home.appendingPathComponent(".Trash"))
        let report = LargeFileRemover(home: sandbox.home, policy: LargeFileRemover.policy(home: sandbox.home), remover: remover, log: nil)
            .perform([LargeFile(url: inner, sizeBytes: 60_000, lastActivity: nil, kind: .other)])

        #expect(report.removed.isEmpty)
        #expect(report.skipped.count == 1)
        #expect(FileManager.default.fileExists(atPath: inner.path))
    }
    #endif
}
