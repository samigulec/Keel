import Foundation
#if os(macOS)
import KeelSystemShims
#endif

/// What Keel asks of the fans.
public enum FanSetting: Equatable, Sendable {
    /// macOS decides, as it does by default.
    case automatic
    /// Every fan at a share of its top speed, never below its own minimum.
    case fixed(percent: Int)

    public static let percentRange = 1...100

    /// "auto" or "75", as the privileged command takes it.
    public var argument: String {
        switch self {
        case .automatic: "auto"
        case .fixed(let percent): String(percent)
        }
    }

    public init?(argument: String) {
        if argument == "auto" {
            self = .automatic
        } else if argument.allSatisfy(\.isASCII), let percent = Int(argument), Self.percentRange.contains(percent) {
            self = .fixed(percent: percent)
        } else {
            return nil
        }
    }
}

/// The arithmetic behind fan control, kept apart from the hardware so it can
/// be tested anywhere.
public enum FanMath {
    /// The speed for a share of the fan's maximum, raised to its minimum;
    /// nil when the limits are missing or implausible.
    public static func target(percent: Int, minimum: Double, maximum: Double) -> Double? {
        guard FanSetting.percentRange.contains(percent),
              minimum.isFinite, maximum.isFinite, minimum >= 0, maximum > 0, minimum <= maximum else { return nil }
        return max(maximum * Double(percent) / 100, minimum)
    }

    /// The SMC's bytes for a number of the given type, the reverse of
    /// `SMCValue.decode`.
    public static func encode(_ value: Double, type: String) -> [UInt8]? {
        guard value.isFinite, value >= 0 else { return nil }
        switch type {
        case "flt ":
            let bits = Float(value).bitPattern
            return [UInt8(bits & 0xFF), UInt8(bits >> 8 & 0xFF), UInt8(bits >> 16 & 0xFF), UInt8(bits >> 24)]
        case "fpe2":
            guard value * 4 <= Double(UInt16.max) else { return nil }
            let raw = UInt16(value * 4)
            return [UInt8(raw >> 8), UInt8(raw & 0xFF)]
        case "ui8 ":
            guard value <= Double(UInt8.max) else { return nil }
            return [UInt8(value)]
        case "ui16":
            guard value <= Double(UInt16.max) else { return nil }
            let raw = UInt16(value)
            return [UInt8(raw >> 8), UInt8(raw & 0xFF)]
        default:
            return nil
        }
    }
}

public struct FanControlResult: Equatable, Sendable {
    public let succeeded: Bool
    /// What happened, one line per fan or problem, for the user.
    public let lines: [String]
}

/// Changes the fans through the SMC. Writing needs root, so Keel runs this
/// in a separate process started through macOS's administrator prompt.
///
/// The keys differ by chip: the M5 takes the mode as `F0md`, M1–M4 as
/// `F0Md` (M3 and M4 only once `Ftst` asks the system to let go), Intel
/// as a bit per fan in `FS! `. Any failure while switching to a fixed
/// speed puts every fan back on automatic.
public enum FanController {
    public static func apply(_ setting: FanSetting, settle: TimeInterval = 4) -> FanControlResult {
        #if os(macOS)
        guard let smc = SMC() else { return FanControlResult(succeeded: false, lines: ["SMC açılamadı."]) }
        defer { smc.close() }
        let count = Int(smc.number("FNum") ?? 0)
        guard (1...9).contains(count) else {
            return FanControlResult(succeeded: false, lines: [count == 0 ? "Bu Mac'te fan yok." : "Beklenmeyen fan sayısı: \(count)."])
        }
        switch setting {
        case .automatic:
            return automatic(smc, fans: count, settle: settle)
        case .fixed(let percent):
            return fixed(smc, fans: count, percent: percent, settle: settle)
        }
        #else
        return FanControlResult(succeeded: false, lines: ["Fan kontrolü yalnızca macOS'te çalışır."])
        #endif
    }

    #if os(macOS)
    private static func fixed(_ smc: SMC, fans: Int, percent: Int, settle: TimeInterval) -> FanControlResult {
        // Work out every target before touching anything.
        var targets: [Double] = []
        for fan in 0..<fans {
            guard let minimum = smc.number("F\(fan)Mn"), let maximum = smc.number("F\(fan)Mx"),
                  let target = FanMath.target(percent: percent, minimum: minimum, maximum: maximum) else {
                return FanControlResult(succeeded: false, lines: ["Fan \(fan + 1): hız sınırları okunamadı, hiçbir şey değişmedi."])
            }
            targets.append(target)
        }

        var unlocked = false
        for (fan, target) in targets.enumerated() {
            var manual = setManual(smc, fan: fan, true)
            if !manual, smc.raw("Ftst") != nil {
                // M3 and M4: the system keeps the fans until asked to let go,
                // and takes a few seconds to do so.
                if !unlocked { unlocked = smc.write("Ftst", 1) }
                let deadline = Date().addingTimeInterval(10)
                while unlocked, !manual, Date() < deadline {
                    Thread.sleep(forTimeInterval: 0.5)
                    manual = setManual(smc, fan: fan, true)
                }
            }
            guard manual, smc.write("F\(fan)Tg", target) else {
                restoreAutomatic(smc, fans: fans)
                return FanControlResult(succeeded: false, lines: ["Fan \(fan + 1): macOS elle kontrole izin vermedi; fanlar otomatiğe döndü."])
            }
        }

        Thread.sleep(forTimeInterval: settle)
        var lines: [String] = []
        var held = true
        for (fan, target) in targets.enumerated() {
            if let mode = mode(smc, fan: fan), !mode {
                held = false
                lines.append("Fan \(fan + 1): macOS kontrolü geri aldı.")
            } else {
                let actual = smc.number("F\(fan)Ac").map { " (şu an \(Int($0)))" } ?? ""
                lines.append("Fan \(fan + 1): hedef \(Int(target)) dev/dk\(actual).")
            }
        }
        if !held { restoreAutomatic(smc, fans: fans) }
        return FanControlResult(succeeded: held, lines: lines)
    }

    private static func automatic(_ smc: SMC, fans: Int, settle: TimeInterval) -> FanControlResult {
        let stuck = restoreAutomatic(smc, fans: fans)
        Thread.sleep(forTimeInterval: min(settle, 1))
        let stillManual = (0..<fans).filter { mode(smc, fan: $0) == true }
        let problems = Set(stuck + stillManual).sorted()
        guard problems.isEmpty else {
            return FanControlResult(
                succeeded: false,
                lines: problems.map { "Fan \($0 + 1) hâlâ elle kontrolde; tekrar dene ya da Mac'i yeniden başlat." }
            )
        }
        return FanControlResult(succeeded: true, lines: ["Fanlar yeniden macOS'in kontrolünde."])
    }

    /// Puts every fan back on automatic; returns the fans that refused.
    @discardableResult
    private static func restoreAutomatic(_ smc: SMC, fans: Int) -> [Int] {
        let refused = (0..<fans).filter { !setManual(smc, fan: $0, false) }
        if let gate = smc.number("Ftst"), gate != 0 { smc.write("Ftst", 0) }
        return refused
    }

    private static func modeKey(_ smc: SMC, fan: Int) -> String? {
        ["F\(fan)md", "F\(fan)Md"].first { smc.raw($0) != nil }
    }

    /// True when the fan is held at a fixed speed; nil when the Mac does not say.
    private static func mode(_ smc: SMC, fan: Int) -> Bool? {
        if let key = modeKey(smc, fan: fan) { return smc.number(key).map { $0 != 0 } }
        if let mask = smc.number("FS! ") { return Int(mask) & (1 << fan) != 0 }
        return nil
    }

    private static func setManual(_ smc: SMC, fan: Int, _ manual: Bool) -> Bool {
        if let key = modeKey(smc, fan: fan) {
            return smc.write(key, manual ? 1 : 0)
        }
        // Intel: one bit per fan.
        guard let current = smc.number("FS! ") else { return false }
        let mask = manual ? Int(current) | (1 << fan) : Int(current) & ~(1 << fan)
        return smc.write("FS! ", Double(mask))
    }
    #endif
}

/// Reads the fans' mode for the screens, without changing anything.
public enum FanModeReader {
    /// Indices of the fans held at a fixed speed.
    public static func manualFans() -> Set<Int> {
        #if os(macOS)
        guard let smc = SMC() else { return [] }
        defer { smc.close() }
        let count = min(Int(smc.number("FNum") ?? 0), 9)
        return Set((0..<count).filter { fan in
            for key in ["F\(fan)md", "F\(fan)Md"] {
                if let value = smc.number(key) { return value != 0 }
            }
            if let mask = smc.number("FS! ") { return Int(mask) & (1 << fan) != 0 }
            return false
        })
        #else
        return []
        #endif
    }
}

#if os(macOS)
/// A connection to the System Management Controller.
struct SMC {
    let connection: io_connect_t

    init?() {
        let connection = keel_smc_open()
        guard connection != 0 else { return nil }
        self.connection = connection
    }

    func close() {
        keel_smc_close(connection)
    }

    func raw(_ key: String) -> (type: String, bytes: [UInt8])? {
        var value = keel_smc_value()
        guard key.withCString({ keel_smc_read(connection, $0, &value) }) == 0 else { return nil }
        let type = withUnsafeBytes(of: value.type) { String(decoding: $0.prefix(4), as: UTF8.self) }
        let bytes = withUnsafeBytes(of: value.bytes) { Array($0.prefix(Int(value.size))) }
        return (type, bytes)
    }

    func number(_ key: String) -> Double? {
        raw(key).flatMap { SMCValue.decode(type: $0.type, bytes: $0.bytes) }
    }

    /// Writes a number in the key's own type and size.
    @discardableResult
    func write(_ key: String, _ value: Double) -> Bool {
        guard let current = raw(key),
              let bytes = FanMath.encode(value, type: current.type),
              bytes.count == current.bytes.count else { return false }
        return key.withCString { name in
            bytes.withUnsafeBufferPointer { keel_smc_write(connection, name, $0.baseAddress, UInt32($0.count)) }
        } == 0
    }
}
#endif
