import Foundation

/// A big file in the user's own folders.
public struct LargeFile: Identifiable, Hashable, Sendable {
    public enum Kind: String, CaseIterable, Sendable {
        case video, archive, diskImage, installer, audio, image, document, other
    }

    public var id: String { url.path }
    public let url: URL
    public let sizeBytes: Int64
    /// When it was last opened or changed, as best macOS can tell.
    public let lastActivity: Date?
    public let kind: Kind

    public init(url: URL, sizeBytes: Int64, lastActivity: Date?, kind: Kind) {
        self.url = url
        self.sizeBytes = sizeBytes
        self.lastActivity = lastActivity
        self.kind = kind
    }

    static func kind(of url: URL) -> Kind {
        switch url.pathExtension.lowercased() {
        case "mp4", "mov", "m4v", "mkv", "avi", "webm", "mts", "wmv": .video
        case "zip", "rar", "7z", "tar", "gz", "tgz", "bz2", "xz", "zst": .archive
        case "dmg", "iso", "img", "sparseimage", "vmdk", "qcow2", "vdi": .diskImage
        case "pkg", "mpkg", "xip", "ipa", "exe", "msi": .installer
        case "mp3", "m4a", "wav", "aiff", "aif", "flac", "aac", "caf": .audio
        case "jpg", "jpeg", "png", "heic", "tif", "tiff", "raw", "cr2", "cr3", "nef", "arw", "dng", "psd", "gif": .image
        case "pdf", "key", "pages", "numbers", "docx", "pptx", "xlsx", "doc", "ppt", "xls", "epub": .document
        default: .other
        }
    }
}

/// Finds large files in the home folder. It never looks inside Library,
/// Applications, the Trash, hidden folders or packages (Photos libraries,
/// app bundles), and never lists folders, only single files.
public struct LargeFileScanner: Sendable {
    public let home: URL
    public let minimumBytes: Int64
    public let lastActivity: @Sendable (URL) -> Date?

    /// Top-level folders of the home that hold the system's and apps' data.
    static let skippedTopLevel: Set<String> = ["Library", "Applications", ".Trash"]

    /// Folders that are one document to the user (apps, Photos and Music
    /// libraries, projects); never looked into, even where macOS does not
    /// mark them as packages.
    static let packageExtensions: Set<String> = [
        "app", "photoslibrary", "musiclibrary", "tvlibrary", "imovielibrary", "fcpbundle", "logicx", "band",
        "bundle", "framework", "plugin", "xcarchive", "sparsebundle", "photolibrary", "aplibrary", "lrdata",
    ]

    public init(
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        minimumBytes: Int64 = 50_000_000,
        lastActivity: @escaping @Sendable (URL) -> Date? = FileActivity.lastActivity(of:)
    ) {
        self.home = home
        self.minimumBytes = minimumBytes
        self.lastActivity = lastActivity
    }

    public func scan(limit: Int = 500, isCancelled: () -> Bool = { false }) -> [LargeFile] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey]
        guard let topLevel = try? FileManager.default.contentsOfDirectory(
            at: home, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        ) else { return [] }

        var found: [(url: URL, size: Int64)] = []
        for folder in topLevel where !Self.skippedTopLevel.contains(folder.lastPathComponent) {
            if isCancelled() { break }
            if Self.packageExtensions.contains(folder.pathExtension.lowercased()) { continue }
            var candidates: [URL] = []
            if (try? folder.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                guard let enumerator = FileManager.default.enumerator(
                    at: folder,
                    includingPropertiesForKeys: keys + [.isDirectoryKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants],
                    errorHandler: { _, _ in true }
                ) else { continue }
                while let url = enumerator.nextObject() as? URL {
                    if isCancelled() { break }
                    if Self.packageExtensions.contains(url.pathExtension.lowercased()),
                       (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                        enumerator.skipDescendants()
                        continue
                    }
                    candidates.append(url)
                }
            } else {
                candidates = [folder]
            }
            for url in candidates {
                if isCancelled() { break }
                guard let values = try? url.resourceValues(forKeys: Set(keys)),
                      values.isRegularFile == true, values.isSymbolicLink != true else { continue }
                let size = Self.size(values)
                if size >= minimumBytes { found.append((url, size)) }
            }
        }

        return found
            .sorted { $0.size > $1.size }
            .prefix(limit)
            .map { LargeFile(url: $0.url, sizeBytes: $0.size, lastActivity: lastActivity($0.url), kind: LargeFile.kind(of: $0.url)) }
    }

    private static func size(_ values: URLResourceValues) -> Int64 {
        #if os(macOS)
        // Allocated size: files iCloud keeps only online take no space and drop out.
        Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        #else
        Int64(values.fileSize ?? 0)
        #endif
    }
}

public struct LargeFilesReport: Sendable {
    public struct Outcome: Sendable {
        public let url: URL
        public let message: String
    }

    public var removed: [LargeFile] = []
    public var skipped: [Outcome] = []
    public var failed: [Outcome] = []
    public var trashed: [TrashedItem] = []

    public init() {}

    public var freedBytes: Int64 { removed.reduce(0) { $0 + $1.sizeBytes } }
}

/// Moves chosen large files to the Trash after checking each one again:
/// a regular file, inside the home folder, outside Library and the other
/// protected places.
public struct LargeFileRemover: Sendable {
    public let policy: SafetyPolicy
    public let remover: any FileRemover
    public let log: ActionLog?

    public init(policy: SafetyPolicy, remover: any FileRemover, log: ActionLog?) {
        self.policy = policy
        self.remover = remover
        self.log = log
    }

    public static func standard(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> LargeFileRemover {
        LargeFileRemover(policy: policy(home: home), remover: SystemFileRemover(), log: .standard(home: home))
    }

    public static func policy(home: URL) -> SafetyPolicy {
        SafetyPolicy(
            allowedRoots: [home],
            protectedRoots: SafetyPolicy.standardProtectedRoots(home: home)
                + LargeFileScanner.skippedTopLevel.map { home.appendingPathComponent($0, isDirectory: true) }
        )
    }

    public func perform(_ files: [LargeFile], now: @Sendable () -> Date = Date.init) -> LargeFilesReport {
        var report = LargeFilesReport()
        for file in files {
            func record(_ outcome: ActionLog.Entry.Outcome, _ detail: String? = nil) {
                try? log?.append(ActionLog.Entry(
                    date: now(), removal: .moveToTrash, path: file.url.path,
                    bytes: file.sizeBytes, outcome: outcome, detail: detail
                ))
            }
            if case .denied(let reason) = policy.evaluate(file.url) {
                report.skipped.append(.init(url: file.url, message: reason.description))
                record(.skipped, reason.description)
                continue
            }
            let values = try? file.url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            guard values?.isRegularFile == true, values?.isSymbolicLink != true else {
                report.skipped.append(.init(url: file.url, message: "artık bir dosya değil"))
                record(.skipped, "not a regular file")
                continue
            }
            do {
                if let landed = try remover.moveToTrash(file.url) {
                    report.trashed.append(TrashedItem(original: file.url, inTrash: landed, bytes: file.sizeBytes))
                }
                report.removed.append(file)
                record(.removed)
            } catch {
                report.failed.append(.init(url: file.url, message: error.localizedDescription))
                record(.failed, error.localizedDescription)
            }
        }
        return report
    }
}
