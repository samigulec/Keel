import Foundation

#if canImport(Darwin)
import Darwin
#endif

public struct ProcessSample: Equatable, Sendable {
    public let pid: Int32
    public let parentPID: Int32
    /// Physical footprint, the "Memory" column in Activity Monitor.
    public let footprintBytes: UInt64

    public init(pid: Int32, parentPID: Int32, footprintBytes: UInt64) {
        self.pid = pid
        self.parentPID = parentPID
        self.footprintBytes = footprintBytes
    }
}

public enum ProcessMemory {
    /// Every process the current user may inspect. Others are left out.
    public static func samples() -> [ProcessSample] {
        #if os(macOS)
        let capacity = Int(proc_listallpids(nil, 0)) + 64
        guard capacity > 64 else { return [] }
        var pids = [pid_t](repeating: 0, count: capacity)
        let found = Int(proc_listallpids(&pids, Int32(capacity * MemoryLayout<pid_t>.stride)))

        return pids.prefix(max(found, 0)).compactMap { pid in
            guard pid > 0 else { return nil }

            var info = proc_bsdinfo()
            let infoSize = Int32(MemoryLayout<proc_bsdinfo>.stride)
            guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, infoSize) == infoSize else { return nil }

            var usage = rusage_info_v4()
            let status = withUnsafeMutablePointer(to: &usage) {
                $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                    proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
                }
            }
            guard status == 0 else { return nil }
            return ProcessSample(pid: pid, parentPID: pid_t(info.pbi_ppid), footprintBytes: usage.ri_phys_footprint)
        }
        #else
        return []
        #endif
    }

    /// Footprint of each root process plus all of its descendants, so a
    /// browser's helper and renderer processes count towards the browser.
    public static func totals(for roots: Set<Int32>, in samples: [ProcessSample]) -> [Int32: UInt64] {
        let parentOf = Dictionary(samples.map { ($0.pid, $0.parentPID) }, uniquingKeysWith: { first, _ in first })
        var totals: [Int32: UInt64] = [:]

        for sample in samples {
            var current = sample.pid
            var hops = 0
            // Walk up until a root is found; launchd (pid 1) ends the search.
            while current > 1, hops < 64 {
                if roots.contains(current) {
                    totals[current, default: 0] += sample.footprintBytes
                    break
                }
                guard let parent = parentOf[current], parent != current else { break }
                current = parent
                hops += 1
            }
        }
        return totals
    }
}
