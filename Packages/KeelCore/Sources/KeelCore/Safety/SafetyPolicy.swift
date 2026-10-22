import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// The single gatekeeper for every destructive file operation in Keel.
///
/// Nothing may be moved to the Trash unless `evaluate(_:)` returns `.allowed`.
/// The policy is an allowlist: an item must live strictly *inside* one of the
/// allowed roots, must not touch a protected location, and must not reach its
/// target through a symbolic link or onto another volume.
public struct SafetyPolicy: Sendable {
    public enum Verdict: Hashable, Sendable {
        case allowed
        case denied(DenialReason)

        public var isAllowed: Bool { self == .allowed }
    }

    public enum DenialReason: Hashable, Sendable, CustomStringConvertible {
        case notFileURL
        case doesNotExist
        case outsideAllowedRoots
        /// The item is an allowed root itself; only its contents may be removed.
        case isAllowedRoot
        case protectedLocation(String)
        /// The item would remove a protected location along with it.
        case containsProtectedLocation(String)
        case insideAppBundle
        case differentVolume

        public var description: String {
            switch self {
            case .notFileURL: "not a file URL"
            case .doesNotExist: "item does not exist"
            case .outsideAllowedRoots: "outside the allowed locations"
            case .isAllowedRoot: "is an allowed root itself"
            case .protectedLocation(let path): "inside protected location \(path)"
            case .containsProtectedLocation(let path): "contains protected location \(path)"
            case .insideAppBundle: "inside an application bundle"
            case .differentVolume: "on a different volume than its allowed root"
            }
        }
    }

    public let allowedRoots: [String]
    public let protectedRoots: [String]

    public init(allowedRoots: [URL], protectedRoots: [URL]) {
        self.allowedRoots = allowedRoots.map(Self.canonicalPath)
        self.protectedRoots = protectedRoots.map(Self.canonicalPath)
    }

    public func evaluate(_ url: URL) -> Verdict {
        guard url.isFileURL else { return .denied(.notFileURL) }

        let lexical = url.standardizedFileURL
        // lstat does not follow a trailing symlink, so a dangling link still
        // counts as existing (trashing it removes only the link).
        guard let itemDevice = Self.deviceID(lexical.path, followLinks: false) else {
            return .denied(.doesNotExist)
        }

        // Resolve every symlink in the parent chain, so a link planted inside an
        // allowed root cannot redirect us into a protected location. The last
        // component stays unresolved on purpose.
        guard let parent = Self.realPath(lexical.deletingLastPathComponent().path) else {
            return .denied(.doesNotExist)
        }
        let path = Self.join(parent, lexical.lastPathComponent)

        if Self.isInsideAppBundle(path) {
            return .denied(.insideAppBundle)
        }

        for protected in protectedRoots {
            if Self.isSameOrDescendant(path, of: protected) {
                return .denied(.protectedLocation(protected))
            }
            if Self.isSameOrDescendant(protected, of: path) {
                return .denied(.containsProtectedLocation(protected))
            }
        }

        let matchingRoot = allowedRoots
            .filter { Self.isSameOrDescendant(path, of: $0) }
            .max { $0.count < $1.count }
        guard let root = matchingRoot else { return .denied(.outsideAllowedRoots) }
        if path == root { return .denied(.isAllowedRoot) }

        guard Self.deviceID(root, followLinks: true) == itemDevice else {
            return .denied(.differentVolume)
        }

        return .allowed
    }

    // MARK: - Path helpers

    /// Resolves symlinks in the deepest existing ancestor and appends the rest,
    /// so a root that does not exist yet (e.g. DerivedData before the first
    /// Xcode build) still matches once it is created.
    static func canonicalPath(_ url: URL) -> String {
        var existing = url.standardizedFileURL.path
        var missing: [String] = []
        while realPath(existing) == nil, existing != "/" {
            missing.insert((existing as NSString).lastPathComponent, at: 0)
            existing = (existing as NSString).deletingLastPathComponent
        }
        return missing.reduce(realPath(existing) ?? existing, join)
    }

    static func realPath(_ path: String) -> String? {
        guard let resolved = realpath(path, nil) else { return nil }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    static func deviceID(_ path: String, followLinks: Bool) -> UInt64? {
        var info = stat()
        let result = followLinks ? stat(path, &info) : lstat(path, &info)
        return result == 0 ? UInt64(info.st_dev) : nil
    }

    /// True when the path is, or is inside, a real application bundle.
    /// Cache folders are often named after bundle IDs like `com.vendor.app`,
    /// so the `.app` suffix alone is not enough: the bundle structure must exist.
    static func isInsideAppBundle(_ path: String) -> Bool {
        var ancestor = ""
        for component in components(of: path) {
            ancestor += "/" + component
            guard component.lowercased().hasSuffix(".app") else { continue }
            if FileManager.default.fileExists(atPath: ancestor + "/Contents/Info.plist")
                || FileManager.default.fileExists(atPath: ancestor + "/Info.plist") {
                return true
            }
        }
        return false
    }

    static func join(_ parent: String, _ name: String) -> String {
        parent.hasSuffix("/") ? parent + name : parent + "/" + name
    }

    static func components(of path: String) -> [String] {
        path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
    }

    /// Component-wise comparison, so `/a/Caches2` is not treated as inside `/a/Caches`.
    static func isSameOrDescendant(_ path: String, of ancestor: String) -> Bool {
        let pathComponents = components(of: path)
        let ancestorComponents = components(of: ancestor)
        guard pathComponents.count >= ancestorComponents.count else { return false }
        return Array(pathComponents.prefix(ancestorComponents.count)) == ancestorComponents
    }
}

extension SafetyPolicy {
    /// Locations Keel may clean in Phase 1, all inside the user's home folder.
    public static func standardAllowedRoots(home: URL) -> [URL] {
        [
            "Library/Caches",
            "Library/Logs",
            ".Trash",
            "Downloads",
            "Library/Developer/Xcode/DerivedData",
            "Library/Developer/CoreSimulator/Caches",
        ].map { home.appendingPathComponent($0, isDirectory: true) }
    }

    /// Locations that must never be touched, even if an allowed root contains them.
    public static func standardProtectedRoots(home: URL) -> [URL] {
        let system = [
            "/System",
            "/bin",
            "/sbin",
            "/usr",
            "/private/var/db",
            "/Library/Apple",
            "/Applications",
        ].map { URL(fileURLWithPath: $0, isDirectory: true) }

        let user = [
            "Library/Keychains",
            "Library/Mobile Documents",
            "Library/Mail",
            "Library/Messages",
            "Library/Photos",
            "Library/Logs/Keel",
            "Pictures/Photos Library.photoslibrary",
        ].map { home.appendingPathComponent($0, isDirectory: true) }

        return system + user
    }

    public static func standard(
        home: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> SafetyPolicy {
        SafetyPolicy(
            allowedRoots: standardAllowedRoots(home: home),
            protectedRoots: standardProtectedRoots(home: home)
        )
    }
}
