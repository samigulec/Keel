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
    private(set) var errorMessage: String?
    var selection: Set<CleanupCategoryID> = []
    /// Bundle ID → app name for apps that were running during the last scan.
    private(set) var runningAppNames: [String: String] = [:]

    private let status: SystemStatus
    @ObservationIgnored private var scanTask: Task<Void, Never>?

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
        guard !isBusy else { return }
        phase = .scanning
        errorMessage = nil
        lastReport = nil

        let apps = NSWorkspace.shared.runningApplications
        runningAppNames = Dictionary(
            apps.compactMap { app in app.bundleIdentifier.map { ($0, app.localizedName ?? $0) } },
            uniquingKeysWith: { first, _ in first }
        )
        let context = ScanContext(runningBundleIDs: Set(runningAppNames.keys))
        scanTask = Task {
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
        }
    }

    func cancelScan() {
        scanTask?.cancel()
    }

    func cleanSelection() {
        guard phase == .ready else { return }
        let items = selectedResults.flatMap(\.items)
        guard !items.isEmpty else { return }
        phase = .cleaning

        Task {
            let report = await Task.detached(priority: .userInitiated) {
                CleanupExecutor.standard().perform(items)
            }.value
            let cleaned = Set(report.removed)
            results = results.map { $0.removing(cleaned) }
            lastReport = report
            phase = .ready
            status.refresh()
        }
    }
}
