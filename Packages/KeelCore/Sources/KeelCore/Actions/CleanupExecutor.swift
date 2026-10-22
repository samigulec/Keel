import Foundation

public struct CleanupReport: Sendable {
    public struct Failure: Sendable {
        public let item: CleanupItem
        public let message: String
    }

    public var removed: [CleanupItem] = []
    public var skipped: [SkippedItem] = []
    public var failed: [Failure] = []

    public var freedBytes: Int64 { removed.reduce(0) { $0 + $1.sizeBytes } }
}

/// Removes items the user confirmed. Every item is checked against the
/// safety policy again right before removal, because the disk may have
/// changed since the scan.
public struct CleanupExecutor: Sendable {
    public let policy: SafetyPolicy
    /// The only place where permanent deletion is allowed.
    public let trashDirectory: URL
    public let remover: any FileRemover
    public let log: ActionLog?

    public init(policy: SafetyPolicy, trashDirectory: URL, remover: any FileRemover, log: ActionLog?) {
        self.policy = policy
        self.trashDirectory = trashDirectory
        self.remover = remover
        self.log = log
    }

    public static func standard(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> CleanupExecutor {
        CleanupExecutor(
            policy: .standard(home: home),
            trashDirectory: home.appendingPathComponent(".Trash", isDirectory: true),
            remover: SystemFileRemover(),
            log: .standard(home: home)
        )
    }

    public func perform(_ items: [CleanupItem], now: @Sendable () -> Date = Date.init) -> CleanupReport {
        var report = CleanupReport()

        for item in items {
            func record(_ outcome: ActionLog.Entry.Outcome, _ detail: String? = nil) {
                try? log?.append(ActionLog.Entry(
                    date: now(),
                    removal: item.removal,
                    path: item.url.path,
                    bytes: item.sizeBytes,
                    outcome: outcome,
                    detail: detail
                ))
            }

            if case .denied(let reason) = policy.evaluate(item.url) {
                report.skipped.append(SkippedItem(url: item.url, reason: .denied(reason)))
                record(.skipped, reason.description)
                continue
            }
            if item.removal == .deletePermanently, !isInsideTrash(item.url) {
                report.skipped.append(SkippedItem(url: item.url, reason: .permanentDeletionNotAllowed))
                record(.skipped, "permanent deletion is only allowed inside the Trash")
                continue
            }

            do {
                switch item.removal {
                case .moveToTrash: try remover.moveToTrash(item.url)
                case .deletePermanently: try remover.deletePermanently(item.url)
                }
                report.removed.append(item)
                record(.removed)
            } catch {
                report.failed.append(.init(item: item, message: error.localizedDescription))
                record(.failed, error.localizedDescription)
            }
        }

        return report
    }

    private func isInsideTrash(_ url: URL) -> Bool {
        let trash = SafetyPolicy.canonicalPath(trashDirectory)
        let parent = SafetyPolicy.canonicalPath(url.standardizedFileURL.deletingLastPathComponent())
        let path = SafetyPolicy.join(parent, url.lastPathComponent)
        return path != trash && SafetyPolicy.isSameOrDescendant(path, of: trash)
    }
}
