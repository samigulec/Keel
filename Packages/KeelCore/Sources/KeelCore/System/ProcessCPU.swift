import Foundation

#if canImport(Darwin)
import Darwin
#endif

/// CPU time a process has used so far, for working out its share between
/// two readings, like Activity Monitor's "% CPU" column.
public struct ProcessCPUTime: Equatable, Sendable {
    public let pid: Int32
    public let name: String
    /// User plus system time, in nanoseconds.
    public let nanoseconds: UInt64

    public init(pid: Int32, name: String, nanoseconds: UInt64) {
        self.pid = pid
        self.name = name
        self.nanoseconds = nanoseconds
    }
}

public struct ProcessCPUUsage: Identifiable, Equatable, Sendable {
    public var id: Int32 { pid }
    public let pid: Int32
    public let name: String
    /// Share of one core: 1.0 is a core fully busy, so it can exceed 1.
    public let coreFraction: Double

    public init(pid: Int32, name: String, coreFraction: Double) {
        self.pid = pid
        self.name = name
        self.coreFraction = coreFraction
    }
}

public enum ProcessCPU {
    /// Every process the current user may inspect.
    public static func sample() -> [ProcessCPUTime] {
        #if os(macOS)
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        // Task times are in Mach ticks, which are not nanoseconds on Apple silicon.
        let scale = Double(timebase.numer) / Double(max(timebase.denom, 1))

        let capacity = Int(proc_listallpids(nil, 0)) + 64
        guard capacity > 64 else { return [] }
        var pids = [pid_t](repeating: 0, count: capacity)
        let found = Int(proc_listallpids(&pids, Int32(capacity * MemoryLayout<pid_t>.stride)))

        return pids.prefix(max(found, 0)).compactMap { pid in
            guard pid > 0 else { return nil }
            var info = proc_taskinfo()
            let size = Int32(MemoryLayout<proc_taskinfo>.stride)
            guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, size) == size else { return nil }

            var buffer = [CChar](repeating: 0, count: 256)
            proc_name(pid, &buffer, UInt32(buffer.count))
            let name = String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
            let ticks = Double(info.pti_total_user + info.pti_total_system)
            return ProcessCPUTime(pid: pid, name: name.isEmpty ? "pid \(pid)" : name, nanoseconds: UInt64(ticks * scale))
        }
        #else
        return []
        #endif
    }

    /// The busiest processes between two samples taken `elapsed` apart.
    /// Processes that started in between are measured from zero; ones that
    /// ended are left out.
    public static func usage(
        from old: [ProcessCPUTime],
        to new: [ProcessCPUTime],
        elapsed: Duration,
        limit: Int = 8
    ) -> [ProcessCPUUsage] {
        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        guard seconds > 0 else { return [] }
        let before = Dictionary(old.map { ($0.pid, $0.nanoseconds) }, uniquingKeysWith: { first, _ in first })

        return new
            .compactMap { process -> ProcessCPUUsage? in
                let start = before[process.pid] ?? 0
                guard process.nanoseconds > start else { return nil }
                let fraction = Double(process.nanoseconds - start) / 1e9 / seconds
                return ProcessCPUUsage(pid: process.pid, name: process.name, coreFraction: fraction)
            }
            .sorted { $0.coreFraction > $1.coreFraction }
            .prefix(limit)
            .map { $0 }
    }
}
