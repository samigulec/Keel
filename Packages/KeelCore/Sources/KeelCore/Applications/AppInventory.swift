import Foundation

/// An application bundle the user installed.
public struct InstalledApp: Identifiable, Hashable, Sendable {
    public enum Source: String, Sendable, Hashable {
        /// Installed from the Mac App Store; it carries Apple's receipt.
        case appStore
        /// Made by Apple but installed separately, e.g. Xcode or Pages.
        case apple
        /// Downloaded from the web or installed by a package.
        case other
    }

    public var id: String { url.path }
    public let url: URL
    public let name: String
    public let bundleID: String?
    public let version: String?
    public let source: Source
    public let architecture: AppArchitecture
    /// Part of macOS itself (on the read-only system volume); it cannot be removed.
    public let isSystem: Bool

    public init(
        url: URL,
        name: String,
        bundleID: String?,
        version: String?,
        source: Source,
        architecture: AppArchitecture,
        isSystem: Bool
    ) {
        self.url = url
        self.name = name
        self.bundleID = bundleID
        self.version = version
        self.source = source
        self.architecture = architecture
        self.isSystem = isSystem
    }
}

/// Finds the applications in the usual install folders.
public enum AppInventory {
    /// /Applications and ~/Applications. Apple's own apps in /System/Applications
    /// are part of macOS and left out.
    public static func standardRoots(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> [URL] {
        [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            home.appendingPathComponent("Applications", isDirectory: true),
        ]
    }

    /// Apps directly in each root, and one folder down (e.g. /Applications/Utilities
    /// or a vendor's folder). Links are not followed, and an app is never searched
    /// for apps inside it.
    public static func scan(roots: [URL], isCancelled: () -> Bool = { false }) -> [InstalledApp] {
        var found: [InstalledApp] = []
        var seen: Set<String> = []

        func visit(_ folder: URL, depth: Int) {
            guard let children = try? FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.isSymbolicLinkKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { return }

            for child in children.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                if isCancelled() { return }
                let values = try? child.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey])
                guard values?.isSymbolicLink != true, values?.isDirectory == true else { continue }

                if child.pathExtension.lowercased() == "app" {
                    if let app = read(child), seen.insert(app.id).inserted {
                        found.append(app)
                    }
                } else if depth == 0 {
                    visit(child, depth: 1)
                }
            }
        }

        for root in roots {
            visit(root, depth: 0)
        }
        return found
    }

    /// Reads one bundle's Info.plist; nil when it is not an application.
    public static func read(_ url: URL) -> InstalledApp? {
        let contents = url.appendingPathComponent("Contents", isDirectory: true)
        guard let data = try? Data(contentsOf: contents.appendingPathComponent("Info.plist")),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }

        let bundleID = plist["CFBundleIdentifier"] as? String
        let fileName = url.deletingPathExtension().lastPathComponent
        let name = (plist["CFBundleDisplayName"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? fileName

        let source: InstalledApp.Source
        if FileManager.default.fileExists(atPath: contents.appendingPathComponent("_MASReceipt/receipt").path) {
            source = .appStore
        } else if bundleID?.lowercased().hasPrefix("com.apple.") == true {
            source = .apple
        } else {
            source = .other
        }

        let architecture = (plist["CFBundleExecutable"] as? String).map {
            AppArchitecture.of(executable: contents.appendingPathComponent("MacOS").appendingPathComponent($0))
        } ?? .unknown

        let readOnly = (try? url.resourceValues(forKeys: [.volumeIsReadOnlyKey]))?.volumeIsReadOnly ?? false

        return InstalledApp(
            url: url,
            name: name,
            bundleID: bundleID,
            version: plist["CFBundleShortVersionString"] as? String ?? plist["CFBundleVersion"] as? String,
            source: source,
            architecture: architecture,
            isSystem: readOnly
        )
    }
}
