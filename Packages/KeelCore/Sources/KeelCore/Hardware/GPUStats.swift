import Foundation

public struct GPUSnapshot: Equatable, Sendable {
    public let name: String?
    public let coreCount: Int?
    /// Busy share of the GPU, 0...1.
    public let utilization: Double
    /// Memory the GPU is using; on Apple silicon this is shared system memory.
    public let memoryInUseBytes: UInt64?

    public init(name: String?, coreCount: Int?, utilization: Double, memoryInUseBytes: UInt64?) {
        self.name = name
        self.coreCount = coreCount
        self.utilization = utilization
        self.memoryInUseBytes = memoryInUseBytes
    }
}

public enum GPUReader {
    /// The busiest GPU, which is the only one on Apple silicon Macs.
    public static func current() -> GPUSnapshot? {
        #if os(macOS)
        IORegistry.properties(ofServicesNamed: "IOAccelerator")
            .compactMap(snapshot(from:))
            .max { $0.utilization < $1.utilization }
        #else
        nil
        #endif
    }

    /// Builds a snapshot from an IOAccelerator's registry properties.
    static func snapshot(from properties: [String: Any]) -> GPUSnapshot? {
        guard let stats = properties["PerformanceStatistics"] as? [String: Any],
              let percent = ioNumber(stats["Device Utilization %"]) else { return nil }

        // Apple silicon reports shared memory in use; discrete GPUs report VRAM.
        let memory = ioNumber(stats["In use system memory"]) ?? ioNumber(stats["vramUsedBytes"])
        return GPUSnapshot(
            name: properties["model"] as? String,
            coreCount: ioNumber(properties["gpu-core-count"]).map(Int.init),
            utilization: min(max(Double(percent) / 100, 0), 1),
            memoryInUseBytes: memory.map { UInt64(max($0, 0)) }
        )
    }
}
