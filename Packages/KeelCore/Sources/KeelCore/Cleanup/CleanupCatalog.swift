import Foundation

/// A cleanup category and where its candidates come from.
public struct CleanupRule: Sendable {
    public let category: CleanupCategory
    public let sources: [any CandidateSource]

    public init(category: CleanupCategory, sources: [any CandidateSource]) {
        self.category = category
        self.sources = sources
    }
}

public enum CleanupCatalog {
    static let day: TimeInterval = 24 * 60 * 60

    /// Browser caches: (path under ~/Library/Caches, owning app's bundle ID).
    static let browserCaches: [(path: String, bundleID: String)] = [
        ("Google/Chrome", "com.google.Chrome"),
        ("com.google.Chrome", "com.google.Chrome"),
        ("Microsoft Edge", "com.microsoft.edgemac"),
        ("com.microsoft.edgemac", "com.microsoft.edgemac"),
        ("BraveSoftware/Brave-Browser", "com.brave.Browser"),
        ("Firefox/Profiles", "org.mozilla.firefox"),
        ("com.operasoftware.Opera", "com.operasoftware.Opera"),
        ("company.thebrowser.Browser", "company.thebrowser.Browser"),
    ]

    /// Top-level cache folders the generic cache rule leaves alone: browsers
    /// have their own category, and Keel never cleans its own cache.
    static let cacheFoldersHandledElsewhere: Set<String> = [
        "Google", "com.google.Chrome",
        "Microsoft Edge", "com.microsoft.edgemac",
        "BraveSoftware", "Firefox",
        "com.operasoftware.Opera", "company.thebrowser.Browser",
        "com.samigulec.Keel",
    ]

    /// Caches of macOS services whose folders lack the `com.apple.` prefix.
    /// Like other Apple caches, they are left to macOS.
    static let appleServiceCaches: Set<String> = [
        "GeoServices", "PassKit", "Animoji", "askpermissiond",
        "CloudKit", "FamilyCircle", "familycircled", "GameKit", "AudioUnitCache",
    ]

    /// Not caches despite living in ~/Library/Caches: browser installs used by
    /// test tools. Removing them breaks the tool until it is reinstalled.
    static let toolInstallations: Set<String> = [
        "ms-playwright", "ms-playwright-go", "Cypress",
    ]

    /// Package manager and build tool caches. Safe to remove, but the next
    /// install or build downloads everything again, so they are opt-in.
    static let developerToolCaches: [String] = [
        "Homebrew", "pip", "pypoetry", "composer", "node-gyp", "typescript",
        "bun", "Yarn", "yarn", "pnpm", "go-build", "org.swift.swiftpm",
        "CocoaPods", "deno",
    ]

    public static func standard(home: URL) -> [CleanupRule] {
        let library = home.appendingPathComponent("Library", isDirectory: true)
        let caches = library.appendingPathComponent("Caches", isDirectory: true)
        let developer = library.appendingPathComponent("Developer", isDirectory: true)

        return [
            CleanupRule(
                category: CleanupCategory(
                    id: .userCaches,
                    title: "Uygulama önbellekleri",
                    summary: "Uygulamaların geçici dosyaları; gerektiğinde yeniden oluşturulur",
                    removal: .moveToTrash,
                    selectedByDefault: true
                ),
                sources: [
                    ChildrenSource(
                        root: caches,
                        ownership: .bundleIDFromName,
                        excludedNames: cacheFoldersHandledElsewhere
                            .union(appleServiceCaches)
                            .union(toolInstallations)
                            .union(developerToolCaches),
                        // Apple's own caches are left to macOS in Phase 1.
                        excludedPrefixes: ["com.apple."]
                    ),
                ]
            ),
            CleanupRule(
                category: CleanupCategory(
                    id: .logs,
                    title: "Günlük dosyaları",
                    summary: "7 günden eski uygulama kayıtları",
                    removal: .moveToTrash,
                    selectedByDefault: true
                ),
                sources: [
                    AgedFilesSource(root: library.appendingPathComponent("Logs", isDirectory: true), minimumAge: 7 * day),
                ]
            ),
            CleanupRule(
                category: CleanupCategory(
                    id: .browserCaches,
                    title: "Tarayıcı önbellekleri",
                    summary: "Chrome, Edge, Brave, Firefox, Opera ve Arc önbellekleri",
                    removal: .moveToTrash,
                    selectedByDefault: true
                ),
                sources: [
                    FixedPathsSource(browserCaches.map {
                        .init(url: caches.appendingPathComponent($0.path, isDirectory: true), owner: $0.bundleID)
                    }),
                ]
            ),
            CleanupRule(
                category: CleanupCategory(
                    id: .developer,
                    title: "Geliştirici önbellekleri",
                    summary: "Xcode, Homebrew, npm, pip ve benzerleri; sonraki derlemede yeniden indirilir",
                    removal: .moveToTrash,
                    selectedByDefault: false
                ),
                sources: [
                    FixedPathsSource(developerToolCaches.map {
                        .init(url: caches.appendingPathComponent($0, isDirectory: true), owner: nil)
                    }),
                    ChildrenSource(
                        root: developer.appendingPathComponent("Xcode/DerivedData", isDirectory: true),
                        ownership: .fixed("com.apple.dt.Xcode")
                    ),
                    ChildrenSource(
                        root: developer.appendingPathComponent("CoreSimulator/Caches", isDirectory: true),
                        ownership: .fixed("com.apple.iphonesimulator")
                    ),
                ]
            ),
            CleanupRule(
                category: CleanupCategory(
                    id: .oldDownloads,
                    title: "Eski indirmeler",
                    summary: "90 günden uzun süredir açılmamış indirmeler",
                    removal: .moveToTrash,
                    selectedByDefault: false
                ),
                sources: [
                    ChildrenSource(root: home.appendingPathComponent("Downloads", isDirectory: true), minimumAge: 90 * day),
                ]
            ),
            CleanupRule(
                category: CleanupCategory(
                    id: .trash,
                    title: "Çöp Kutusu",
                    summary: "Çöp Kutusu'ndaki dosyalar kalıcı olarak silinir",
                    removal: .deletePermanently,
                    selectedByDefault: false
                ),
                sources: [
                    ChildrenSource(root: home.appendingPathComponent(".Trash", isDirectory: true)),
                ]
            ),
        ]
    }
}
