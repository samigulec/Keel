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
    @ObservationIgnored private var running: Set<Job> = []
    @ObservationIgnored private var requested: Set<Job> = []
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    /// Readings taken together off the main thread.
    private enum Job {
        /// Free space; macOS can take seconds to count purgeable space.
        case disk
        case battery
        case live
        case thermals
    }

    init() {
        refreshTask = Task { [weak self, interval, slowEvery] in
            var tick = 0
            while !Task.isCancelled {
                if tick % slowEvery == 0 {
                    self?.start(.disk)
                    self?.start(.battery)
                }
                self?.start(.live)
                // Sensors take a moment to read; every other tick is enough.
                if tick % 2 == 0 { self?.start(.thermals) }
                tick += 1
                try? await Task.sleep(for: interval)
            }
        }
    }

    /// Re-reads the disk now, e.g. right after a cleanup.
    func refresh() {
        start(.disk)
        start(.battery)
    }

    /// Reads the disk and waits for it, for a scan that reports free space.
    func refreshNow() async {
        start(.battery)
        if let disk = await Self.read(Self.readDisk) { self.disk = disk }
    }

    /// Every reading runs in the background so a system call that is slow
    /// or never answers cannot freeze the window. One of each kind runs at a
    /// time; asking again while it runs reads once more when it ends.
    private func start(_ job: Job) {
        guard !running.contains(job) else {
            requested.insert(job)
            return
        }
        running.insert(job)
        Task { [weak self] in
            switch job {
            case .disk:
                let disk = await Self.read(Self.readDisk)
                if let disk { self?.disk = disk }
            case .battery:
                let reading = await Self.read { (BatteryReader.current(), NetworkReader.primaryAddress()) }
                self?.battery = reading.0
                self?.networkAddress = reading.1
            case .live:
                let reading = await Self.read(LiveReading.take)
                self?.apply(reading)
            case .thermals:
                let snapshot = await Self.read(SensorReader.snapshot)
                if let snapshot { self?.apply(snapshot) }
            }
            self?.finish(job)
        }
    }

    private func finish(_ job: Job) {
        running.remove(job)
        if requested.remove(job) != nil { start(job) }
    }

    private nonisolated static func read<Value: Sendable>(_ body: @escaping @Sendable () -> Value) async -> Value {
        await Task.detached(priority: .utility, operation: body).value
    }

    private nonisolated static func readDisk() -> DiskSpace? {
        try? DiskSpace.current(for: FileManager.default.homeDirectoryForCurrentUser)
    }

    private func apply(_ reading: LiveReading) {
        if let memory = reading.memory { self.memory = memory }
        thermalState = ProcessInfo.processInfo.thermalState
        uptime = ProcessInfo.processInfo.systemUptime
        loadAverages = reading.loadAverages

        if let ticks = reading.cpu {
            if let lastTicks {
                let usage = CPUReader.usage(from: lastTicks, to: ticks)
                cpuUsage = usage
                cpuSplit = CPUReader.split(from: lastTicks, to: ticks)
                cpuHistory = Self.appending(usage, to: cpuHistory)
            }
            lastTicks = ticks
        }
        if let cores = reading.cores {
            if lastCoreTicks.count == cores.count {
                perCoreUsage = zip(lastCoreTicks, cores).map { CPUReader.usage(from: $0, to: $1) }
            }
            lastCoreTicks = cores
        }

        gpu = reading.gpu
        if let gpu { gpuHistory = Self.appending(gpu.utilization, to: gpuHistory) }

        if let totals = reading.diskIO {
            if let last = lastDiskSample {
                let rate = StorageReader.rate(from: last.totals, to: totals, seconds: Self.seconds(from: last.time, to: reading.time))
                diskRate = rate
                diskReadHistory = Self.appending(rate.readPerSecond, to: diskReadHistory)
                diskWriteHistory = Self.appending(rate.writePerSecond, to: diskWriteHistory)
            }
            diskTotals = totals
            lastDiskSample = (totals, reading.time)
        }

        if let totals = reading.network {
            if let last = lastNetworkSample {
                let rate = NetworkRate(from: last.totals, to: totals, seconds: Self.seconds(from: last.time, to: reading.time))
                networkRate = rate
                networkInHistory = Self.appending(rate.receivedPerSecond, to: networkInHistory)
                networkOutHistory = Self.appending(rate.sentPerSecond, to: networkOutHistory)
            }
            networkTotals = totals
            lastNetworkSample = (totals, reading.time)
        }
    }

    private func apply(_ snapshot: ThermalSnapshot) {
        thermals = snapshot
        if let cpu = snapshot.summary(.cpu) ?? snapshot.summaries.first {
            cpuTemperatureHistory = Self.appending(cpu.hottest, to: cpuTemperatureHistory)
        }
    }

    private static func seconds(from start: ContinuousClock.Instant, to end: ContinuousClock.Instant) -> Double {
        let elapsed = start.duration(to: end)
        return Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
    }

    private static func appending(_ value: Double, to history: [Double]) -> [Double] {
        Array((history + [value]).suffix(historyLength))
    }
}

/// The readings that change every tick, taken together.
private struct LiveReading: Sendable {
    let memory: MemorySnapshot?
    let loadAverages: [Double]?
    let cpu: CPUTicks?
    let cores: [CPUTicks]?
    let gpu: GPUSnapshot?
    let diskIO: DiskIOTotals?
    let network: NetworkTotals?
    let time: ContinuousClock.Instant

    static func take() -> LiveReading {
        LiveReading(
            memory: MemoryReader.current(),
            loadAverages: SystemInfo.loadAverages(),
            cpu: CPUReader.ticks(),
            cores: CPUReader.perCoreTicks(),
            gpu: GPUReader.current(),
            diskIO: StorageReader.ioTotals(),
            network: NetworkReader.totals(),
            time: .now
        )
    }
}
