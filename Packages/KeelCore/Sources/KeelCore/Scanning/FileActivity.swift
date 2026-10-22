import Foundation

#if os(macOS)
import CoreServices
#endif

/// When a file was last touched by the user, as best macOS can tell.
public enum FileActivity {
    /// The latest of: last modified, added to its folder, and Spotlight's
    /// "last opened" date. Access time is ignored because it is unreliable.
    @Sendable
    public static func lastActivity(of url: URL) -> Date? {
        var dates: [Date] = []

        #if os(macOS)
        let keys: Set<URLResourceKey> = [.contentModificationDateKey, .addedToDirectoryDateKey]
        #else
        let keys: Set<URLResourceKey> = [.contentModificationDateKey]
        #endif

        if let values = try? url.resourceValues(forKeys: keys) {
            if let modified = values.contentModificationDate { dates.append(modified) }
            #if os(macOS)
            if let added = values.addedToDirectoryDate { dates.append(added) }
            #endif
        }

        #if os(macOS)
        if let item = MDItemCreateWithURL(kCFAllocatorDefault, url as CFURL),
           let lastUsed = MDItemCopyAttribute(item, kMDItemLastUsedDate) as? Date {
            dates.append(lastUsed)
        }
        #endif

        return dates.max()
    }

    @Sendable
    public static func modificationDate(of url: URL) -> Date? {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }
}
