import Foundation
import Testing
@testable import KeelCore

/// Builds a throwaway fake home folder so the policy is exercised against a
/// real file system, symlinks included.
final class Sandbox {
    let home: URL
    let outside: URL
    private let base: URL

    init() throws {
        base = FileManager.default.temporaryDirectory
            .appendingPathComponent("keel-tests-\(UUID().uuidString)", isDirectory: true)
        home = base.appendingPathComponent("home", isDirectory: true)
        outside = base.appendingPathComponent("outside", isDirectory: true)
        for directory in [
            "Library/Caches/com.example.app",
            "Library/Logs/Keel",
            "Library/Keychains",
            "Library/Mobile Documents",
            "Documents",
            ".Trash",
        ] {
            try FileManager.default.createDirectory(
                at: home.appendingPathComponent(directory), withIntermediateDirectories: true)
        }
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    }

    deinit { try? FileManager.default.removeItem(at: base) }

    @discardableResult
    func file(_ relativePath: String, in root: URL? = nil) throws -> URL {
        let url = (root ?? home).appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("x".utf8).write(to: url)
        return url
    }

    func symlink(_ relativePath: String, to destination: URL) throws -> URL {
        let url = home.appendingPathComponent(relativePath)
        try FileManager.default.createSymbolicLink(at: url, withDestinationURL: destination)
        return url
    }

    var policy: SafetyPolicy { .standard(home: home) }
}

@Suite("SafetyPolicy")
struct SafetyPolicyTests {
    @Test func allowsFileInsideCaches() throws {
        let sandbox = try Sandbox()
        let file = try sandbox.file("Library/Caches/com.example.app/blob.cache")
        #expect(sandbox.policy.evaluate(file) == .allowed)
    }

    @Test func allowsWholeCacheFolderOfAnApp() throws {
        let sandbox = try Sandbox()
        let folder = sandbox.home.appendingPathComponent("Library/Caches/com.example.app")
        #expect(sandbox.policy.evaluate(folder) == .allowed)
    }

    @Test func allowsTrashAndDownloadsContents() throws {
        let sandbox = try Sandbox()
        #expect(sandbox.policy.evaluate(try sandbox.file(".Trash/old.zip")) == .allowed)
        #expect(sandbox.policy.evaluate(try sandbox.file("Downloads/installer.dmg")) == .allowed)
    }

    @Test func deniesAllowedRootItself() throws {
        let sandbox = try Sandbox()
        let caches = sandbox.home.appendingPathComponent("Library/Caches")
        #expect(sandbox.policy.evaluate(caches) == .denied(.isAllowedRoot))
    }

    @Test func deniesEverythingOutsideAllowedRoots() throws {
        let sandbox = try Sandbox()
        let document = try sandbox.file("Documents/thesis.pages")
        #expect(sandbox.policy.evaluate(document) == .denied(.outsideAllowedRoots))
        #expect(!sandbox.policy.evaluate(sandbox.home).isAllowed)
    }

    @Test func deniesSiblingWithSharedNamePrefix() throws {
        let sandbox = try Sandbox()
        let lookalike = try sandbox.file("Library/CachesBackup/important.db")
        #expect(sandbox.policy.evaluate(lookalike) == .denied(.outsideAllowedRoots))
    }

    @Test func deniesMissingItem() throws {
        let sandbox = try Sandbox()
        let missing = sandbox.home.appendingPathComponent("Library/Caches/nope")
        #expect(sandbox.policy.evaluate(missing) == .denied(.doesNotExist))
    }

    @Test func deniesNonFileURL() throws {
        let sandbox = try Sandbox()
        let url = try #require(URL(string: "https://example.com/Library/Caches/x"))
        #expect(sandbox.policy.evaluate(url) == .denied(.notFileURL))
    }

    @Test func deniesDotDotEscapeFromAllowedRoot() throws {
        let sandbox = try Sandbox()
        try sandbox.file("Documents/secret.txt")
        let escape = URL(fileURLWithPath: sandbox.home.path + "/Library/Caches/../../Documents/secret.txt")
        #expect(sandbox.policy.evaluate(escape) == .denied(.outsideAllowedRoots))
    }

    @Test func deniesProtectedLocationNestedInAllowedRoot() throws {
        let sandbox = try Sandbox()
        let ownLog = try sandbox.file("Library/Logs/Keel/actions.log")
        #expect(sandbox.policy.evaluate(ownLog) == .denied(
            .protectedLocation(SafetyPolicy.canonicalPath(sandbox.home.appendingPathComponent("Library/Logs/Keel")))))
    }

    @Test func deniesItemThatWouldTakeAProtectedLocationWithIt() throws {
        let sandbox = try Sandbox()
        // A policy whose allowed root wraps a protected folder must still refuse the wrapper.
        let library = sandbox.home.appendingPathComponent("Library")
        let policy = SafetyPolicy(
            allowedRoots: [sandbox.home],
            protectedRoots: [library.appendingPathComponent("Keychains")]
        )
        guard case .denied(.containsProtectedLocation) = policy.evaluate(library) else {
            Issue.record("expected containsProtectedLocation")
            return
        }
    }

    @Test func deniesAnythingInsideAnAppBundle() throws {
        let sandbox = try Sandbox()
        let inner = try sandbox.file("Downloads/Tool.app/Contents/Info.plist")
        let bundle = sandbox.home.appendingPathComponent("Downloads/Tool.app")
        #expect(sandbox.policy.evaluate(bundle) == .denied(.insideAppBundle))
        #expect(sandbox.policy.evaluate(inner) == .denied(.insideAppBundle))
    }

    @Test func cacheFolderNamedLikeAnAppIsNotABundle() throws {
        let sandbox = try Sandbox()
        // Bundle-ID style names such as com.example.app are ordinary folders.
        let file = try sandbox.file("Library/Caches/com.example.app/Contents/data.bin")
        #expect(sandbox.policy.evaluate(file) == .allowed)
    }

    @Test func deniesPathThatEscapesThroughSymlinkedParent() throws {
        let sandbox = try Sandbox()
        let precious = try sandbox.file("precious.txt", in: sandbox.outside)
        _ = try sandbox.symlink("Library/Caches/sneaky", to: sandbox.outside)
        let throughLink = sandbox.home.appendingPathComponent("Library/Caches/sneaky/precious.txt")
        #expect(FileManager.default.fileExists(atPath: throughLink.path))
        #expect(sandbox.policy.evaluate(throughLink) == .denied(.outsideAllowedRoots))
        #expect(FileManager.default.fileExists(atPath: precious.path))
    }

    @Test func allowsSymlinkItselfButNeverItsTarget() throws {
        let sandbox = try Sandbox()
        try sandbox.file("precious.txt", in: sandbox.outside)
        // Trashing the link removes only the link, so the link itself is fine.
        let link = try sandbox.symlink("Library/Caches/link", to: sandbox.outside)
        #expect(sandbox.policy.evaluate(link) == .allowed)
    }

    @Test func allowsRootCreatedAfterPolicyThroughSymlinkedHome() throws {
        let sandbox = try Sandbox()
        // Like /var -> /private/var on macOS: home is reached through a link,
        // and Downloads does not exist yet when the policy is built.
        let linkedHome = sandbox.outside.appendingPathComponent("linked-home")
        try FileManager.default.createSymbolicLink(at: linkedHome, withDestinationURL: sandbox.home)
        let policy = SafetyPolicy.standard(home: linkedHome)

        let file = try sandbox.file("Downloads/installer.dmg")
        #expect(policy.evaluate(file) == .allowed)
        #expect(policy.evaluate(linkedHome.appendingPathComponent("Downloads/installer.dmg")) == .allowed)
    }

    @Test func deniesSystemLocations() throws {
        let policy = SafetyPolicy.standard(home: URL(fileURLWithPath: "/Users/nobody"))
        for path in ["/System", "/usr/bin", "/bin"] where FileManager.default.fileExists(atPath: path) {
            #expect(!policy.evaluate(URL(fileURLWithPath: path)).isAllowed, "\(path)")
        }
    }
}
