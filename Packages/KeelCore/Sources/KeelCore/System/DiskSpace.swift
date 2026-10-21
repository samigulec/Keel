import Foundation

/// Capacity of the volume that holds a given path.
public struct DiskSpace: Equatable, Sendable {
    public let totalBytes: Int64
    public let availableBytes: Int64

    public init(totalBytes: Int64, availableBytes: Int64) {
        self.totalBytes = totalBytes
        self.availableBytes = availableBytes
    }

    public var usedBytes: Int64 { max(totalBytes - availableBytes, 0) }

    public var usedFraction: Double {
        totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0
    }

    public static func current(for url: URL = URL(fileURLWithPath: "/")) throws -> DiskSpace {
        #if os(macOS)
        // "Important usage" counts purgeable space as available, matching Finder.
        let values = try url.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
        ])
        return DiskSpace(
            totalBytes: Int64(values.volumeTotalCapacity ?? 0),
            availableBytes: values.volumeAvailableCapacityForImportantUsage ?? 0
        )
        #else
        let attributes = try FileManager.default.attributesOfFileSystem(forPath: url.path)
        return DiskSpace(
            totalBytes: (attributes[.systemSize] as? NSNumber)?.int64Value ?? 0,
            availableBytes: (attributes[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        )
        #endif
    }
}
