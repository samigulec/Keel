import Foundation

#if canImport(Darwin)
import Darwin
#endif

public struct MemorySnapshot: Equatable, Sendable {
    public enum Pressure: Equatable, Sendable {
        case normal
        case warning
        case critical
    }

    public let totalBytes: UInt64
    /// Memory in use the way Activity Monitor counts it:
    /// app memory + wired + compressed. File cache is not "used".
    public let usedBytes: UInt64
    public let pressure: Pressure

    public init(totalBytes: UInt64, usedBytes: UInt64, pressure: Pressure) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.pressure = pressure
    }

    public var usedFraction: Double {
        totalBytes > 0 ? min(Double(usedBytes) / Double(totalBytes), 1) : 0
    }
}

public enum MemoryReader {
    public static func current() -> MemorySnapshot? {
        #if os(macOS)
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(getpagesize())
        let appPages = UInt64(stats.internal_page_count) - min(UInt64(stats.purgeable_count), UInt64(stats.internal_page_count))
        let usedPages = appPages + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        return MemorySnapshot(
            totalBytes: ProcessInfo.processInfo.physicalMemory,
            usedBytes: usedPages * pageSize,
            pressure: systemPressure()
        )
        #else
        guard let text = try? String(contentsOfFile: "/proc/meminfo", encoding: .utf8) else { return nil }
        return parseMeminfo(text)
        #endif
    }

    #if os(macOS)
    /// The kernel's own pressure level, the same signal Activity Monitor graphs.
    private static func systemPressure() -> MemorySnapshot.Pressure {
        var level: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0) == 0 else { return .normal }
        switch level {
        case 4: return .critical
        case 2: return .warning
        default: return .normal
        }
    }
    #endif

    /// Linux fallback, also used to test the snapshot logic off macOS.
    static func parseMeminfo(_ text: String) -> MemorySnapshot? {
        var values: [String: UInt64] = [:]
        for line in text.split(separator: "\n") {
            let parts = line.split(whereSeparator: { $0 == ":" || $0 == " " })
            if parts.count >= 2, let kilobytes = UInt64(parts[1]) {
                values[String(parts[0])] = kilobytes * 1024
            }
        }
        guard let total = values["MemTotal"], let available = values["MemAvailable"], total > 0 else { return nil }
        let availableFraction = Double(available) / Double(total)
        let pressure: MemorySnapshot.Pressure = availableFraction < 0.1 ? .critical : availableFraction < 0.2 ? .warning : .normal
        return MemorySnapshot(totalBytes: total, usedBytes: total - min(available, total), pressure: pressure)
    }
}
