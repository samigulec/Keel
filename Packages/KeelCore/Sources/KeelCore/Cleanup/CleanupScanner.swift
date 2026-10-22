import Foundation

public struct CategoryScanResult: Sendable {
    public let category: CleanupCategory
    /// Largest first.
    public let items: [CleanupItem]
    public let skipped: [SkippedItem]
    /// Folders that exist but could not be read, so the result may be incomplete.
    public var unreadableRoots: [URL] = []

    public var totalBytes: Int64 { items.reduce(0) { $0 + $1.sizeBytes } }

    /// The same result without items that have since been cleaned.
    public func removing(_ cleaned: Set<CleanupItem>) -> CategoryScanResult {
        CategoryScanResult(
            category: category,
            items: items.filter { !cleaned.contains($0) },
            skipped: skipped,
            unreadableRoots: unreadableRoots
        )
    }
}

/// Finds what can be cleaned. Scanning only reads; nothing is changed on disk.
public struct CleanupScanner: Sendable {
    public let policy: SafetyPolicy
    public let rules: [CleanupRule]

    public init(policy: SafetyPolicy, rules: [CleanupRule]) {
        self.policy = policy
        self.rules = rules
    }

    public static func standard(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> CleanupScanner {
        CleanupScanner(policy: .standard(home: home), rules: CleanupCatalog.standard(home: home))
    }

    /// Scans every category in parallel; results keep the catalog's order.
    public func scan(context: ScanContext = ScanContext()) async throws -> [CategoryScanResult] {
        let results = try await withThrowingTaskGroup(of: CategoryScanResult.self) { group in
            for rule in rules {
                group.addTask { try scan(rule, context: context) }
            }
            var results: [CleanupCategoryID: CategoryScanResult] = [:]
            for try await result in group {
                results[result.category.id] = result
            }
            return results
        }
        return rules.compactMap { results[$0.category.id] }
    }

    func scan(_ rule: CleanupRule, context: ScanContext) throws -> CategoryScanResult {
        var items: [CleanupItem] = []
        var skipped: [SkippedItem] = []
        var seen = Set<String>()

        var unreadable: [URL] = []

        for source in rule.sources {
            unreadable += source.roots.filter(Self.existsButUnreadable)
            for candidate in source.candidates(in: context) {
                try Task.checkCancellation()
                guard seen.insert(candidate.url.standardizedFileURL.path).inserted else { continue }

                if let owner = candidate.owner, context.runningBundleIDs.contains(owner) {
                    skipped.append(SkippedItem(url: candidate.url, reason: .appRunning(bundleID: owner)))
                    continue
                }
                if case .denied(let reason) = policy.evaluate(candidate.url) {
                    skipped.append(SkippedItem(url: candidate.url, reason: .denied(reason)))
                    continue
                }

                let size = DirectorySizer.allocatedSize(of: candidate.url, isCancelled: { Task.isCancelled })
                guard size > 0 else { continue }
                items.append(CleanupItem(
                    url: candidate.url,
                    category: rule.category.id,
                    removal: rule.category.removal,
                    sizeBytes: size,
                    lastActivity: candidate.lastActivity
                ))
            }
        }

        return CategoryScanResult(
            category: rule.category,
            items: items.sorted { $0.sizeBytes > $1.sizeBytes },
            skipped: skipped,
            unreadableRoots: unreadable
        )
    }

    static func existsButUnreadable(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
            && (try? FileManager.default.contentsOfDirectory(atPath: url.path)) == nil
    }
}
