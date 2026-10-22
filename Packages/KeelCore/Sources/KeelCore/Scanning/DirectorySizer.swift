import Foundation

/// Measures how much disk space an item takes, the way Finder's "on disk" size does.
public enum DirectorySizer {
    private static let keys: Set<URLResourceKey> = [
        .isRegularFileKey,
        .isDirectoryKey,
        .isSymbolicLinkKey,
        .totalFileAllocatedSizeKey,
        .fileAllocatedSizeKey,
        .fileSizeKey,
    ]

    /// Total allocated size of a file or a directory tree. Symbolic links are
    /// never followed, so a link pointing elsewhere counts as zero.
    public static func allocatedSize(of url: URL, isCancelled: () -> Bool = { false }) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: keys) else { return 0 }
        if values.isSymbolicLink == true { return 0 }
        guard values.isDirectory == true else { return fileSize(values) }

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [],
            errorHandler: { _, _ in true } // skip unreadable folders, keep counting
        ) else { return 0 }

        var total: Int64 = 0
        for case let child as URL in enumerator {
            if isCancelled() { break }
            guard let childValues = try? child.resourceValues(forKeys: keys),
                  childValues.isRegularFile == true else { continue }
            total += fileSize(childValues)
        }
        return total
    }

    private static func fileSize(_ values: URLResourceValues) -> Int64 {
        #if os(macOS)
        Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? values.fileSize ?? 0)
        #else
        // swift-corelibs-foundation multiplies st_blocks by the block size
        // instead of 512, inflating allocated sizes; use the logical size.
        Int64(values.fileSize ?? 0)
        #endif
    }
}
