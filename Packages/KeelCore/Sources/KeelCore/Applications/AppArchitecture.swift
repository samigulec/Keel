import Foundation

/// Which processors an app's executable is built for, read from its Mach-O
/// header. Intel-only apps run through Rosetta on Apple silicon.
public enum AppArchitecture: String, Sendable, Hashable {
    case universal
    case appleSilicon
    case intel
    case unknown

    // Mach-O magic numbers and CPU types, from <mach-o/loader.h> and <mach/machine.h>.
    private static let fatMagic: UInt32 = 0xCAFE_BABE
    private static let fatMagic64: UInt32 = 0xCAFE_BABF
    private static let thinMagic64: UInt32 = 0xFEED_FACF
    private static let thinMagic32: UInt32 = 0xFEED_FACE
    private static let cpuARM64: UInt32 = 0x0100_000C
    private static let cpuX86_64: UInt32 = 0x0100_0007
    private static let cpuX86: UInt32 = 0x0000_0007

    /// Reads the start of the executable; a few kilobytes hold every header.
    public static func of(executable url: URL) -> AppArchitecture {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return .unknown }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: 4096) else { return .unknown }
        return of(header: data)
    }

    public static func of(header data: Data) -> AppArchitecture {
        let bytes = [UInt8](data)
        guard bytes.count >= 8 else { return .unknown }

        // Fat headers are big-endian; thin ones are in the CPU's byte order.
        let bigMagic = readUInt32(bytes, at: 0, bigEndian: true)
        let littleMagic = readUInt32(bytes, at: 0, bigEndian: false)

        var cpuTypes: [UInt32] = []
        if bigMagic == fatMagic || bigMagic == fatMagic64 {
            let count = Int(readUInt32(bytes, at: 4, bigEndian: true))
            // Each entry is 20 bytes (32-bit) or 32 bytes (64-bit); the CPU type comes first.
            let stride = bigMagic == fatMagic64 ? 32 : 20
            for index in 0..<min(count, 16) {
                let offset = 8 + index * stride
                guard offset + 4 <= bytes.count else { break }
                cpuTypes.append(readUInt32(bytes, at: offset, bigEndian: true))
            }
        } else if littleMagic == thinMagic64 || littleMagic == thinMagic32 {
            cpuTypes.append(readUInt32(bytes, at: 4, bigEndian: false))
        } else {
            return .unknown
        }

        let arm = cpuTypes.contains(cpuARM64)
        let intel = cpuTypes.contains(cpuX86_64) || cpuTypes.contains(cpuX86)
        switch (arm, intel) {
        case (true, true): return .universal
        case (true, false): return .appleSilicon
        case (false, true): return .intel
        case (false, false): return .unknown
        }
    }

    private static func readUInt32(_ bytes: [UInt8], at offset: Int, bigEndian: Bool) -> UInt32 {
        guard offset + 4 <= bytes.count else { return 0 }
        let slice = bytes[offset..<offset + 4]
        return slice.enumerated().reduce(UInt32(0)) { value, element in
            let shift = bigEndian ? (3 - element.offset) * 8 : element.offset * 8
            return value | UInt32(element.element) << UInt32(shift)
        }
    }
}
