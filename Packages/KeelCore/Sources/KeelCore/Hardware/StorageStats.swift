import Foundation

/// Bytes read from and written to all disks since boot.
public struct DiskIOTotals: Equatable, Sendable {
    public let readBytes: UInt64
    public let writtenBytes: UInt64

    public init(readBytes: UInt64, writtenBytes: UInt64) {
        self.readBytes = readBytes
        self.writtenBytes = writtenBytes
    }
}

/// Throughput between two samples, in bytes per second.
public struct DiskIORate: Equatable, Sendable {
    public let readPerSecond: Double
    public let writePerSecond: Double

    public init(readPerSecond: Double, writePerSecond: Double) {
        self.readPerSecond = readPerSecond
        self.writePerSecond = writePerSecond
    }
}

public struct StorageDevice: Equatable, Sendable {
    /// e.g. "APPLE SSD AP0512Z"
    public let model: String
    public let isSolidState: Bool
    /// e.g. "Apple Fabric", "PCI-Express", "USB"
    public let interconnect: String?
    public let isInternal: Bool
}

public enum StorageReader {
    public static func ioTotals() -> DiskIOTotals? {
        #if os(macOS)
        totals(fromDrivers: IORegistry.properties(ofServicesNamed: "IOBlockStorageDriver"))
        #else
        nil
        #endif
    }

    public static func rate(from earlier: DiskIOTotals, to later: DiskIOTotals, seconds: Double) -> DiskIORate {
        guard seconds > 0 else { return DiskIORate(readPerSecond: 0, writePerSecond: 0) }
        // Counters reset when a disk is ejected; never report negative speeds.
        let read = later.readBytes >= earlier.readBytes ? Double(later.readBytes - earlier.readBytes) : 0
        let written = later.writtenBytes >= earlier.writtenBytes ? Double(later.writtenBytes - earlier.writtenBytes) : 0
        return DiskIORate(readPerSecond: read / seconds, writePerSecond: written / seconds)
    }

    /// The disk macOS runs from: the internal one, solid state if there is a choice.
    public static func startupDevice() -> StorageDevice? {
        #if os(macOS)
        let devices = IORegistry.properties(ofServicesNamed: "IOBlockStorageDevice").compactMap(device(from:))
        return devices.first { $0.isInternal && $0.isSolidState } ?? devices.first { $0.isInternal }
        #else
        nil
        #endif
    }

    static func totals(fromDrivers drivers: [[String: Any]]) -> DiskIOTotals? {
        let statistics = drivers.compactMap { $0["Statistics"] as? [String: Any] }
        guard !statistics.isEmpty else { return nil }
        let read = statistics.compactMap { ioNumber($0["Bytes (Read)"]) }.reduce(0, +)
        let written = statistics.compactMap { ioNumber($0["Bytes (Write)"]) }.reduce(0, +)
        return DiskIOTotals(readBytes: UInt64(max(read, 0)), writtenBytes: UInt64(max(written, 0)))
    }

    static func device(from properties: [String: Any]) -> StorageDevice? {
        guard let characteristics = properties["Device Characteristics"] as? [String: Any],
              let model = (characteristics["Product Name"] as? String)?.trimmingCharacters(in: .whitespaces),
              !model.isEmpty else { return nil }
        let protocolInfo = properties["Protocol Characteristics"] as? [String: Any]
        return StorageDevice(
            model: model,
            isSolidState: (characteristics["Medium Type"] as? String) == "Solid State",
            interconnect: protocolInfo?["Physical Interconnect"] as? String,
            isInternal: (protocolInfo?["Physical Interconnect Location"] as? String) == "Internal"
        )
    }
}
