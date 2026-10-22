import Foundation
import Testing
@testable import KeelCore

@Suite("CleanupScanner")
struct CleanupScannerTests {
    @Test func findsAppCachesButLeavesAppleBrowsersAndKeelAlone() async throws {
        let sandbox = try Sandbox()
        try sandbox.write("Library/Caches/com.spotify.client/data", bytes: 30_000)
        try sandbox.write("Library/Caches/com.todesktop.230313mzl4w4u92/blob", bytes: 20_000)
        try sandbox.write("Library/Caches/com.apple.Safari/cache.db", bytes: 20_000)
        try sandbox.write("Library/Caches/Google/Chrome/Default/blob", bytes: 20_000)
        try sandbox.write("Library/Caches/com.samigulec.Keel/state", bytes: 20_000)

        let results = try await sandbox.scanner.scan(context: sandbox.context())
        #expect(results[.userCaches].names == ["com.spotify.client", "com.todesktop.230313mzl4w4u92"])
        #expect(results[.browserCaches].names == ["Chrome"])
        #expect(results[.userCaches].items.allSatisfy { $0.removal == .moveToTrash })
    }

    @Test func leavesAppleServicesAndToolInstallsAlone() async throws {
        let sandbox = try Sandbox()
        try sandbox.write("Library/Caches/GeoServices/tiles.db", bytes: 20_000)
        try sandbox.write("Library/Caches/PassKit/pass.db", bytes: 20_000)
        try sandbox.write("Library/Caches/ms-playwright-go/chromium/chrome", bytes: 20_000)
        try sandbox.write("Library/Caches/ms-playwright/firefox/firefox", bytes: 20_000)

        let results = try await sandbox.scanner.scan(context: sandbox.context())
        #expect(results.allSatisfy { $0.items.isEmpty })
    }

    @Test func developerToolCachesAreOptIn() async throws {
        let sandbox = try Sandbox()
        try sandbox.write("Library/Caches/Homebrew/bottle.tar.gz", bytes: 20_000)
        try sandbox.write("Library/Caches/pip/http/x", bytes: 20_000)
        try sandbox.write("Library/Caches/com.spotify.client/data", bytes: 20_000)

        let results = try await sandbox.scanner.scan(context: sandbox.context())
        #expect(results[.userCaches].names == ["com.spotify.client"])
        #expect(results[.developer].names == ["Homebrew", "pip"])
        #expect(results[.developer].category.selectedByDefault == false)
    }

    @Test func skipsCachesOfRunningApps() async throws {
        let sandbox = try Sandbox()
        try sandbox.write("Library/Caches/com.spotify.client/data", bytes: 30_000)
        try sandbox.write("Library/Caches/Google/Chrome/Default/blob", bytes: 20_000)

        let results = try await sandbox.scanner.scan(
            context: sandbox.context(running: ["com.spotify.client", "com.google.Chrome"]))
        #expect(results[.userCaches].items.isEmpty)
        #expect(results[.browserCaches].items.isEmpty)
        #expect(results[.userCaches].skipped.map(\.reason) == [.appRunning(bundleID: "com.spotify.client")])
    }

    @Test func onlyOldLogsAndNeverKeelsOwn() async throws {
        let sandbox = try Sandbox()
        try sandbox.write("Library/Logs/SomeApp/old.log", bytes: 5_000, daysOld: 10)
        try sandbox.write("Library/Logs/SomeApp/fresh.log", bytes: 5_000, daysOld: 1)
        try sandbox.write("Library/Logs/Keel/actions.log", bytes: 5_000, daysOld: 30)

        let logs = try await sandbox.scanner.scan(context: sandbox.context())[.logs]
        #expect(logs.names == ["old.log"])
        #expect(logs.skipped.contains { $0.url.lastPathComponent == "actions.log" })
    }

    @Test func onlyDownloadsUntouchedFor90Days() async throws {
        let sandbox = try Sandbox()
        try sandbox.write("Downloads/old-installer.dmg", bytes: 8_000, daysOld: 120)
        try sandbox.write("Downloads/recent.pdf", bytes: 8_000, daysOld: 10)

        let results = try await sandbox.scanner.scan(context: sandbox.context())
        #expect(results[.oldDownloads].names == ["old-installer.dmg"])
        #expect(results[.oldDownloads].category.selectedByDefault == false)
    }

    @Test func trashIsDeletedPermanentlyAndNotPreselected() async throws {
        let sandbox = try Sandbox()
        try sandbox.write(".Trash/old.zip", bytes: 8_000)

        let trash = try await sandbox.scanner.scan(context: sandbox.context())[.trash]
        #expect(trash.names == ["old.zip"])
        #expect(trash.items.first?.removal == .deletePermanently)
        #expect(trash.category.selectedByDefault == false)
    }

    @Test func developerCachesBelongToXcode() async throws {
        let sandbox = try Sandbox()
        try sandbox.write("Library/Developer/Xcode/DerivedData/MyApp-abc/Build/x.o", bytes: 9_000)

        let idle = try await sandbox.scanner.scan(context: sandbox.context())
        #expect(idle[.developer].names == ["MyApp-abc"])
        let busy = try await sandbox.scanner.scan(context: sandbox.context(running: ["com.apple.dt.Xcode"]))
        #expect(busy[.developer].items.isEmpty)
    }

    @Test func symlinkIntoOutsideDataIsNeverSized() async throws {
        let sandbox = try Sandbox()
        try sandbox.write("precious.bin", bytes: 500_000, in: sandbox.outside)
        _ = try sandbox.symlink("Library/Caches/com.evil.app", to: sandbox.outside)

        let caches = try await sandbox.scanner.scan(context: sandbox.context())[.userCaches]
        #expect(caches.totalBytes < 100_000)
    }

    @Test func sortsLargestFirstAndKeepsCatalogOrder() async throws {
        let sandbox = try Sandbox()
        try sandbox.write("Library/Caches/com.small.app/a", bytes: 10_000)
        try sandbox.write("Library/Caches/com.big.app/a", bytes: 90_000)

        let results = try await sandbox.scanner.scan(context: sandbox.context())
        #expect(results.map(\.category.id) == CleanupCategoryID.allCases)
        #expect(results[.userCaches].items.map(\.url.lastPathComponent) == ["com.big.app", "com.small.app"])
    }

    @Test func scanningChangesNothingOnDisk() async throws {
        let sandbox = try Sandbox()
        let cache = try sandbox.write("Library/Caches/com.spotify.client/data", bytes: 30_000)
        let trashed = try sandbox.write(".Trash/old.zip", bytes: 8_000)
        _ = try await sandbox.scanner.scan(context: sandbox.context())
        #expect(FileManager.default.fileExists(atPath: cache.path))
        #expect(FileManager.default.fileExists(atPath: trashed.path))
    }
}
