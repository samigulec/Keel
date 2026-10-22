import Foundation

#if canImport(Darwin)
import Darwin
import KeelSystemShims
#endif

/// Cumulative CPU time across all cores since boot, in scheduler ticks.
public struct CPUTicks: Equatable, Sendable {
    public var user: UInt64
    public var system: UInt64
    public var idle: UInt64
    public var nice: UInt64

    public init(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }

    var busy: UInt64 { user + system + nice }
    var total: UInt64 { busy + idle }
}

public enum CPUReader {
    public static func ticks() -> CPUTicks? {
        #if os(macOS)
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        let ticks = info.cpu_ticks // user, system, idle, nice
        return CPUTicks(user: UInt64(ticks.0), system: UInt64(ticks.1), idle: UInt64(ticks.2), nice: UInt64(ticks.3))
        #else
        guard let text = try? String(contentsOfFile: "/proc/stat", encoding: .utf8) else { return nil }
        return parseProcStat(text)
        #endif
    }

    /// One reading per logical core, in the kernel's core order.
    public static func perCoreTicks() -> [CPUTicks]? {
        #if os(macOS)
        var coreCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        guard host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &coreCount, &info, &infoCount) == KERN_SUCCESS,
              let info else { return nil }
        defer { keel_deallocate_processor_info(info, infoCount) }

        let stride = Int(CPU_STATE_MAX)
        return (0..<Int(coreCount)).map { core in
            func value(_ state: Int32) -> UInt64 {
                UInt64(UInt32(bitPattern: info[core * stride + Int(state)]))
            }
            return CPUTicks(
                user: value(CPU_STATE_USER),
                system: value(CPU_STATE_SYSTEM),
                idle: value(CPU_STATE_IDLE),
                nice: value(CPU_STATE_NICE)
            )
        }
        #else
        guard let text = try? String(contentsOfFile: "/proc/stat", encoding: .utf8) else { return nil }
        return parsePerCoreProcStat(text)
        #endif
    }

    /// User and system shares between two samples, each 0...1.
    public static func split(from earlier: CPUTicks, to later: CPUTicks) -> (user: Double, system: Double) {
        guard later.total > earlier.total, later.user >= earlier.user, later.system >= earlier.system,
              later.nice >= earlier.nice else { return (0, 0) }
        let total = Double(later.total - earlier.total)
        let user = Double((later.user - earlier.user) + (later.nice - earlier.nice)) / total
        let system = Double(later.system - earlier.system) / total
        return (min(user, 1), min(system, 1))
    }

    static func parsePerCoreProcStat(_ text: String) -> [CPUTicks] {
        text.split(separator: "\n")
            .filter { $0.hasPrefix("cpu") && !$0.hasPrefix("cpu ") }
            .compactMap { parseProcStat("cpu " + $0.split(separator: " ").dropFirst().joined(separator: " ")) }
    }

    /// Share of CPU time spent busy between two samples, 0...1.
    public static func usage(from earlier: CPUTicks, to later: CPUTicks) -> Double {
        // The kernel's counters are 32-bit on macOS and can wrap; treat that as no data.
        guard later.total > earlier.total, later.busy >= earlier.busy else { return 0 }
        let busy = Double(later.busy - earlier.busy)
        let total = Double(later.total - earlier.total)
        return min(max(busy / total, 0), 1)
    }

    static func parseProcStat(_ text: String) -> CPUTicks? {
        guard let line = text.split(separator: "\n").first(where: { $0.hasPrefix("cpu ") }) else { return nil }
        let fields = line.split(separator: " ").dropFirst().compactMap { UInt64($0) }
        guard fields.count >= 4 else { return nil }
        // /proc/stat order: user nice system idle ...
        return CPUTicks(user: fields[0], system: fields[2], idle: fields[3], nice: fields[1])
    }
}
