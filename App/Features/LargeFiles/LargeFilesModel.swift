import AppKit
import KeelCore
import Observation

/// Large and old files in the home folder and in apps' data, and moving
/// them to the Trash.
@MainActor
@Observable
final class LargeFilesModel {
    enum Phase: Equatable {
        case idle, scanning, ready, removing
    }

    enum Age: String, CaseIterable, Identifiable {
        case any, sixMonths, oneYear, twoYears
        var id: String { rawValue }

        var title: String {
            switch self {
            case .any: "Her zaman"
            case .sixMonths: "6 aydan eski"
            case .oneYear: "1 yıldan eski"
            case .twoYears: "2 yıldan eski"
            }
        }

        var seconds: TimeInterval? {
            switch self {
            case .any: nil
            case .sixMonths: 182 * 86_400
            case .oneYear: 365 * 86_400
            case .twoYears: 730 * 86_400
            }
        }
    }

    /// The user's own files, apps' data in ~/Library, or both.
    enum Place: String, CaseIterable, Identifiable {
        case all, personal, appData
        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: "Her yer"
            case .personal: "Kişisel dosyalar"
            case .appData: "Uygulama verileri"
            }
        }
    }

    enum MinimumSize: Int64, CaseIterable, Identifiable {
        case fifty = 50_000_000
        case hundred = 100_000_000
        case fiveHundred = 500_000_000
        case gigabyte = 1_000_000_000
        var id: Int64 { rawValue }
        var title: String { ByteFormat.string(rawValue) + "+" }
    }

    private(set) var phase: Phase = .idle
    private(set) var files: [LargeFile] = []
    private(set) var lastScan: Date?
    private(set) var lastReport: LargeFilesReport?
    private(set) var lastRestore: RestoreReport?

    var kind: LargeFile.Kind?
    var place: Place = .all
    var age: Age = .any
    var minimumSize: MinimumSize = .hundred
    var selection: Set<String> = []

    private let status: SystemStatus
    @ObservationIgnored private var icons: [String: NSImage] = [:]
    @ObservationIgnored private var ownerNames: [String: String] = [:]
    @ObservationIgnored private var scanTask: Task<Void, Never>?

    init(status: SystemStatus) {
        self.status = status
    }

    // MARK: Scanning

    func scan() {
        guard phase != .scanning, phase != .removing else { return }
        phase = .scanning
        lastReport = nil
        lastRestore = nil
        scanTask = Task {
            // Scan once at the smallest size; the size filter then works instantly.
            let found = await Task.detached(priority: .userInitiated) {
                LargeFileScanner(minimumBytes: MinimumSize.fifty.rawValue, includeAppData: true).scan()
            }.value
            files = found
            selection = selection.filter { id in found.contains { $0.id == id } }
            lastScan = Date()
            phase = .ready
        }
    }

    /// Waits for a scan, starting one if there is none yet.
    func filesWhenReady() async -> [LargeFile] {
        if phase == .idle { scan() }
        await scanTask?.value
        return files
    }

    // MARK: Listing

    var visibleFiles: [LargeFile] {
        files.filter { file in
            file.sizeBytes >= minimumSize.rawValue
                && (kind == nil || file.kind == kind)
                && isIn(file, place)
                && isOlder(file, than: age)
        }
    }

    func isIn(_ file: LargeFile, _ place: Place) -> Bool {
        switch place {
        case .all: true
        case .personal: file.appData == nil
        case .appData: file.appData != nil
        }
    }

    func isOlder(_ file: LargeFile, than age: Age) -> Bool {
        guard let seconds = age.seconds else { return true }
        guard let date = file.lastActivity else { return false }
        return Date().timeIntervalSince(date) > seconds
    }

    func count(_ kind: LargeFile.Kind?) -> Int {
        files.filter { $0.sizeBytes >= minimumSize.rawValue && (kind == nil || $0.kind == kind) && isIn($0, place) && isOlder($0, than: age) }.count
    }

    var totalBytes: Int64 { files.reduce(0) { $0 + $1.sizeBytes } }
    var appDataBytes: Int64 { files.filter { $0.appData != nil }.reduce(0) { $0 + $1.sizeBytes } }
    var appDataCount: Int { files.filter { $0.appData != nil }.count }
    var oldBytes: Int64 { files.filter { isOlder($0, than: .oneYear) }.reduce(0) { $0 + $1.sizeBytes } }
    var downloadsBytes: Int64 {
        let downloads = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").path + "/"
        return files.filter { $0.url.path.hasPrefix(downloads) }.reduce(0) { $0 + $1.sizeBytes }
    }
    var selectedFiles: [LargeFile] { files.filter { selection.contains($0.id) } }
    var selectedBytes: Int64 { selectedFiles.reduce(0) { $0 + $1.sizeBytes } }
    var selectionHasAppData: Bool { selectedFiles.contains { $0.appData != nil } }

    /// The app a data folder belongs to, e.g. "com.docker.docker" -> "Docker".
    func ownerName(_ location: AppDataLocation) -> String {
        if let name = ownerNames[location.owner] { return name }
        var id = location.owner
        if id.hasPrefix("group.") { id.removeFirst(6) }
        // Group containers may start with the developer's team ID: "UBF8T346G9.com.microsoft.teams".
        if let dot = id.firstIndex(of: "."), id.distance(from: id.startIndex, to: dot) == 10,
           id[..<dot].allSatisfy({ $0.isUppercase || $0.isNumber }) {
            id = String(id[id.index(after: dot)...])
        }
        var name = location.owner
        if id.contains("."), let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
            name = app.deletingPathExtension().lastPathComponent
        } else if location.area == "Developer" {
            name = location.owner == "CoreSimulator" ? "iOS Simülatörü" : location.owner
        }
        ownerNames[location.owner] = name
        return name
    }

    func icon(for file: LargeFile) -> NSImage {
        if let icon = icons[file.id] { return icon }
        let icon = NSWorkspace.shared.icon(forFile: file.url.path)
        icons[file.id] = icon
        return icon
    }

    // MARK: Removing

    func removeSelected() async {
        let chosen = selectedFiles
        guard phase == .ready, !chosen.isEmpty else { return }
        phase = .removing
        // An open app's data is left alone; the report says so.
        let running = NSWorkspace.shared.runningApplications
        let bundleIDs = Set(running.compactMap { $0.bundleIdentifier?.lowercased() })
        let names = Set(running.compactMap { $0.localizedName?.lowercased() })
        let report = await Task.detached(priority: .userInitiated) {
            LargeFileRemover.standard().perform(chosen, runningBundleIDs: bundleIDs, runningNames: names)
        }.value
        let removed = Set(report.removed.map(\.id))
        files.removeAll { removed.contains($0.id) }
        selection.subtract(removed)
        lastReport = report
        lastRestore = nil
        phase = .ready
        status.refresh()
    }

    func undoLastRemoval() async {
        guard phase == .ready, let trashed = lastReport?.trashed, !trashed.isEmpty else { return }
        let report = await Undo.restore(trashed)
        scan()
        lastRestore = report
    }

    func reveal(_ file: LargeFile) {
        NSWorkspace.shared.activateFileViewerSelecting([file.url])
    }

    /// Opens the file in its app, e.g. to check a video before removing it.
    func open(_ file: LargeFile) {
        NSWorkspace.shared.open(file.url)
    }
}
