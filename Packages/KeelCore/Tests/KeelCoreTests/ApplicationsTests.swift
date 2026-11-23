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

    // MARK: LaunchAgent bootout

    private func writeAgentPlist(in sandbox: Sandbox, name: String, label: String?) throws -> URL {
        let agents = sandbox.home.appendingPathComponent("Library/LaunchAgents", isDirectory: true)
        try FileManager.default.createDirectory(at: agents, withIntermediateDirectories: true)
        let url = agents.appendingPathComponent(name)
        var dict: [String: Any] = ["RunAtLoad": true]
        if let label { dict["Label"] = label }
        let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        try data.write(to: url)
        return url
    }

    @Test func bootsOutLaunchAgentsBeforeTrashingAppAndOtherFiles() throws {
        let sandbox = try Sandbox()
        let app = try #require(AppInventory.read(try sandbox.app("Applications/Editor.app", bundleID: "com.vendor.editor")))
        let cache = try sandbox.write("Library/Caches/com.vendor.editor/huge.bin", bytes: 50_000)
        let plist = try writeAgentPlist(in: sandbox, name: "com.vendor.editor.helper.plist", label: "com.vendor.editor.helper")

        // Simulate ApplicationsModel's descending size sort: big cache first, tiny plist last.
        let files = [
            RelatedFile(url: cache.deletingLastPathComponent(), kind: .caches, sizeBytes: 50_000),
            RelatedFile(url: plist, kind: .launchAgents, sizeBytes: 120),
        ]

        let lock = NSLock()
        nonisolated(unsafe) var events: [String] = []
        let policy = sandbox.uninstallPolicy()
        let stopper = LaunchAgentStopper(
            launchAgentsRoots: policy.launchAgentsRoots,
            ownBundleIdentifier: "com.samigulec.Keel",
            runner: { executable, arguments in
                #expect(executable == URL(fileURLWithPath: "/bin/launchctl"))
                #expect(arguments == ["bootout", "gui/501/com.vendor.editor.helper"])
                #expect(!arguments.contains("disable"))
                lock.withLock { events.append("bootout:\(arguments[1])") }
                return .init(exitCode: 0)
            },
            userIDProvider: { 501 }
        )

        let remover = try RecordingRemover(bin: sandbox.outside.appendingPathComponent("bin"))
        let log = ActionLog(fileURL: sandbox.home.appendingPathComponent("Library/Logs/Keel/actions.log"))
        let report = Uninstaller(policy: policy, remover: remover, log: log, agentStopper: stopper)
            .perform([UninstallPlan(app: app, removesApp: true, files: files, appSizeBytes: 1_000)])

        #expect(report.failed.isEmpty && report.skipped.isEmpty)
        #expect(events == ["bootout:gui/501/com.vendor.editor.helper"])
        // LaunchAgent plist must be trashed first, then app bundle, then remaining files.
        #expect(remover.trashed.map(\.lastPathComponent) == [
            "com.vendor.editor.helper.plist",
            "Editor.app",
            "com.vendor.editor",
        ])
        let entries = try log.entries()
        #expect(entries.first?.detail == "launchctl bootout com.vendor.editor.helper (exit 0)")
    }

    @Test func toleratesNotLoadedExitCodesAndFailsClosedOnOtherErrors() throws {
        for tolerated: Int32 in [3, 113] {
            let sandbox = try Sandbox()
            let app = try #require(AppInventory.read(try sandbox.app("Applications/Editor.app", bundleID: "com.vendor.editor")))
            let plist = try writeAgentPlist(in: sandbox, name: "com.vendor.editor.agent.plist", label: "com.vendor.editor.agent")
            let policy = sandbox.uninstallPolicy()
            let stopper = LaunchAgentStopper(
                launchAgentsRoots: policy.launchAgentsRoots,
                runner: { _, _ in .init(exitCode: tolerated) },
                userIDProvider: { 501 }
            )
            let remover = try RecordingRemover(bin: sandbox.outside.appendingPathComponent("bin"))
            // Reset flow (removesApp: false) stops & trashes agent while keeping app bundle.
            let report = Uninstaller(policy: policy, remover: remover, log: nil, agentStopper: stopper)
                .perform([UninstallPlan(app: app, removesApp: false, files: [RelatedFile(url: plist, kind: .launchAgents, sizeBytes: 100)], appSizeBytes: 1_000)])

            #expect(report.failed.isEmpty)
            #expect(remover.trashed.map(\.lastPathComponent) == ["com.vendor.editor.agent.plist"])
            #expect(FileManager.default.fileExists(atPath: app.url.path))
        }

        // Non-tolerated exit code (e.g. 5) must fail closed: plist stays on disk and ActionLog records failure.
        let sandbox = try Sandbox()
        let app = try #require(AppInventory.read(try sandbox.app("Applications/Editor.app", bundleID: "com.vendor.editor")))
        let plist = try writeAgentPlist(in: sandbox, name: "com.vendor.editor.stuck.plist", label: "com.vendor.editor.stuck")
        let policy = sandbox.uninstallPolicy()
        let stopper = LaunchAgentStopper(
            launchAgentsRoots: policy.launchAgentsRoots,
            runner: { _, _ in .init(exitCode: 5, output: "I/O error") },
            userIDProvider: { 501 }
        )
        let remover = try RecordingRemover(bin: sandbox.outside.appendingPathComponent("bin"))
        let log = ActionLog(fileURL: sandbox.home.appendingPathComponent("Library/Logs/Keel/actions.log"))
        let report = Uninstaller(policy: policy, remover: remover, log: log, agentStopper: stopper)
            .perform([UninstallPlan(app: app, removesApp: false, files: [RelatedFile(url: plist, kind: .launchAgents, sizeBytes: 100)], appSizeBytes: 1_000)])

        #expect(report.removed.isEmpty)
        #expect(report.failed.count == 1)
        #expect(remover.trashed.isEmpty)
        #expect(FileManager.default.fileExists(atPath: plist.path))
        let entries = try log.entries()
        #expect(entries.count == 1 && entries[0].outcome == .failed)
        #expect(entries[0].detail?.contains("exit 5") == true)
    }

    @Test func refusesUnsafeAppleKeelAndSymlinkLaunchAgentsInPolicyAndStopper() throws {
        let sandbox = try Sandbox()
        let agents = sandbox.home.appendingPathComponent("Library/LaunchAgents", isDirectory: true)
        try FileManager.default.createDirectory(at: agents, withIntermediateDirectories: true)

        let appleUpper = try writeAgentPlist(in: sandbox, name: "COM.APPLE.helper.plist", label: "COM.APPLE.helper")
        let keelOwn = try writeAgentPlist(in: sandbox, name: "com.samigulec.Keel.plist", label: "com.samigulec.Keel")
        let keelSub = try writeAgentPlist(in: sandbox, name: "com.samigulec.Keel.fan.plist", label: "com.samigulec.Keel.fan")
        let customOwn = try writeAgentPlist(in: sandbox, name: "org.custom.keel.helper.plist", label: "org.custom.keel.helper")
        let emptyLabel = try writeAgentPlist(in: sandbox, name: "empty.plist", label: "")
        let slashLabel = try writeAgentPlist(in: sandbox, name: "slash.plist", label: "bad/label")
        let dotLabel = try writeAgentPlist(in: sandbox, name: "dot.plist", label: ".")
        let dotDotLabel = try writeAgentPlist(in: sandbox, name: "dotdot.plist", label: "..")
        let missingLabel = try writeAgentPlist(in: sandbox, name: "missing.plist", label: nil)
        let badXML = agents.appendingPathComponent("corrupt.plist")
        try Data("not a plist".utf8).write(to: badXML)
        let nonPlist = agents.appendingPathComponent("notes.txt")
        try Data("hello".utf8).write(to: nonPlist)
        let dirPlist = agents.appendingPathComponent("folder.plist")
        try FileManager.default.createDirectory(at: dirPlist, withIntermediateDirectories: true)
        let outsidePlist = sandbox.outside.appendingPathComponent("real.plist")
        try PropertyListSerialization.data(fromPropertyList: ["Label": "com.vendor.real"], format: .xml, options: 0).write(to: outsidePlist)
        let symlinkPlist = try sandbox.symlink("Library/LaunchAgents/link.plist", to: outsidePlist)

        let policy = UninstallPolicy(
            appRoots: [sandbox.applications],
            fileRoots: AppLeftoverFinder.locations.map { sandbox.home.appendingPathComponent($0.path, isDirectory: true) },
            protectedRoots: SafetyPolicy.standardProtectedRoots(home: sandbox.home).filter { $0.path != "/Applications" },
            ownBundle: nil,
            ownBundleIdentifier: "org.custom.keel"
        )

        nonisolated(unsafe) var runnerCalls = 0
        let stopper = LaunchAgentStopper(
            launchAgentsRoots: policy.launchAgentsRoots,
            ownBundleIdentifier: "org.custom.keel",
            runner: { _, _ in
                runnerCalls += 1
                return .init(exitCode: 0)
            },
            userIDProvider: { 501 }
        )

        let unsafeURLs = [
            appleUpper, keelOwn, keelSub, customOwn, emptyLabel,
            slashLabel, dotLabel, dotDotLabel, missingLabel, badXML,
            nonPlist, dirPlist, symlinkPlist,
        ]
        for url in unsafeURLs {
            // Even when passed with a non-.launchAgents kind, canonical parent under Library/LaunchAgents triggers full checks.
            let file = RelatedFile(url: url, kind: .preferences, sizeBytes: 10)
            #expect(policy.evaluateFile(file) != .allowed, "policy should deny \(url.lastPathComponent)")
            if case .success = stopper.stop(at: url) {
                Issue.record("stopper should fail for \(url.lastPathComponent)")
            }
        }
        #expect(runnerCalls == 0)
    }
}
