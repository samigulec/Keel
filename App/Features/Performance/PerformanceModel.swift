import AppKit
import KeelCore
import Observation

struct AppMemoryUsage: Identifiable {
    let id: pid_t
    let name: String
    let icon: NSImage?
    let footprintBytes: UInt64
}

/// Per-process CPU for Performans; per-app memory, startup items and fans
/// for Optimizasyon and Keel AI. Lists refresh only while their screen is visible.
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

    /// Asks the app to quit, as if the user chose Quit from its menu.
    func quit(_ app: AppMemoryUsage) {
        NSRunningApplication(processIdentifier: app.id)?.terminate()
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await refreshApps()
        }
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
        // What `launchctl disable` turned off is not in the plists.
        async let session = SystemControl.overrides(domain: "gui/\(getuid())")
        async let system = SystemControl.overrides(domain: "system")
        let (sessionOverrides, systemOverrides) = await (session, system)
        launchItems = await Task.detached(priority: .utility) {
            LaunchItemScanner.scan(sessionOverrides: sessionOverrides, systemOverrides: systemOverrides)
        }.value
        launchItemsLoaded = true
    }

    // MARK: Changing startup

    /// Services being switched right now, by id.
    private(set) var switchingItems: Set<String> = []
    /// The last problem switching a service or a login item.
    private(set) var startupMessage: String?

    /// Turns background services off or back on and returns the problems;
    /// system services ask for an administrator's password first.
    @discardableResult
    func setLaunchItems(_ items: [LaunchItem], enabled: Bool) async -> [String] {
        let ids = Set(items.map(\.id))
        switchingItems.formUnion(ids)
        let problems = await SystemControl.setLaunchItems(items, enabled: enabled)
        startupMessage = problems.isEmpty ? nil : problems.joined(separator: "\n")
        await refreshLaunchItems()
        switchingItems.subtract(ids)
        return problems
    }

    /// Apps in "Open at Login". Reading them needs permission to use System
    /// Events, so the list loads when the user asks the first time.
    private(set) var loginItems: [LoginItem] = []
    private(set) var loginItemsLoaded = false
    private(set) var loginItemsError: String?
    /// Taken out of the list since Keel started, so they can be put back.
    private(set) var removedLoginItems: [LoginItem] = []

    func refreshLoginItems() async {
        switch await SystemControl.loginItems() {
        case .success(let items):
            loginItems = items
            loginItemsError = nil
            loginItemsLoaded = true
        case .failure(let error):
            loginItemsError = error.message
        }
    }

    /// Finds the login items that are listed now, reading the list once if needed.
    func loginItemsWhenReady() async -> [LoginItem] {
        if !loginItemsLoaded { await refreshLoginItems() }
        return loginItems
    }

    @discardableResult
    func removeLoginItem(_ item: LoginItem) async -> SystemControl.Outcome {
        let outcome = await SystemControl.appleScript(LoginItemScript.remove(item))
        if case .done = outcome, !removedLoginItems.contains(item) { removedLoginItems.append(item) }
        startupMessage = outcome.errorMessage
        await refreshLoginItems()
        return outcome
    }

    func restoreLoginItem(_ item: LoginItem) async {
        guard let script = LoginItemScript.add(item) else { return }
        let outcome = await SystemControl.appleScript(script)
        if case .done = outcome { removedLoginItems.removeAll { $0 == item } }
        startupMessage = outcome.errorMessage
        await refreshLoginItems()
    }

    // MARK: Fans

    private(set) var fanBusy = false
    /// What the last fan change did, or why it did not.
    private(set) var fanMessage: String?
    /// The last setting Keel applied; macOS resets fans to automatic on restart.
    private(set) var fanSetting: FanSetting?

    @discardableResult
    func setFans(_ setting: FanSetting) async -> SystemControl.Outcome {
        fanBusy = true
        let outcome = await SystemControl.setFans(setting)
        switch outcome {
        case .done(let output):
            fanSetting = setting
            fanMessage = output.trimmingCharacters(in: .whitespacesAndNewlines)
        case .cancelled:
            break
        case .failed(let message):
            fanMessage = message
        }
        fanBusy = false
        return outcome
    }

    static func openLoginItemsSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
