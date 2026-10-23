import Foundation
import KeelCore
import Observation

/// Live system readings shared by the main window and the menu bar.
@MainActor
@Observable
final class SystemStatus {
    static let historyLength = 30

    let info = SystemInfo.current()
    let storageDevice = StorageReader.startupDevice()

    private(set) var disk: DiskSpace?
    private(set) var memory: MemorySnapshot?
    private(set) var battery: BatterySnapshot?
    private(set) var thermalState = ProcessInfo.processInfo.thermalState
    private(set) var uptime = ProcessInfo.processInfo.systemUptime
    private(set) var loadAverages: [Double]?

    /// Busy share of all cores over the last interval, 0...1.
    private(set) var cpuUsage: Double?
    private(set) var cpuSplit: (user: Double, system: Double)?
    private(set) var perCoreUsage: [Double] = []
    private(set) var gpu: GPUSnapshot?
    private(set) var diskRate: DiskIORate?
    private(set) var diskTotals: DiskIOTotals?
    private(set) var networkRate: NetworkRate?
    private(set) var networkTotals: NetworkTotals?
    private(set) var networkAddress: NetworkAddress?
    /// Temperatures and fans; nil until the first reading or when the Mac reports none.
    private(set) var thermals: ThermalSnapshot?

    // Recent readings, oldest first, for the sparklines.
    private(set) var cpuHistory: [Double] = []
    private(set) var gpuHistory: [Double] = []
    private(set) var diskReadHistory: [Double] = []
    private(set) var diskWriteHistory: [Double] = []
    private(set) var networkInHistory: [Double] = []
    private(set) var networkOutHistory: [Double] = []
    /// Hottest CPU sensor, in °C.
    private(set) var cpuTemperatureHistory: [Double] = []

    private let interval: Duration = .seconds(2)
    /// Slow-changing readings are taken every 15 ticks (30 s).
    private let slowEvery = 15

    @ObservationIgnored private var lastTicks: CPUTicks?
    @ObservationIgnored private var lastCoreTicks: [CPUTicks] = []
    @ObservationIgnored private var lastDiskSample: (totals: DiskIOTotals, time: ContinuousClock.Instant)?
    @ObservationIgnored private var lastNetworkSample: (totals: NetworkTotals, time: ContinuousClock.Instant)?
    @ObservationIgnored private var thermalsBusy = false
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    init() {
        refreshTask = Task { [weak self, interval, slowEvery] in
            var tick = 0
            while !Task.isCancelled {
                self?.sample(includeSlow: tick % slowEvery == 0)
                // Sensors take a moment to read; every other tick, off the main thread.
                if tick % 2 == 0 { await self?.sampleThermals() }
                tick += 1
                try? await Task.sleep(for: interval)
            }
        }
    }

    /// Re-reads the disk now, e.g. right after a cleanup.
    func refresh() {
        sample(includeSlow: true)
    }

    private func sample(includeSlow: Bool) {
        if includeSlow {
            disk = try? DiskSpace.current(for: FileManager.default.homeDirectoryForCurrentUser)
            battery = BatteryReader.current()
            networkAddress = NetworkReader.primaryAddress()
        }
        memory = MemoryReader.current()
        thermalState = ProcessInfo.processInfo.thermalState
        uptime = ProcessInfo.processInfo.systemUptime
        loadAverages = SystemInfo.loadAverages()

        sampleCPU()

        gpu = GPUReader.current()
        if let gpu { gpuHistory = Self.appending(gpu.utilization, to: gpuHistory) }

        sampleDisk()
        sampleNetwork()
    }

    private func sampleCPU() {
        if let ticks = CPUReader.ticks() {
            if let lastTicks {
                let usage = CPUReader.usage(from: lastTicks, to: ticks)
                cpuUsage = usage
                cpuSplit = CPUReader.split(from: lastTicks, to: ticks)
                cpuHistory = Self.appending(usage, to: cpuHistory)
            }
            lastTicks = ticks
        }
        if let cores = CPUReader.perCoreTicks() {
            if lastCoreTicks.count == cores.count {
                perCoreUsage = zip(lastCoreTicks, cores).map { CPUReader.usage(from: $0, to: $1) }
            }
            lastCoreTicks = cores
        }
    }

    private func sampleDisk() {
        guard let totals = StorageReader.ioTotals() else { return }
        let now = ContinuousClock.now
        if let last = lastDiskSample {
            let elapsed = last.time.duration(to: now)
            let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
            let rate = StorageReader.rate(from: last.totals, to: totals, seconds: seconds)
            diskRate = rate
            diskReadHistory = Self.appending(rate.readPerSecond, to: diskReadHistory)
            diskWriteHistory = Self.appending(rate.writePerSecond, to: diskWriteHistory)
        }
        diskTotals = totals
        lastDiskSample = (totals, now)
    }

    private func sampleThermals() async {
        // A sensor that does not answer must not stall the other readings:
        // stop waiting after three seconds; a reading still running keeps
        // the next one from starting until it ends.
        guard !thermalsBusy else { return }
        thermalsBusy = true
        let snapshot: ThermalSnapshot? = await withCheckedContinuation { continuation in
            let answer = FirstAnswer(continuation)
            Task.detached(priority: .utility) { [weak self] in
                answer.resume(SensorReader.snapshot())
                await MainActor.run { self?.thermalsBusy = false }
            }
            Task.detached {
                try? await Task.sleep(for: .seconds(3))
                answer.resume(nil)
            }
        }
        guard let snapshot else { return }
        thermals = snapshot
        if let cpu = snapshot.summary(.cpu) ?? snapshot.summaries.first {
            cpuTemperatureHistory = Self.appending(cpu.hottest, to: cpuTemperatureHistory)
        }
    }

    private func sampleNetwork() {
        guard let totals = NetworkReader.totals() else { return }
        let now = ContinuousClock.now
        if let last = lastNetworkSample {
            let elapsed = last.time.duration(to: now)
            let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
            let rate = NetworkRate(from: last.totals, to: totals, seconds: seconds)
            networkRate = rate
            networkInHistory = Self.appending(rate.receivedPerSecond, to: networkInHistory)
            networkOutHistory = Self.appending(rate.sentPerSecond, to: networkOutHistory)
        }
        networkTotals = totals
        lastNetworkSample = (totals, now)
    }

    private static func appending(_ value: Double, to history: [Double]) -> [Double] {
        Array((history + [value]).suffix(historyLength))
    }
}

/// Resumes a continuation with whichever value arrives first; later ones are dropped.
private final class FirstAnswer<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Never>?

    init(_ continuation: CheckedContinuation<Value, Never>) {
        self.continuation = continuation
    }

    func resume(_ value: Value) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(returning: value)
    }
}
