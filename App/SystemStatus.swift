import Foundation
import KeelCore
import Observation

/// Live system readings shared by the main window and the menu bar.
@MainActor
@Observable
final class SystemStatus {
    private(set) var disk: DiskSpace?
    private(set) var memory: MemorySnapshot?
    /// Busy share of all cores over the last interval, 0...1.
    private(set) var cpuUsage: Double?
    /// Recent CPU readings, oldest first, for the sparkline.
    private(set) var cpuHistory: [Double] = []

    static let historyLength = 30
    private let interval: Duration = .seconds(2)
    /// The disk changes slowly; read it every 15 ticks (30 s).
    private let diskEvery = 15

    @ObservationIgnored private var lastTicks: CPUTicks?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    init() {
        refreshTask = Task { [weak self, interval, diskEvery] in
            var tick = 0
            while !Task.isCancelled {
                self?.sample(includeDisk: tick % diskEvery == 0)
                tick += 1
                try? await Task.sleep(for: interval)
            }
        }
    }

    /// Re-reads the disk now, e.g. right after a cleanup.
    func refresh() {
        sample(includeDisk: true)
    }

    private func sample(includeDisk: Bool) {
        if includeDisk {
            disk = try? DiskSpace.current(for: FileManager.default.homeDirectoryForCurrentUser)
        }
        memory = MemoryReader.current()

        if let ticks = CPUReader.ticks() {
            if let lastTicks {
                let usage = CPUReader.usage(from: lastTicks, to: ticks)
                cpuUsage = usage
                cpuHistory = Array((cpuHistory + [usage]).suffix(Self.historyLength))
            }
            lastTicks = ticks
        }
    }
}
