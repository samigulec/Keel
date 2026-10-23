import Foundation

/// What removing one app takes: its bundle and the related files the user
/// kept ticked. Everything goes to the Trash, so it can be put back.
public struct UninstallPlan: Sendable {
    public let app: InstalledApp
    /// false keeps the app and removes only its files, i.e. resets it.
    public let removesApp: Bool
    public let files: [RelatedFile]
    public let appSizeBytes: Int64

    public init(app: InstalledApp, removesApp: Bool, files: [RelatedFile], appSizeBytes: Int64) {
        self.app = app
        self.removesApp = removesApp
        self.files = files
        self.appSizeBytes = appSizeBytes
    }

    public var totalBytes: Int64 {
        (removesApp ? appSizeBytes : 0) + files.reduce(0) { $0 + $1.sizeBytes }
    }
}

public struct UninstallReport: Sendable {
    public struct Outcome: Sendable {
        public let url: URL
        public let message: String
    }

    public var removed: [URL] = []
    public var freedBytes: Int64 = 0
    public var skipped: [Outcome] = []
    public var failed: [Outcome] = []
    /// Apps whose bundle went to the Trash.
    public var removedApps: [InstalledApp] = []

    public init() {}
}

/// Checks every item right before it is removed. App bundles must be real
/// bundles in an install folder; related files must sit directly in one of
/// the ~/Library folders the finder searches.
public struct UninstallPolicy: Sendable {
    public enum Verdict: Equatable, Sendable {
        case allowed
        case denied(String)
    }

    public let appRoots: [String]
    public let fileRoots: [String]
    /// Keel itself, which must not remove its own bundle.
    public let ownBundle: String?
    let library: SafetyPolicy

    public init(appRoots: [URL], fileRoots: [URL], protectedRoots: [URL], ownBundle: URL?) {
        self.appRoots = appRoots.map(SafetyPolicy.canonicalPath)
        self.fileRoots = fileRoots.map(SafetyPolicy.canonicalPath)
        self.ownBundle = ownBundle.map(SafetyPolicy.canonicalPath)
        library = SafetyPolicy(allowedRoots: fileRoots, protectedRoots: protectedRoots)
    }

    public static func standard(
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        ownBundle: URL? = Bundle.main.bundleURL
    ) -> UninstallPolicy {
        UninstallPolicy(
            appRoots: AppInventory.standardRoots(home: home),
            fileRoots: AppLeftoverFinder.locations.map { home.appendingPathComponent($0.path, isDirectory: true) },
            protectedRoots: SafetyPolicy.standardProtectedRoots(home: home).filter { $0.path != "/Applications" },
            ownBundle: ownBundle
        )
    }

    public func evaluateApp(_ app: InstalledApp) -> Verdict {
        let url = app.url.standardizedFileURL
        if app.isSystem { return .denied("macOS'un parçası") }

        // Resource values describe the link itself, not what it points to.
        guard let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey]) else { return .denied("artık yok") }
        if values.isSymbolicLink == true { return .denied("bir kısayol") }
        guard url.pathExtension.lowercased() == "app",
              FileManager.default.fileExists(atPath: url.appendingPathComponent("Contents/Info.plist").path)
        else { return .denied("bir uygulama paketi değil") }

        let path = SafetyPolicy.canonicalPath(url)
        if let ownBundle, path == ownBundle { return .denied("Keel'in kendisi") }
        // The bundle sits in an install folder, or one folder below it, and is not that folder.
        let inRoot = appRoots.contains { root in
            let parent = (path as NSString).deletingLastPathComponent
            let grandparent = (parent as NSString).deletingLastPathComponent
            return parent == root || (grandparent == root && !parent.lowercased().hasSuffix(".app"))
        }
        guard inRoot else { return .denied("uygulama klasörlerinin dışında") }
        if SafetyPolicy.isInsideAppBundle((path as NSString).deletingLastPathComponent) {
            return .denied("başka bir uygulamanın içinde")
        }
        return .allowed
    }

    public func evaluateFile(_ file: RelatedFile) -> Verdict {
        if case .denied(let reason) = library.evaluate(file.url) { return .denied(reason.description) }
        // Only entries directly in a searched folder, never deeper.
        let parent = SafetyPolicy.canonicalPath(file.url.standardizedFileURL.deletingLastPathComponent())
        guard fileRoots.contains(parent) else { return .denied("arama klasörlerinin doğrudan içinde değil") }
        return .allowed
    }
}

public struct Uninstaller: Sendable {
    public let policy: UninstallPolicy
    public let remover: any FileRemover
    public let log: ActionLog?

    public init(policy: UninstallPolicy, remover: any FileRemover, log: ActionLog?) {
        self.policy = policy
        self.remover = remover
        self.log = log
    }

    /// Removes each plan's app and files. A running app is left alone, and
    /// so are its files, since it may be writing them.
    public func perform(_ plans: [UninstallPlan], runningBundleIDs: Set<String> = [], now: @Sendable () -> Date = Date.init) -> UninstallReport {
        var report = UninstallReport()
        let running = Set(runningBundleIDs.map { $0.lowercased() })

        for plan in plans {
            if let id = plan.app.bundleID?.lowercased(), running.contains(id) {
                report.skipped.append(.init(url: plan.app.url, message: "\(plan.app.name) açık"))
                continue
            }

            var targets: [(url: URL, bytes: Int64, verdict: UninstallPolicy.Verdict)] = plan.files.map {
                ($0.url, $0.sizeBytes, policy.evaluateFile($0))
            }
            if plan.removesApp {
                targets.insert((plan.app.url, plan.appSizeBytes, policy.evaluateApp(plan.app)), at: 0)
            }

            for target in targets {
                func record(_ outcome: ActionLog.Entry.Outcome, _ detail: String? = nil) {
                    try? log?.append(ActionLog.Entry(
                        date: now(), removal: .moveToTrash, path: target.url.path,
                        bytes: target.bytes, outcome: outcome, detail: detail
                    ))
                }
                if case .denied(let reason) = target.verdict {
                    report.skipped.append(.init(url: target.url, message: reason))
                    record(.skipped, reason)
                    continue
                }
                do {
                    try remover.moveToTrash(target.url)
                    report.removed.append(target.url)
                    report.freedBytes += target.bytes
                    record(.removed)
                    if target.url == plan.app.url { report.removedApps.append(plan.app) }
                } catch {
                    report.failed.append(.init(url: target.url, message: error.localizedDescription))
                    record(.failed, error.localizedDescription)
                }
            }
        }
        return report
    }
}
