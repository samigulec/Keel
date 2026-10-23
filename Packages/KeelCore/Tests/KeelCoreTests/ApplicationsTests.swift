import Foundation
import Testing
@testable import KeelCore

extension Sandbox {
    /// A minimal app bundle: Info.plist, an executable header, and optionally
    /// the App Store receipt.
    @discardableResult
    func app(
        _ relativePath: String,
        bundleID: String,
        version: String = "1.0",
        executable: [UInt8] = [0xCF, 0xFA, 0xED, 0xFE, 0x0C, 0x00, 0x00, 0x01],
        appStore: Bool = false
    ) throws -> URL {
        let url = home.appendingPathComponent(relativePath, isDirectory: true)
        let contents = url.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contents.appendingPathComponent("MacOS"), withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "CFBundleIdentifier": bundleID,
            "CFBundleShortVersionString": version,
            "CFBundleExecutable": "main",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: contents.appendingPathComponent("Info.plist"))
        try Data(executable + [UInt8](repeating: 0, count: 64)).write(to: contents.appendingPathComponent("MacOS/main"))
        if appStore {
            try self.write("_MASReceipt/receipt", bytes: 10, in: contents)
        }
        return url
    }

    var applications: URL { home.appendingPathComponent("Applications", isDirectory: true) }

    func uninstallPolicy(ownBundle: URL? = nil) -> UninstallPolicy {
        UninstallPolicy(
            appRoots: [applications],
            fileRoots: AppLeftoverFinder.locations.map { home.appendingPathComponent($0.path, isDirectory: true) },
            protectedRoots: SafetyPolicy.standardProtectedRoots(home: home).filter { $0.path != "/Applications" },
            ownBundle: ownBundle
        )
    }
}

@Suite("Applications")
struct ApplicationsTests {
    // MARK: Architecture

    @Test func readsArchitectureFromMachOHeaders() {
        let thinARM: [UInt8] = [0xCF, 0xFA, 0xED, 0xFE, 0x0C, 0x00, 0x00, 0x01]
        let thinIntel: [UInt8] = [0xCF, 0xFA, 0xED, 0xFE, 0x07, 0x00, 0x00, 0x01]
        // Fat header: magic, two entries of 20 bytes, each starting with a CPU type.
        var fat: [UInt8] = [0xCA, 0xFE, 0xBA, 0xBE, 0x00, 0x00, 0x00, 0x02]
        fat += [0x01, 0x00, 0x00, 0x07] + [UInt8](repeating: 0, count: 16)
        fat += [0x01, 0x00, 0x00, 0x0C] + [UInt8](repeating: 0, count: 16)

        #expect(AppArchitecture.of(header: Data(thinARM)) == .appleSilicon)
        #expect(AppArchitecture.of(header: Data(thinIntel)) == .intel)
        #expect(AppArchitecture.of(header: Data(fat)) == .universal)
        #expect(AppArchitecture.of(header: Data("#!/bin/sh\n".utf8)) == .unknown)
        #expect(AppArchitecture.of(header: Data()) == .unknown)
    }

    // MARK: Inventory

    @Test func findsAppsInRootsAndVendorFolders() throws {
        let sandbox = try Sandbox()
        try sandbox.app("Applications/Editor.app", bundleID: "com.vendor.editor", appStore: true)
        try sandbox.app("Applications/Vendor/Tool.app", bundleID: "com.vendor.tool",
                        executable: [0xCF, 0xFA, 0xED, 0xFE, 0x07, 0x00, 0x00, 0x01])
        // Apps inside apps, and folders two levels down, are not listed.
        try sandbox.app("Applications/Editor.app/Contents/Helpers/Helper.app", bundleID: "com.vendor.editor.helper")
        try sandbox.app("Applications/Vendor/Deep/Hidden.app", bundleID: "com.vendor.hidden")
        _ = try sandbox.symlink("Applications/Link.app", to: sandbox.applications.appendingPathComponent("Editor.app"))
        try sandbox.write("Applications/NotAnApp.app/readme.txt", bytes: 4)

        let apps = AppInventory.scan(roots: [sandbox.applications])

        #expect(apps.map(\.name).sorted() == ["Editor", "Tool"])
        let editor = try #require(apps.first { $0.name == "Editor" })
        #expect(editor.bundleID == "com.vendor.editor")
        #expect(editor.source == .appStore)
        #expect(editor.architecture == .appleSilicon)
        #expect(apps.first { $0.name == "Tool" }?.architecture == .intel)
    }

    // MARK: Related files

    @Test func findsOnlyTheAppsOwnFiles() throws {
        let sandbox = try Sandbox()
        let editor = try #require(AppInventory.read(try sandbox.app("Applications/Editor.app", bundleID: "com.Vendor.Editor")))
        for path in [
            "Library/Application Support/com.vendor.editor/state.db",
            "Library/Application Support/Editor/cache.bin",
            "Library/Caches/com.vendor.editor/blob",
            "Library/Caches/com.vendor.editor.ShipIt/update",
            "Library/Preferences/com.vendor.editor.plist",
            "Library/Preferences/ByHost/com.vendor.editor.7A1B2C3D-0000-4000-8000-123456789ABC.plist",
            "Library/Containers/com.vendor.editor.share-extension/data",
            "Library/Group Containers/ABCDE12345.com.vendor.editor/data",
            "Library/Saved Application State/com.vendor.editor.savedState/window",
            "Library/HTTPStorages/com.vendor.editor/cookies",
            // Another installed app's files, even though its id starts the same.
            "Library/Caches/com.vendor.editor.pro/blob",
            "Library/Preferences/com.vendor.editor.pro.plist",
            // Unrelated.
            "Library/Caches/com.vendor.editorial/blob",
            "Library/Preferences/com.other.app.plist",
        ] {
            try sandbox.write(path, bytes: 100)
        }

        let finder = AppLeftoverFinder(home: sandbox.home, installedBundleIDs: ["com.vendor.editor", "com.vendor.editor.pro"])
        let files = finder.relatedFiles(for: editor)
        let found = Set(files.map { $0.url.path.replacingOccurrences(of: sandbox.home.path + "/", with: "") })

        #expect(found == [
            "Library/Application Support/com.vendor.editor",
            "Library/Application Support/Editor",
            "Library/Caches/com.vendor.editor",
            "Library/Caches/com.vendor.editor.ShipIt",
            "Library/Preferences/com.vendor.editor.plist",
            "Library/Preferences/ByHost/com.vendor.editor.7A1B2C3D-0000-4000-8000-123456789ABC.plist",
            "Library/Containers/com.vendor.editor.share-extension",
            "Library/Group Containers/ABCDE12345.com.vendor.editor",
            "Library/Saved Application State/com.vendor.editor.savedState",
            "Library/HTTPStorages/com.vendor.editor",
        ])
        #expect(files.allSatisfy { $0.sizeBytes > 0 })
        #expect(files.first { $0.url.lastPathComponent == "com.vendor.editor.plist" }?.kind == .preferences)
    }

    @Test func genericNamesDoNotMatchByName() throws {
        let sandbox = try Sandbox()
        let app = try #require(AppInventory.read(try sandbox.app("Applications/Google.app", bundleID: "com.example.google")))
        try sandbox.write("Library/Application Support/Google/Chrome/data", bytes: 10)
        let finder = AppLeftoverFinder(home: sandbox.home, installedBundleIDs: ["com.example.google"])
        #expect(finder.relatedFiles(for: app).isEmpty)
    }

    // MARK: Removing

    @Test func uninstallsAppAndFilesToTheTrash() throws {
        let sandbox = try Sandbox()
        let app = try #require(AppInventory.read(try sandbox.app("Applications/Editor.app", bundleID: "com.vendor.editor")))
        try sandbox.write("Library/Caches/com.vendor.editor/blob", bytes: 500)
        let files = AppLeftoverFinder(home: sandbox.home, installedBundleIDs: ["com.vendor.editor"]).relatedFiles(for: app)
        let remover = try RecordingRemover(bin: sandbox.outside.appendingPathComponent("bin"))

        let report = Uninstaller(policy: sandbox.uninstallPolicy(), remover: remover, log: nil)
            .perform([UninstallPlan(app: app, removesApp: true, files: files, appSizeBytes: 1_000)])

        #expect(report.failed.isEmpty && report.skipped.isEmpty)
        #expect(remover.trashed.map(\.lastPathComponent) == ["Editor.app", "com.vendor.editor"])
        #expect(remover.deleted.isEmpty)
        #expect(report.removedApps.map(\.name) == ["Editor"])
        #expect(report.freedBytes == 1_000 + files[0].sizeBytes)
    }

    @Test func leavesRunningAppsAndKeelAlone() throws {
        let sandbox = try Sandbox()
        let editor = try #require(AppInventory.read(try sandbox.app("Applications/Editor.app", bundleID: "com.vendor.editor")))
        let keelURL = try sandbox.app("Applications/Keel.app", bundleID: "com.samigulec.Keel")
        let keel = try #require(AppInventory.read(keelURL))
        let remover = try RecordingRemover(bin: sandbox.outside.appendingPathComponent("bin"))

        let report = Uninstaller(policy: sandbox.uninstallPolicy(ownBundle: keelURL), remover: remover, log: nil).perform(
            [
                UninstallPlan(app: editor, removesApp: true, files: [], appSizeBytes: 1),
                UninstallPlan(app: keel, removesApp: true, files: [], appSizeBytes: 1),
            ],
            runningBundleIDs: ["COM.VENDOR.EDITOR"]
        )

        #expect(remover.trashed.isEmpty)
        #expect(report.skipped.map(\.message) == ["Editor açık", "Keel'in kendisi"])
    }

    @Test func refusesAppsOutsideInstallFoldersAndFilesOutsideLibrary() throws {
        let sandbox = try Sandbox()
        let stray = try #require(AppInventory.read(try sandbox.app("Documents/Stray.app", bundleID: "com.vendor.stray")))
        let policy = sandbox.uninstallPolicy()

        #expect(policy.evaluateApp(stray) == .denied("uygulama klasörlerinin dışında"))

        let deep = RelatedFile(url: try sandbox.write("Library/Caches/com.vendor.stray/inner/file", bytes: 1), kind: .caches, sizeBytes: 1)
        #expect(policy.evaluateFile(deep) == .denied("arama klasörlerinin doğrudan içinde değil"))

        let document = RelatedFile(url: try sandbox.file("Documents/notes.txt"), kind: .supportFiles, sizeBytes: 1)
        #expect(policy.evaluateFile(document) != .allowed)

        let keychain = RelatedFile(url: try sandbox.file("Library/Keychains/login.keychain-db"), kind: .supportFiles, sizeBytes: 1)
        #expect(policy.evaluateFile(keychain) != .allowed)
    }

    @Test func refusesLinksPosingAsApps() throws {
        let sandbox = try Sandbox()
        let real = try sandbox.app("Documents/Real.app", bundleID: "com.vendor.real")
        try FileManager.default.createDirectory(at: sandbox.applications, withIntermediateDirectories: true)
        let link = try sandbox.symlink("Applications/Real.app", to: real)
        let app = InstalledApp(url: link, name: "Real", bundleID: "com.vendor.real", version: nil, source: .other, architecture: .unknown, isSystem: false)

        #expect(sandbox.uninstallPolicy().evaluateApp(app) == .denied("bir kısayol"))
    }
}
