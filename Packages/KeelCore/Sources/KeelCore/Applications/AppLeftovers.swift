import Foundation

/// A file or folder an app keeps outside its bundle: settings, caches,
/// support data. Removing the app without these leaves them behind.
public struct RelatedFile: Identifiable, Hashable, Sendable {
    public enum Kind: String, Sendable, Hashable, CaseIterable {
        case supportFiles
        case caches
        case preferences
        case containers
        case savedState
        case logs
        case webData
        case launchAgents
    }

    public var id: String { url.path }
    public let url: URL
    public let kind: Kind
    public let sizeBytes: Int64

    public init(url: URL, kind: Kind, sizeBytes: Int64) {
        self.url = url
        self.kind = kind
        self.sizeBytes = sizeBytes
    }
}

/// Finds an app's files in ~/Library by its bundle id, and for a few
/// folders by its exact name.
///
/// Matching is deliberately narrow: an entry belongs to the app when its
/// name is the bundle id, or the bundle id followed by "." (helpers,
/// extensions). When another installed app's bundle id is a closer match,
/// the entry belongs to that app instead, so removing "com.vendor.app" never
/// takes "com.vendor.app.pro"'s files.
public struct AppLeftoverFinder: Sendable {
    struct Location: Sendable {
        let path: String
        let kind: RelatedFile.Kind
        /// Whether an entry named exactly like the app counts, e.g. "Docker".
        let matchesName: Bool
    }

    static let locations: [Location] = [
        Location(path: "Library/Application Support", kind: .supportFiles, matchesName: true),
        Location(path: "Library/Caches", kind: .caches, matchesName: true),
        Location(path: "Library/Preferences", kind: .preferences, matchesName: false),
        Location(path: "Library/Preferences/ByHost", kind: .preferences, matchesName: false),
        Location(path: "Library/Containers", kind: .containers, matchesName: false),
        Location(path: "Library/Group Containers", kind: .containers, matchesName: false),
        Location(path: "Library/Application Scripts", kind: .containers, matchesName: false),
        Location(path: "Library/Saved Application State", kind: .savedState, matchesName: false),
        Location(path: "Library/Logs", kind: .logs, matchesName: true),
        Location(path: "Library/HTTPStorages", kind: .webData, matchesName: false),
        Location(path: "Library/WebKit", kind: .webData, matchesName: false),
        Location(path: "Library/Cookies", kind: .webData, matchesName: false),
        Location(path: "Library/LaunchAgents", kind: .launchAgents, matchesName: false),
    ]

    /// Suffixes that follow a bundle id in file names, e.g. "com.x.app.plist".
    static let suffixes = [".plist", ".savedstate", ".binarycookies"]

    public let home: URL
    /// Bundle ids of every installed app, lowercased.
    public let installedBundleIDs: Set<String>

    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser, installedBundleIDs: Set<String>) {
        self.home = home
        self.installedBundleIDs = Set(installedBundleIDs.map { $0.lowercased() })
    }

    public func relatedFiles(for app: InstalledApp, isCancelled: () -> Bool = { false }) -> [RelatedFile] {
        guard let bundleID = app.bundleID?.lowercased(), !bundleID.isEmpty else { return [] }
        let name = app.name.lowercased()
        // A very short or generic name could match another app's folder.
        let nameIsDistinct = name.count >= 4 && !Self.genericNames.contains(name)

        var files: [RelatedFile] = []
        var seen: Set<String> = []
        for location in Self.locations {
            let folder = home.appendingPathComponent(location.path, isDirectory: true)
            guard let entries = try? FileManager.default.contentsOfDirectory(atPath: folder.path) else { continue }
            for entry in entries.sorted() {
                if isCancelled() { return files }
                let key = Self.stripSuffix(entry.lowercased())
                let byID = owner(of: key) == bundleID
                let byName = location.matchesName && nameIsDistinct && key == name
                guard byID || byName else { continue }

                let url = folder.appendingPathComponent(entry)
                guard seen.insert(url.path).inserted else { continue }
                // Links are never followed; the size of what they point to is not the app's.
                files.append(RelatedFile(url: url, kind: location.kind, sizeBytes: DirectorySizer.allocatedSize(of: url, isCancelled: isCancelled)))
            }
        }
        return files
    }

    /// The installed app an entry belongs to: the longest bundle id that is
    /// the entry itself, its start before a ".", or its end after a "."
    /// (group containers are named "TEAMID.com.vendor.app" or "group.com.vendor.app").
    func owner(of key: String) -> String? {
        installedBundleIDs
            .filter { id in
                key == id || key.hasPrefix(id + ".") || key.hasSuffix("." + id)
            }
            .max { $0.count < $1.count }
    }

    static func stripSuffix(_ name: String) -> String {
        for suffix in suffixes where name.hasSuffix(suffix) {
            var base = String(name.dropLast(suffix.count))
            // ByHost preferences end in the Mac's hardware UUID: "com.x.app.<UUID>.plist".
            if let dot = base.lastIndex(of: "."), UUID(uuidString: String(base[base.index(after: dot)...])) != nil {
                base = String(base[..<dot])
            }
            return base
        }
        return name
    }

    /// Names that are folders of their own in ~/Library, not one app's.
    static let genericNames: Set<String> = [
        "apple", "google", "microsoft", "adobe", "mozilla", "cache", "caches", "data",
        "logs", "support", "temp", "tmp", "default", "defaults", "user", "users", "shared",
    ]
}
