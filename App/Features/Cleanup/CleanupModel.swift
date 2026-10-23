import AppKit
import KeelCore
import Observation

/// Scan results and selection shared by Smart Scan and Cleanup.
@MainActor
@Observable
final class CleanupModel {
    enum Phase: Equatable {
        case idle
        case scanning
        case ready
        case cleaning
    }

    private(set) var phase: Phase = .idle
    private(set) var results: [CategoryScanResult] = []
    private(set) var lastScan: Date?
    private(set) var lastReport: CleanupReport?
    /// What the last undo put back.
    private(set) var lastRestore: RestoreReport?
    private(set) var errorMessage: String?
    var selection: Set<CleanupCategoryID> = []
    /// Bundle ID → app name for apps that were running during the last scan.
    private(set) var runningAppNames: [String: String] = [:]

    private let status: SystemStatus
    /// The scan in progress; the screen and Keel AI share it instead of starting a second one.
    @ObservationIgnored private var inFlightScan: Task<[CategoryScanResult], Never>?

    init(status: SystemStatus) {
        self.status = status
    }

    var isBusy: Bool { phase == .scanning || phase == .cleaning }

    var totalBytes: Int64 { results.reduce(0) { $0 + $1.totalBytes } }

    /// What a default cleanup removes: categories that are preselected.
    var recommendedBytes: Int64 {
        results.filter(\.category.selectedByDefault).reduce(0) { $0 + $1.totalBytes }
    }

    /// Found in categories the user must opt into (Trash, old downloads).
    var optInBytes: Int64 { totalBytes - recommendedBytes }

    var optInTitles: [String] {
        results.filter { !$0.category.selectedByDefault && !$0.items.isEmpty }.map(\.category.title)
    }

    var selectedResults: [CategoryScanResult] {
        results.filter { selection.contains($0.category.id) && !$0.items.isEmpty }
    }

    var selectedBytes: Int64 { selectedResults.reduce(0) { $0 + $1.totalBytes } }

    /// Bytes that would be deleted for good rather than moved to the Trash.
    var selectedPermanentBytes: Int64 {
        selectedResults.filter { $0.category.removal == .deletePermanently }.reduce(0) { $0 + $1.totalBytes }
    }

    var allSelected: Bool {
        let selectable = results.filter { !$0.items.isEmpty }.map(\.category.id)
        return !selectable.isEmpty && selectable.allSatisfy(selection.contains)
    }

    func toggleAll() {
        selection = allSelected ? [] : Set(results.filter { !$0.items.isEmpty }.map(\.category.id))
    }

    func scan() {
        _ = startScan()
    }

    /// Scans and returns once results are in; used by Keel AI's tools.
    @discardableResult
    func scanAndWait() async -> [CategoryScanResult] {
        await startScan().value
    }

    func cancelScan() {
        inFlightScan?.cancel()
    }

    private func startScan() -> Task<[CategoryScanResult], Never> {
        if let inFlightScan { return inFlightScan }
        let current = results
        guard phase != .cleaning else { return Task { current } }

        phase = .scanning
        errorMessage = nil
        lastReport = nil
        lastRestore = nil

        refreshRunningApps()
        let context = ScanContext(runningBundleIDs: Set(runningAppNames.keys))
        let task = Task {
            do {
                // The scan's work runs in child tasks off the main actor, and
                // awaiting it directly lets cancelScan() reach them.
                let results = try await CleanupScanner.standard().scan(context: context)
                self.results = results
                selection = Set(results.filter { $0.category.selectedByDefault }.map(\.category.id))
                lastScan = Date()
                phase = .ready
            } catch is CancellationError {
                phase = results.isEmpty ? .idle : .ready
            } catch {
                errorMessage = error.localizedDescription
                phase = results.isEmpty ? .idle : .ready
            }
            inFlightScan = nil
            return results
        }
        inFlightScan = task
        return task
    }

    func cleanSelection() {
        Task { await cleanSelectionAndWait() }
    }

    /// Removes the selected categories and returns the report once done.
    @discardableResult
    func cleanSelectionAndWait() async -> CleanupReport? {
        await cleanAndWait(items: selectedResults.flatMap(\.items))
    }

    /// Removes exactly these items, e.g. the ones the user kept ticked on a
    /// Keel AI suggestion. Items no longer in the latest scan are skipped.
    @discardableResult
    func cleanAndWait(items: [CleanupItem]) async -> CleanupReport? {
        guard phase == .ready else { return nil }
        // Match by path: a rescan may have changed sizes or dates since.
        let current = Dictionary(results.flatMap(\.items).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let valid = items.compactMap { current[$0.id] }
        guard !valid.isEmpty else { return nil }
        phase = .cleaning

        // Apps opened since the scan keep their files.
        refreshRunningApps()
        let running = Set(runningAppNames.keys)
        let report = await Task.detached(priority: .userInitiated) {
            CleanupExecutor.standard().perform(valid, runningBundleIDs: running)
        }.value
        let cleaned = Set(report.removed)
        results = results.map { $0.removing(cleaned) }
        lastReport = report
        phase = .ready
        status.refresh()
        return report
    }

    /// Puts the last cleanup's trashed items back and scans again.
    func undoLastCleanup() async {
        guard phase == .ready, let trashed = lastReport?.trashed, !trashed.isEmpty else { return }
        let report = await Undo.restore(trashed)
        scan()
        lastRestore = report
    }

    private func refreshRunningApps() {
        let apps = NSWorkspace.shared.runningApplications
        runningAppNames = Dictionary(
            apps.compactMap { app in app.bundleIdentifier.map { ($0, app.localizedName ?? $0) } },
            uniquingKeysWith: { first, _ in first }
        )
    }
}
