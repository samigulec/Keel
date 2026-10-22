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

    /// The parts Activity Monitor shows under "Memory Used" and "Cached Files".
    public struct Breakdown: Equatable, Sendable {
        public let appBytes: UInt64
        public let wiredBytes: UInt64
        public let compressedBytes: UInt64
        /// File cache: memory macOS hands back as soon as apps need it.
        public let cachedFilesBytes: UInt64

        public init(appBytes: UInt64, wiredBytes: UInt64, compressedBytes: UInt64, cachedFilesBytes: UInt64) {
            self.appBytes = appBytes
            self.wiredBytes = wiredBytes
            self.compressedBytes = compressedBytes
            self.cachedFilesBytes = cachedFilesBytes
        }
    }

    public let totalBytes: UInt64
    /// Memory in use the way Activity Monitor counts it:
    /// app memory + wired + compressed. File cache is not "used".
    public let usedBytes: UInt64
    public let pressure: Pressure
    public let breakdown: Breakdown?
    public let swapUsedBytes: UInt64

    public init(
        totalBytes: UInt64,
        usedBytes: UInt64,
        pressure: Pressure,
        breakdown: Breakdown? = nil,
        swapUsedBytes: UInt64 = 0
    ) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.pressure = pressure
        self.breakdown = breakdown
        self.swapUsedBytes = swapUsedBytes
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
        let purgeable = min(UInt64(stats.purgeable_count), UInt64(stats.internal_page_count))
        let breakdown = MemorySnapshot.Breakdown(
            appBytes: (UInt64(stats.internal_page_count) - purgeable) * pageSize,
            wiredBytes: UInt64(stats.wire_count) * pageSize,
            compressedBytes: UInt64(stats.compressor_page_count) * pageSize,
            cachedFilesBytes: (UInt64(stats.external_page_count) + purgeable) * pageSize
        )
        return MemorySnapshot(
            totalBytes: ProcessInfo.processInfo.physicalMemory,
            usedBytes: breakdown.appBytes + breakdown.wiredBytes + breakdown.compressedBytes,
            pressure: systemPressure(),
            breakdown: breakdown,
            swapUsedBytes: swapUsed()
        )
        #else
        guard let text = try? String(contentsOfFile: "/proc/meminfo", encoding: .utf8) else { return nil }
        return parseMeminfo(text)
        #endif
    }

    #if os(macOS)
    private static func swapUsed() -> UInt64 {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        guard sysctlbyname("vm.swapusage", &usage, &size, nil, 0) == 0 else { return 0 }
        return usage.xsu_used
    }

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
        let swapUsed = (values["SwapTotal"] ?? 0) - min(values["SwapFree"] ?? 0, values["SwapTotal"] ?? 0)
        return MemorySnapshot(
            totalBytes: total,
            usedBytes: total - min(available, total),
            pressure: pressure,
            breakdown: nil,
            swapUsedBytes: swapUsed
        )
    }
}
