import Foundation

/// Everything a scan needs to know about the moment it runs.
public struct ScanContext: Sendable {
    public var now: Date
    /// Bundle IDs of running apps; their files are skipped.
    public var runningBundleIDs: Set<String>
    /// Last time the user touched an item, used for "old" rules.
    public var lastActivity: @Sendable (URL) -> Date?

    public init(
        now: Date = Date(),
        runningBundleIDs: Set<String> = [],
        lastActivity: @escaping @Sendable (URL) -> Date? = FileActivity.lastActivity(of:)
    ) {
        self.now = now
        self.runningBundleIDs = runningBundleIDs
        self.lastActivity = lastActivity
    }
}

/// Something found on disk that may become a cleanup item.
public struct Candidate: Sendable {
    public let url: URL
    /// Bundle ID of the app that owns the item, if known.
    public let owner: String?
    public let lastActivity: Date?
}

/// Finds candidates for one cleanup category. Sources only list what they
/// find; the scanner applies the safety policy and running-app checks.
public protocol CandidateSource: Sendable {
    func candidates(in context: ScanContext) -> [Candidate]
}

private let ignoredNames: Set<String> = [".DS_Store", ".localized"]

/// The direct children of a folder, e.g. each app's folder in ~/Library/Caches.
public struct ChildrenSource: CandidateSource {
    public enum Ownership: Sendable {
        case none
        case fixed(String)
        /// Folder names like `com.vendor.app` are taken as bundle IDs.
        case bundleIDFromName
    }

    public let root: URL
    public var ownership: Ownership = .none
    public var excludedNames: Set<String> = []
    public var excludedPrefixes: [String] = []
    /// Only children the user has not touched for this long.
    public var minimumAge: TimeInterval?

    public init(
        root: URL,
        ownership: Ownership = .none,
        excludedNames: Set<String> = [],
        excludedPrefixes: [String] = [],
        minimumAge: TimeInterval? = nil
    ) {
        self.root = root
        self.ownership = ownership
        self.excludedNames = excludedNames
        self.excludedPrefixes = excludedPrefixes
        self.minimumAge = minimumAge
    }

    public func candidates(in context: ScanContext) -> [Candidate] {
        guard let children = try? FileManager.default.contentsOfDirectory(
            at: root, includingPropertiesForKeys: nil, options: []
        ) else { return [] }

        return children.compactMap { child in
            let name = child.lastPathComponent
            guard !ignoredNames.contains(name),
                  !excludedNames.contains(name),
                  !excludedPrefixes.contains(where: { name.hasPrefix($0) }) else { return nil }

            let lastActivity = context.lastActivity(child)
            if let minimumAge {
                guard let lastActivity, context.now.timeIntervalSince(lastActivity) >= minimumAge else { return nil }
            }
            return Candidate(url: child, owner: owner(forName: name), lastActivity: lastActivity)
        }
    }

    private func owner(forName name: String) -> String? {
        switch ownership {
        case .none: nil
        case .fixed(let bundleID): bundleID
        case .bundleIDFromName: name.contains(".") ? name : nil
        }
    }
}

/// Every file below a folder that has not been modified for a while, e.g. old logs.
public struct AgedFilesSource: CandidateSource {
    public let root: URL
    public let minimumAge: TimeInterval

    public init(root: URL, minimumAge: TimeInterval) {
        self.root = root
        self.minimumAge = minimumAge
    }

    public func candidates(in context: ScanContext) -> [Candidate] {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .contentModificationDateKey]
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: Array(keys),
            options: [],
            errorHandler: { _, _ in true }
        ) else { return [] }

        var found: [Candidate] = []
        for case let file as URL in enumerator {
            guard !ignoredNames.contains(file.lastPathComponent),
                  let values = try? file.resourceValues(forKeys: keys),
                  values.isRegularFile == true,
                  let modified = values.contentModificationDate,
                  context.now.timeIntervalSince(modified) >= minimumAge else { continue }
            found.append(Candidate(url: file, owner: nil, lastActivity: modified))
        }
        return found
    }
}

/// Known locations, e.g. a browser's cache folder.
public struct FixedPathsSource: CandidateSource {
    public struct Entry: Sendable {
        public let url: URL
        public let owner: String?

        public init(url: URL, owner: String?) {
            self.url = url
            self.owner = owner
        }
    }

    public let entries: [Entry]

    public init(_ entries: [Entry]) {
        self.entries = entries
    }

    public func candidates(in context: ScanContext) -> [Candidate] {
        entries
            .filter { FileManager.default.fileExists(atPath: $0.url.path) }
            .map { Candidate(url: $0.url, owner: $0.owner, lastActivity: context.lastActivity($0.url)) }
    }
}
