import AppKit
import CoreServices
import KeelCore
import Observation

/// One installed app with what Keel measured about it.
struct AppEntry: Identifiable {
    let app: InstalledApp
    /// The bundle's size on disk; measured after the list appears.
    var sizeBytes: Int64?
    /// When Spotlight last saw the app opened.
    var lastUsed: Date?

    var id: String { app.id }
}

/// The installed apps, their related files and removing them.
@MainActor
@Observable
final class ApplicationsModel {
    enum Phase: Equatable {
        case idle
        case scanning
        case ready
        case removing
    }

    enum Filter: String, CaseIterable, Identifiable {
        case all, unused, large, intel, appStore, other
        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: "Tümü"
            case .unused: "Kullanılmayan"
            case .large: "Büyük"
            case .intel: "Intel"
            case .appStore: "App Store"
            case .other: "Diğer kaynaklar"
            }
        }
    }

    enum Sort: String, CaseIterable, Identifiable {
        case size, name, lastUsed
        var id: String { rawValue }

        var title: String {
            switch self {
            case .size: "Boyut"
            case .name: "Ad"
            case .lastUsed: "Son kullanım"
            }
        }
    }

    /// Not opened for this long counts as unused, like CleanMyMac's suggestion.
    static let unusedAfter: TimeInterval = 90 * 86_400
    static let largeBytes: Int64 = 1_000_000_000

    private(set) var phase: Phase = .idle
    private(set) var apps: [AppEntry] = []
    private(set) var runningBundleIDs: Set<String> = []
    private(set) var lastReport: UninstallReport?
    /// What the last undo put back.
    private(set) var lastRestore: RestoreReport?
    /// Related files per app id, found when the app is first looked at.
    private(set) var related: [String: [RelatedFile]] = [:]
    private(set) var loadingRelated: Set<String> = []

    var filter: Filter = .all
    var sort: Sort = .size
    var search = ""
    /// Apps ticked for removal.
    var selection: Set<String> = []
    /// The app shown in the detail panel.
    var focusedID: String?
    /// Related files the user unticked, by path.
    var keptFiles: Set<String> = []

    private let status: SystemStatus
    @ObservationIgnored private var icons: [String: NSImage] = [:]
    @ObservationIgnored private var sizeTask: Task<Void, Never>?
    @ObservationIgnored private var listTask: Task<Void, Never>?

    init(status: SystemStatus) {
        self.status = status
    }

    // MARK: Scanning

    func scan() {
        guard phase != .scanning, phase != .removing else { return }
        phase = .scanning
        sizeTask?.cancel()
        refreshRunning()

        listTask = Task {
            let found = await Task.detached(priority: .userInitiated) {
                AppInventory.scan(roots: AppInventory.standardRoots())
                    .map { AppEntry(app: $0, sizeBytes: nil, lastUsed: AppUsage.lastUsed($0.url)) }
            }.value
            apps = found
            related = [:]
            selection = selection.filter { id in found.contains { $0.id == id } }
            if focusedID == nil || !found.contains(where: { $0.id == focusedID }) {
                focusedID = nil
            }
            phase = .ready
            measureSizes()
        }
    }

    /// Waits for the app list, scanning first if nothing was scanned yet.
    /// Sizes may still be measuring when it returns.
    func listWhenReady() async -> [AppEntry] {
        if phase == .idle { scan() }
        await listTask?.value
        return apps
    }

    /// Bundle sizes, a few at a time, filled in as they finish.
    private func measureSizes() {
        let pending = apps.filter { $0.sizeBytes == nil }.map(\.app.url)
        sizeTask = Task {
            await withTaskGroup(of: (String, Int64).self) { group in
                var queue = pending[...]
                for _ in 0..<4 {
                    guard let url = queue.popFirst() else { break }
                    group.addTask(priority: .utility) { (url.path, DirectorySizer.allocatedSize(of: url)) }
                }
                for await (id, size) in group {
                    if Task.isCancelled { break }
                    if let index = apps.firstIndex(where: { $0.id == id }) { apps[index].sizeBytes = size }
                    if let url = queue.popFirst() {
                        group.addTask(priority: .utility) { (url.path, DirectorySizer.allocatedSize(of: url)) }
                    }
                }
            }
        }
    }

    func refreshRunning() {
        runningBundleIDs = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier?.lowercased() })
    }

    func isRunning(_ app: InstalledApp) -> Bool {
        app.bundleID.map { runningBundleIDs.contains($0.lowercased()) } ?? false
    }

    // MARK: Listing

    var visibleApps: [AppEntry] {
        let query = search.trimmingCharacters(in: .whitespaces).lowercased()
        let filtered = apps.filter { entry in
            guard matches(entry, filter) else { return false }
            guard !query.isEmpty else { return true }
            return entry.app.name.lowercased().contains(query) || (entry.app.bundleID?.lowercased().contains(query) ?? false)
        }
        return filtered.sorted { a, b in
            switch sort {
            case .size: (a.sizeBytes ?? -1) > (b.sizeBytes ?? -1)
            case .name: a.app.name.localizedStandardCompare(b.app.name) == .orderedAscending
            case .lastUsed: (a.lastUsed ?? .distantPast) < (b.lastUsed ?? .distantPast)
            }
        }
    }

    func matches(_ entry: AppEntry, _ filter: Filter) -> Bool {
        switch filter {
        case .all: true
        case .unused: isUnused(entry)
        case .large: (entry.sizeBytes ?? 0) >= Self.largeBytes
        case .intel: entry.app.architecture == .intel
        case .appStore: entry.app.source == .appStore
        case .other: entry.app.source == .other
        }
    }

    func count(_ filter: Filter) -> Int {
        apps.filter { matches($0, filter) }.count
    }

    func isUnused(_ entry: AppEntry) -> Bool {
        guard let lastUsed = entry.lastUsed else { return false }
        return Date().timeIntervalSince(lastUsed) > Self.unusedAfter
    }

    var totalBytes: Int64 { apps.reduce(0) { $0 + ($1.sizeBytes ?? 0) } }
    var isMeasuring: Bool { apps.contains { $0.sizeBytes == nil } }

    var focused: AppEntry? {
        focusedID.flatMap { id in apps.first { $0.id == id } }
    }

    func icon(for app: InstalledApp) -> NSImage {
        if let icon = icons[app.id] { return icon }
        let icon = NSWorkspace.shared.icon(forFile: app.url.path)
        icons[app.id] = icon
        return icon
    }

    // MARK: Related files

    func loadRelated(for entry: AppEntry) async {
        guard related[entry.id] == nil, !loadingRelated.contains(entry.id) else { return }
        loadingRelated.insert(entry.id)
        let app = entry.app
        let bundleIDs = Set(apps.compactMap(\.app.bundleID))
        let files = await Task.detached(priority: .userInitiated) {
            AppLeftoverFinder(installedBundleIDs: bundleIDs).relatedFiles(for: app)
        }.value
        related[entry.id] = files.sorted { $0.sizeBytes > $1.sizeBytes }
        loadingRelated.remove(entry.id)
    }

    func relatedBytes(for entry: AppEntry, ticked: Bool = true) -> Int64? {
        related[entry.id].map { files in
            files.filter { !ticked || !keptFiles.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
        }
    }

    // MARK: Removing

    /// Plans for the given apps; related files are found first where needed.
    func plans(for ids: [String], removingApps: Bool) async -> [UninstallPlan] {
        var plans: [UninstallPlan] = []
        for id in ids {
            guard let entry = apps.first(where: { $0.id == id }) else { continue }
            await loadRelated(for: entry)
            let files = (related[id] ?? []).filter { !keptFiles.contains($0.id) }
            plans.append(UninstallPlan(app: entry.app, removesApp: removingApps, files: files, appSizeBytes: entry.sizeBytes ?? 0))
        }
        return plans
    }

    func perform(_ plans: [UninstallPlan]) async {
        guard phase == .ready, !plans.isEmpty else { return }
        phase = .removing
        refreshRunning()
        let running = runningBundleIDs
        let report = await Task.detached(priority: .userInitiated) {
            Uninstaller(policy: .standard(), remover: AppRemover(), log: .standard())
                .perform(plans, runningBundleIDs: running)
        }.value
        lastReport = report

        let removedApps = Set(report.removedApps.map(\.id))
        let removedFiles = Set(report.removed.map(\.path))
        apps.removeAll { removedApps.contains($0.id) }
        selection.subtract(removedApps)
        for (id, files) in related {
            related[id] = files.filter { !removedFiles.contains($0.id) }
        }
        if let focusedID, removedApps.contains(focusedID) { self.focusedID = nil }
        phase = .ready
        status.refresh()
    }

    /// Puts the last removal's app and files back and lists the apps again.
    func undoLastRemoval() async {
        guard phase == .ready, let trashed = lastReport?.trashed, !trashed.isEmpty else { return }
        let report = await Undo.restore(trashed)
        lastReport = nil
        lastRestore = report
        scan()
    }

    func dismissReport() {
        lastReport = nil
        lastRestore = nil
    }

    /// Asks the app to quit, as if the user chose Quit from its menu.
    func quit(_ app: InstalledApp) {
        guard let bundleID = app.bundleID else { return }
        for running in NSRunningApplication.runningApplications(withBundleIdentifier: bundleID) {
            running.terminate()
        }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            refreshRunning()
        }
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

/// When Spotlight last saw an app opened.
enum AppUsage {
    nonisolated static func lastUsed(_ url: URL) -> Date? {
        guard let item = MDItemCreateWithURL(kCFAllocatorDefault, url as CFURL) else { return nil }
        return MDItemCopyAttribute(item, kMDItemLastUsedDate) as? Date
    }
}

/// Moves to the Trash like Finder. Apps installed by a package belong to the
/// system; for those, Finder's own route asks for an administrator password.
struct AppRemover: FileRemover {
    @discardableResult
    func moveToTrash(_ url: URL) throws -> URL? {
        do {
            var landed: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &landed)
            return landed as URL?
        } catch _ where url.pathExtension.lowercased() == "app" {
            return try Self.recycleWithFinder(url)
        }
    }

    /// Keel never deletes apps or their files outright.
    func deletePermanently(_ url: URL) throws {
        throw CocoaError(.featureUnsupported)
    }

    private static func recycleWithFinder(_ url: URL) throws -> URL? {
        final class Outcome: @unchecked Sendable {
            var error: (any Error)?
            var landed: URL?
        }
        let outcome = Outcome()
        let done = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                NSWorkspace.shared.recycle([url]) { moved, error in
                    outcome.landed = moved[url]
                    outcome.error = error
                    done.signal()
                }
            }
        }
        // Runs on the uninstaller's background thread, never on the main one.
        if done.wait(timeout: .now() + 120) == .timedOut {
            throw CocoaError(.userCancelled)
        }
        if let error = outcome.error { throw error }
        return outcome.landed
    }
}
