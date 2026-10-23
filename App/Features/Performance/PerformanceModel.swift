import AppKit
import KeelCore
import Observation

struct AppMemoryUsage: Identifiable {
    let id: pid_t
    let name: String
    let icon: NSImage?
    let footprintBytes: UInt64
}

/// The per-app memory list and the startup items, refreshed only while
/// the Performance screen is visible.
@MainActor
@Observable
final class PerformanceModel {
    private(set) var topApps: [AppMemoryUsage] = []
    private(set) var launchItems: [LaunchItem] = []
    private(set) var launchItemsLoaded = false
    /// The busiest processes since the previous refresh.
    private(set) var topProcesses: [ProcessCPUUsage] = []
    @ObservationIgnored private var lastProcessSample: (times: [ProcessCPUTime], time: ContinuousClock.Instant)?

    static let topAppCount = 8

    /// Items that start by themselves: they run at load or are kept alive, and are not disabled.
    var activeLaunchItems: [LaunchItem] {
        launchItems.filter { ($0.runsAtLoad || $0.keepsAlive) && !$0.isDisabled }
    }

    func refreshApps() async {
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        let roots = Set(apps.map(\.processIdentifier))
        let totals = await Task.detached(priority: .utility) {
            ProcessMemory.totals(for: roots, in: ProcessMemory.samples())
        }.value

        topApps = apps
            .compactMap { app -> AppMemoryUsage? in
                guard let bytes = totals[app.processIdentifier], bytes > 0 else { return nil }
                return AppMemoryUsage(
                    id: app.processIdentifier,
                    name: app.localizedName ?? app.bundleIdentifier ?? "?",
                    icon: app.icon,
                    footprintBytes: bytes
                )
            }
            .sorted { $0.footprintBytes > $1.footprintBytes }
            .prefix(Self.topAppCount)
            .map { $0 }
    }

    func refreshProcesses() async {
        let times = await Task.detached(priority: .utility) { ProcessCPU.sample() }.value
        let now = ContinuousClock.now
        if let last = lastProcessSample {
            topProcesses = ProcessCPU.usage(from: last.times, to: times, elapsed: last.time.duration(to: now))
        }
        lastProcessSample = (times, now)
    }

    func refreshLaunchItems() async {
        launchItems = await Task.detached(priority: .utility) { LaunchItemScanner.scan() }.value
        launchItemsLoaded = true
    }

    static func openLoginItemsSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
