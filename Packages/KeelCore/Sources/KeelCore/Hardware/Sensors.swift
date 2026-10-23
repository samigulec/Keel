import Foundation

#if os(macOS)
import IOKit
import KeelSystemShims
#endif

/// Where a temperature sensor sits, so readings can be summed up per part.
public enum SensorGroup: String, CaseIterable, Sendable {
    case cpu, gpu, soc, ssd, battery, other
}

public struct TemperatureSensor: Identifiable, Equatable, Sendable {
    public var id: String { name }
    public let name: String
    public let celsius: Double
    public let group: SensorGroup

    public init(name: String, celsius: Double, group: SensorGroup) {
        self.name = name
        self.celsius = celsius
        self.group = group
    }
}

public struct TemperatureSummary: Equatable, Sendable {
    public let group: SensorGroup
    public let hottest: Double
    public let average: Double
    public let sensorCount: Int
}

public struct FanReading: Identifiable, Equatable, Sendable {
    public var id: Int { index }
    public let index: Int
    public let rpm: Double
    public let minimumRPM: Double?
    public let maximumRPM: Double?
    /// True when held at a fixed speed instead of macOS's automatic control.
    public let isManual: Bool

    public init(index: Int, rpm: Double, minimumRPM: Double?, maximumRPM: Double?, isManual: Bool = false) {
        self.index = index
        self.rpm = rpm
        self.minimumRPM = minimumRPM
        self.maximumRPM = maximumRPM
        self.isManual = isManual
    }

    /// How far between its slowest and fastest speed the fan runs, 0...1.
    public var fraction: Double? {
        guard let low = minimumRPM, let high = maximumRPM, high > low else { return nil }
        return min(max((rpm - low) / (high - low), 0), 1)
    }
}

public struct ThermalSnapshot: Equatable, Sendable {
    public let sensors: [TemperatureSensor]
    public let fans: [FanReading]
    /// False when the Mac reports no fan count, as on fanless MacBook Airs.
    public let hasFans: Bool

    public init(sensors: [TemperatureSensor], fans: [FanReading], hasFans: Bool) {
        self.sensors = sensors
        self.fans = fans
        self.hasFans = hasFans
    }

    /// Hottest and average reading per part, hottest parts first.
    public var summaries: [TemperatureSummary] {
        SensorGroup.allCases.compactMap { group in
            let values = sensors.filter { $0.group == group }.map(\.celsius)
            guard let hottest = values.max() else { return nil }
            return TemperatureSummary(group: group, hottest: hottest, average: values.reduce(0, +) / Double(values.count), sensorCount: values.count)
        }
    }

    public func summary(_ group: SensorGroup) -> TemperatureSummary? {
        summaries.first { $0.group == group }
    }
}

public enum SensorReader {
    /// Readings outside this range are disconnected or placeholder sensors.
    static let plausible: ClosedRange<Double> = 1...130

    public static func snapshot() -> ThermalSnapshot? {
        #if os(macOS)
        var sensors = hidTemperatures()
        let connection = keel_smc_open()
        defer { keel_smc_close(connection) }
        if sensors.isEmpty, connection != 0 {
            // Intel Macs report temperatures through the SMC instead.
            sensors = smcTemperatures(connection)
        }
        let fanCount = connection != 0 ? smcValue(connection, "FNum").map { Int($0) } : nil
        let manual = fanCount.map { _ in FanModeReader.manualFans() } ?? []
        let fans = (0..<min(fanCount ?? 0, 8)).compactMap { index -> FanReading? in
            guard let rpm = smcValue(connection, "F\(index)Ac") else { return nil }
            return FanReading(
                index: index,
                rpm: rpm,
                minimumRPM: smcValue(connection, "F\(index)Mn"),
                maximumRPM: smcValue(connection, "F\(index)Mx"),
                isManual: manual.contains(index)
            )
        }
        guard !sensors.isEmpty || fanCount != nil else { return nil }
        return ThermalSnapshot(sensors: sensors, fans: fans, hasFans: (fanCount ?? 0) > 0)
        #else
        return nil
        #endif
    }

    /// Sorts a sensor into a part by the name Apple gives it, e.g.
    /// "PMU tdie3" (CPU die), "GPU MTR Temp Sensor1", "NAND CH0 temp".
    static func group(for name: String) -> SensorGroup {
        let text = name.lowercased()
        if text.contains("gpu") { return .gpu }
        if text.contains("tdie") || text.contains("pacc") || text.contains("eacc") || text.contains("cpu") { return .cpu }
        if text.contains("nand") || text.contains("ssd") { return .ssd }
        if text.contains("battery") || text.contains("gas gauge") { return .battery }
        if text.contains("soc") || text.contains("pmu") { return .soc }
        return .other
    }

    /// Builds sensors from raw name and value pairs; calibration constants
    /// and implausible readings are dropped, duplicates averaged once.
    static func sensors(from readings: [(name: String, celsius: Double)]) -> [TemperatureSensor] {
        var seen: Set<String> = []
        return readings.compactMap { reading in
            let name = reading.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, !name.lowercased().contains("tcal"),
                  plausible.contains(reading.celsius), seen.insert(name).inserted else { return nil }
            return TemperatureSensor(name: name, celsius: reading.celsius, group: group(for: name))
        }
    }

    #if os(macOS)
    private static func hidTemperatures() -> [TemperatureSensor] {
        var buffer = [keel_temperature_reading](repeating: keel_temperature_reading(), count: 128)
        let count = Int(keel_read_temperature_sensors(&buffer, Int32(buffer.count)))
        let readings = buffer.prefix(max(count, 0)).map { reading -> (name: String, celsius: Double) in
            let name = withUnsafeBytes(of: reading.name) { raw in
                String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
            }
            return (name, reading.celsius)
        }
        return sensors(from: readings)
    }

    /// Common Intel SMC keys and what they measure.
    static let intelKeys: [(key: String, name: String)] = [
        ("TC0P", "CPU proximity"), ("TC0D", "CPU die"), ("TC0E", "CPU die (PECI)"), ("TC0F", "CPU die (filtered)"),
        ("TG0P", "GPU proximity"), ("TG0D", "GPU die"), ("TH0a", "SSD"), ("TB0T", "Battery"), ("Ts0P", "Palm rest"),
    ]

    private static func smcTemperatures(_ connection: io_connect_t) -> [TemperatureSensor] {
        sensors(from: intelKeys.compactMap { entry in
            smcValue(connection, entry.key).map { (entry.name, $0) }
        })
    }

    private static func smcValue(_ connection: io_connect_t, _ key: String) -> Double? {
        var value = keel_smc_value()
        guard key.withCString({ keel_smc_read(connection, $0, &value) }) == 0 else { return nil }
        let type = withUnsafeBytes(of: value.type) { raw in String(decoding: raw.prefix(4), as: UTF8.self) }
        let bytes = withUnsafeBytes(of: value.bytes) { raw in Array(raw.prefix(Int(value.size))) }
        return SMCValue.decode(type: type, bytes: bytes)
    }
    #endif
}

/// Decodes the SMC's data types.
public enum SMCValue {
    public static func decode(type: String, bytes: [UInt8]) -> Double? {
        func bigEndian(_ count: Int) -> UInt64? {
            guard bytes.count >= count else { return nil }
            return bytes.prefix(count).reduce(0) { $0 << 8 | UInt64($1) }
        }
        switch type {
        case "flt ":
            // Apple silicon: a little-endian 32-bit float.
            guard bytes.count >= 4 else { return nil }
            let bits = UInt32(bytes[0]) | UInt32(bytes[1]) << 8 | UInt32(bytes[2]) << 16 | UInt32(bytes[3]) << 24
            let value = Double(Float(bitPattern: bits))
            return value.isFinite ? value : nil
        case "fpe2":
            // Unsigned fixed point with 2 fraction bits, used for fan speeds on Intel.
            return bigEndian(2).map { Double($0) / 4 }
        case "sp78":
            // Signed fixed point with 8 fraction bits, used for temperatures on Intel.
            return bigEndian(2).map { Double(Int16(bitPattern: UInt16($0))) / 256 }
        // `map(Double.init)` would pick init(bitPattern:); convert the number itself.
        case "ui8 ": return bigEndian(1).map { Double($0) }
        case "ui16": return bigEndian(2).map { Double($0) }
        case "ui32": return bigEndian(4).map { Double($0) }
        default: return nil
        }
    }
}
