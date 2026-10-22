import Foundation

public enum CleanupCategoryID: String, CaseIterable, Codable, Sendable {
    case userCaches
    case logs
    case browserCaches
    case developer
    case oldDownloads
    case trash
}

/// How an item leaves the disk. Everything goes to the Trash, except the
/// contents of the Trash itself, which can only be deleted for good.
public enum Removal: String, Codable, Sendable {
    case moveToTrash
    case deletePermanently
}

public struct CleanupCategory: Identifiable, Sendable {
    public let id: CleanupCategoryID
    public let title: String
    public let summary: String
    public let removal: Removal
    public let selectedByDefault: Bool

    public init(id: CleanupCategoryID, title: String, summary: String, removal: Removal, selectedByDefault: Bool) {
        self.id = id
        self.title = title
        self.summary = summary
        self.removal = removal
        self.selectedByDefault = selectedByDefault
    }
}

/// One thing the user can clean: a file or a whole folder.
public struct CleanupItem: Identifiable, Hashable, Sendable {
    public var id: String { url.path }
    public let url: URL
    public let category: CleanupCategoryID
    public let removal: Removal
    public let sizeBytes: Int64
    public let lastActivity: Date?

    public init(url: URL, category: CleanupCategoryID, removal: Removal, sizeBytes: Int64, lastActivity: Date? = nil) {
        self.url = url
        self.category = category
        self.removal = removal
        self.sizeBytes = sizeBytes
        self.lastActivity = lastActivity
    }
}

public struct SkippedItem: Hashable, Sendable {
    public enum Reason: Hashable, Sendable {
        /// The owning app is running; its files may be in use.
        case appRunning(bundleID: String)
        case denied(SafetyPolicy.DenialReason)
        case permanentDeletionNotAllowed
    }

    public let url: URL
    public let reason: Reason

    public init(url: URL, reason: Reason) {
        self.url = url
        self.reason = reason
    }
}
