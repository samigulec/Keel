import Foundation

/// Where in ~/Library an app keeps a file: the area ("Containers",
/// "Application Support") and the folder under it that names the owner
/// (a bundle ID such as "com.docker.docker", a group, or an app's name).
public struct AppDataLocation: Hashable, Sendable {
    public let area: String
    public let owner: String

    public init(area: String, owner: String) {
        self.area = area
        self.owner = owner
    }

    /// True when the folder belongs to one of these running apps, by bundle
    /// ID ("com.docker.docker", "UBF8T346G9.com.microsoft.teams") or name
    /// ("Steam"). Both sets are lowercased.
    public func belongs(toAnyOf bundleIDs: Set<String>, names: Set<String>) -> Bool {
        let owner = owner.lowercased()
        if names.contains(owner) || bundleIDs.contains(owner) { return true }
        return bundleIDs.contains { $0.count > 4 && (owner.hasSuffix("." + $0) || owner == "group." + $0) }
    }
}

/// A big file in the user's own folders or in an app's data.
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
    /// Set for files in an app's data in ~/Library; nil for the user's own files.
    public let appData: AppDataLocation?

    public init(url: URL, sizeBytes: Int64, lastActivity: Date?, kind: Kind, appData: AppDataLocation? = nil) {
        self.url = url
        self.sizeBytes = sizeBytes
        self.lastActivity = lastActivity
        self.kind = kind
        self.appData = appData
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

/// Finds large files in the home folder and, when asked, in the folders of
/// ~/Library where apps keep their data. It never looks inside the rest of
/// Library, Applications, the Trash, hidden folders or packages (Photos
/// libraries, app bundles), nor into Apple's own app data, and never lists
/// folders, only single files.
public struct LargeFileScanner: Sendable {
    public let home: URL
    public let minimumBytes: Int64
    public let includeAppData: Bool
    public let lastActivity: @Sendable (URL) -> Date?

    /// Top-level folders of the home that hold the system's and apps' data.
    static let skippedTopLevel: Set<String> = ["Library", "Applications", ".Trash"]

    /// The folders of ~/Library where apps keep data the user may remove.
    public static let appDataAreas = ["Application Support", "Containers", "Group Containers", "Caches", "Developer", "Logs"]

    /// Apple's own data in those areas: system databases, iPhone backups
    /// (one missing file breaks a whole backup), iCloud. Developer data
    /// (Xcode, simulators) stays in, as it is the user's to manage.
    static let appleDataFolders: Set<String> = [
        "MobileSync", "AddressBook", "CallHistoryDB", "CallHistoryTransactions", "Knowledge", "CloudDocs",
        "FileProvider", "Dock", "DifferentialPrivacy", "CrashReporter", "iCloud",
    ]

    /// Where `url` sits in an app's data, or nil when it is not in an area
    /// Keel scans or is Apple's own data. Links are resolved on both sides
    /// (on macOS /var is /private/var).
    public static func appDataLocation(of url: URL, home: URL) -> AppDataLocation? {
        let library = home.appendingPathComponent("Library", isDirectory: true).resolvingSymlinksInPath().pathComponents
        let parts = url.deletingLastPathComponent().resolvingSymlinksInPath().appendingPathComponent(url.lastPathComponent).pathComponents
        guard parts.count > library.count + 2, Array(parts.prefix(library.count)) == library else { return nil }
        return location(area: parts[library.count], owner: parts[library.count + 1])
    }

    /// The owner folder `owner` in `area`, unless Keel leaves it alone.
    static func location(area: String, owner: String) -> AppDataLocation? {
        guard appDataAreas.contains(area), !owner.hasPrefix(".") else { return nil }
        if area != "Developer" {
            let lowered = owner.lowercased()
            if lowered.hasPrefix("com.apple.") || lowered.hasPrefix("group.com.apple.") || appleDataFolders.contains(owner) {
                return nil
            }
        }
        return AppDataLocation(area: area, owner: owner)
    }

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
        includeAppData: Bool = false,
        lastActivity: @escaping @Sendable (URL) -> Date? = FileActivity.lastActivity(of:)
    ) {
        self.home = home
        self.minimumBytes = minimumBytes
        self.includeAppData = includeAppData
        self.lastActivity = lastActivity
    }

    public func scan(limit: Int = 500, isCancelled: () -> Bool = { false }) -> [LargeFile] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey]
        guard let topLevel = try? FileManager.default.contentsOfDirectory(
            at: home, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        ) else { return [] }
        // Each root with the app whose data it is, if any.
        var roots: [(url: URL, appData: AppDataLocation?)] = topLevel
            .filter { !Self.skippedTopLevel.contains($0.lastPathComponent) }
            .map { ($0, nil) }
        if includeAppData {
            // Each owner's folder on its own, so Apple's can be left out whole.
            for area in Self.appDataAreas {
                let folder = home.appendingPathComponent("Library/\(area)", isDirectory: true)
                let owners = (try? FileManager.default.contentsOfDirectory(
                    at: folder, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
                )) ?? []
                for owner in owners where (try? owner.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                    if let location = Self.location(area: area, owner: owner.lastPathComponent) {
                        roots.append((owner, location))
                    }
                }
            }
        }
        let protected = Set(SafetyPolicy.standardProtectedRoots(home: home).map(\.standardizedFileURL.path))

        var found: [(url: URL, size: Int64, appData: AppDataLocation?)] = []
        for (folder, appData) in roots {
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
                    if protected.contains(url.standardizedFileURL.path) {
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
                if size >= minimumBytes { found.append((url, size, appData)) }
            }
        }

        return found
            .sorted { $0.size > $1.size }
            .prefix(limit)
            .map {
                LargeFile(
                    url: $0.url, sizeBytes: $0.size, lastActivity: lastActivity($0.url), kind: LargeFile.kind(of: $0.url),
                    appData: $0.appData
                )
            }
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
/// a regular file, inside the home folder, outside the protected places.
/// In ~/Library only the app data the scanner lists qualifies, and never
/// while its app is open.
public struct LargeFileRemover: Sendable {
    public let home: URL
    public let policy: SafetyPolicy
    public let remover: any FileRemover
    public let log: ActionLog?

    public init(
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        policy: SafetyPolicy,
        remover: any FileRemover,
        log: ActionLog?
    ) {
        self.home = home
        self.policy = policy
        self.remover = remover
        self.log = log
    }

    public static func standard(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> LargeFileRemover {
        LargeFileRemover(home: home, policy: policy(home: home), remover: SystemFileRemover(), log: .standard(home: home))
    }

    public static func policy(home: URL) -> SafetyPolicy {
        SafetyPolicy(
            allowedRoots: [home],
            protectedRoots: SafetyPolicy.standardProtectedRoots(home: home)
                + ["Applications", ".Trash"].map { home.appendingPathComponent($0, isDirectory: true) }
        )
    }

    /// `runningBundleIDs` and `runningNames` (lowercased) name the apps that
    /// are open; their data is left alone.
    public func perform(
        _ files: [LargeFile],
        runningBundleIDs: Set<String> = [],
        runningNames: Set<String> = [],
        now: @Sendable () -> Date = Date.init
    ) -> LargeFilesReport {
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
            // Judge where it really is, with links in its folders resolved.
            let realHome = home.resolvingSymlinksInPath()
            let resolved = file.url.deletingLastPathComponent().resolvingSymlinksInPath()
                .appendingPathComponent(file.url.lastPathComponent)
            if resolved.path.hasPrefix(realHome.appendingPathComponent("Library").path + "/") {
                guard let location = LargeFileScanner.appDataLocation(of: resolved, home: realHome) else {
                    report.skipped.append(.init(url: file.url, message: "Library'nin korunan bir yerinde"))
                    record(.skipped, "protected part of Library")
                    continue
                }
                if location.belongs(toAnyOf: runningBundleIDs, names: runningNames) {
                    report.skipped.append(.init(url: file.url, message: "uygulaması açık; kapatıp tekrar dene"))
                    record(.skipped, "its app is running")
                    continue
                }
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
