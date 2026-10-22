import Foundation

public struct BatterySnapshot: Equatable, Sendable {
    /// Current charge, 0...1.
    public let charge: Double
    /// Full-charge capacity relative to the design capacity, 0...1.
    public let health: Double?
    public let cycleCount: Int?
    public let temperatureCelsius: Double?
    public let isCharging: Bool
    public let isPluggedIn: Bool
}

public enum BatteryReader {
    /// nil on Macs without a battery.
    public static func current() -> BatterySnapshot? {
        #if os(macOS)
        IORegistry.properties(ofServicesNamed: "AppleSmartBattery").first.flatMap(snapshot(from:))
        #else
        nil
        #endif
    }

    static func snapshot(from properties: [String: Any]) -> BatterySnapshot? {
        guard let current = ioNumber(properties["CurrentCapacity"]),
              let max = ioNumber(properties["MaxCapacity"]), max > 0 else { return nil }

        // Apple silicon reports charge in percent (MaxCapacity == 100) and the
        // real full-charge capacity as AppleRawMaxCapacity, in mAh like the design value.
        let fullCharge = ioNumber(properties["AppleRawMaxCapacity"]) ?? (max > 100 ? max : nil)
        let design = ioNumber(properties["DesignCapacity"])
        let health: Double? = if let fullCharge, let design, design > 0 {
            min(Double(fullCharge) / Double(design), 1)
        } else {
            nil
        }

        return BatterySnapshot(
            charge: min(Swift.max(Double(current) / Double(max), 0), 1),
            health: health,
            cycleCount: ioNumber(properties["CycleCount"]).map(Int.init),
            temperatureCelsius: ioNumber(properties["Temperature"]).map { Double($0) / 100 },
            isCharging: properties["IsCharging"] as? Bool ?? false,
            isPluggedIn: properties["ExternalConnected"] as? Bool ?? false
        )
    }
}
