import Foundation

#if canImport(Darwin)
import Darwin
#endif

/// Facts about the Mac that do not change while Keel runs.
public struct SystemInfo: Equatable, Sendable {
    /// e.g. "Apple M2 Pro"
    public let chipName: String?
    /// e.g. "Mac14,9"
    public let modelIdentifier: String?
    public let logicalCores: Int
    /// Apple silicon only: performance and efficiency core counts.
    public let performanceCores: Int?
    public let efficiencyCores: Int?
    public let physicalMemoryBytes: UInt64
    /// e.g. "Version 15.1 (Build 24B83)"
    public let osVersion: String

    public static func current() -> SystemInfo {
        SystemInfo(
            chipName: sysctlString("machdep.cpu.brand_string"),
            modelIdentifier: sysctlString("hw.model"),
            logicalCores: ProcessInfo.processInfo.activeProcessorCount,
            performanceCores: sysctlInt("hw.perflevel0.logicalcpu"),
            efficiencyCores: sysctlInt("hw.perflevel1.logicalcpu"),
            physicalMemoryBytes: ProcessInfo.processInfo.physicalMemory,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString
        )
    }

    /// 1, 5 and 15 minute load averages: runnable threads, not a percentage.
    public static func loadAverages() -> [Double]? {
        var loads = [Double](repeating: 0, count: 3)
        return getloadavg(&loads, 3) == 3 ? loads : nil
    }

    static func sysctlString(_ name: String) -> String? {
        #if os(macOS)
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        let value = String(cString: buffer).trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
        #else
        nil
        #endif
    }

    static func sysctlInt(_ name: String) -> Int? {
        #if os(macOS)
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
        return Int(value)
        #else
        nil
        #endif
    }
}
