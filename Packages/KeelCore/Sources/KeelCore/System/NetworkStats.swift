import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Bytes received and sent since the Mac started, over its real network
/// interfaces (Wi-Fi, Ethernet, a phone's hotspot). Loopback and VPN tunnels
/// are left out so traffic is not counted twice.
public struct NetworkTotals: Equatable, Sendable {
    public var received: UInt64
    public var sent: UInt64

    public init(received: UInt64, sent: UInt64) {
        self.received = received
        self.sent = sent
    }
}

public struct NetworkRate: Equatable, Sendable {
    public let receivedPerSecond: Double
    public let sentPerSecond: Double

    /// Per-second rates between two readings; a counter that went backwards
    /// (an interface came and went) counts as no traffic.
    public init(from old: NetworkTotals, to new: NetworkTotals, seconds: Double) {
        let time = max(seconds, 0.001)
        receivedPerSecond = new.received >= old.received ? Double(new.received - old.received) / time : 0
        sentPerSecond = new.sent >= old.sent ? Double(new.sent - old.sent) / time : 0
    }
}

public struct NetworkAddress: Equatable, Sendable {
    public let interface: String
    public let address: String
}

public enum NetworkReader {
    /// Interfaces that carry the Mac's own traffic.
    static func countsInterface(_ name: String) -> Bool {
        name.hasPrefix("en") || name.hasPrefix("pdp_ip") || name.hasPrefix("eth") || name.hasPrefix("wl")
    }

    public static func totals() -> NetworkTotals? {
        #if os(macOS)
        // getifaddrs keeps 32-bit counters that wrap every 4 GB; the routing
        // sysctl's if_msghdr2 has 64-bit ones.
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var length = 0
        guard sysctl(&mib, UInt32(mib.count), nil, &length, nil, 0) == 0, length > 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: length)
        guard sysctl(&mib, UInt32(mib.count), &buffer, &length, nil, 0) == 0 else { return nil }

        var totals = NetworkTotals(received: 0, sent: 0)
        var offset = 0
        buffer.withUnsafeBytes { raw in
            while offset + MemoryLayout<if_msghdr>.size <= length {
                let header = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr.self)
                guard header.ifm_msglen > 0 else { break }
                if Int32(header.ifm_type) == RTM_IFINFO2, offset + MemoryLayout<if_msghdr2>.size <= length {
                    let info = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr2.self)
                    var name = [CChar](repeating: 0, count: Int(IF_NAMESIZE))
                    if if_indextoname(UInt32(info.ifm_index), &name) != nil {
                        let interface = String(decoding: name.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
                        if countsInterface(interface) {
                            totals.received += info.ifm_data.ifi_ibytes
                            totals.sent += info.ifm_data.ifi_obytes
                        }
                    }
                }
                offset += Int(header.ifm_msglen)
            }
        }
        return totals
        #else
        guard let text = try? String(contentsOfFile: "/proc/net/dev", encoding: .utf8) else { return nil }
        return parseProcNetDev(text)
        #endif
    }

    /// Linux: "  eth0: 1234 5 0 0 0 0 0 0 5678 9 ..." (received bytes first, sent bytes ninth).
    static func parseProcNetDev(_ text: String) -> NetworkTotals {
        var totals = NetworkTotals(received: 0, sent: 0)
        for line in text.split(separator: "\n") {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let name = line[..<colon].trimmingCharacters(in: .whitespaces)
            guard countsInterface(name) else { continue }
            let fields = line[line.index(after: colon)...].split(separator: " ").compactMap { UInt64($0) }
            guard fields.count >= 9 else { continue }
            totals.received += fields[0]
            totals.sent += fields[8]
        }
        return totals
    }

    /// The first IPv4 address on a counted interface, e.g. en0 192.168.1.20.
    public static func primaryAddress() -> NetworkAddress? {
        var first: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&first) == 0, let start = first else { return nil }
        defer { freeifaddrs(first) }

        var candidates: [NetworkAddress] = []
        var current: UnsafeMutablePointer<ifaddrs>? = start
        while let entry = current {
            defer { current = entry.pointee.ifa_next }
            guard let address = entry.pointee.ifa_addr, Int32(address.pointee.sa_family) == AF_INET else { continue }
            let name = String(cString: entry.pointee.ifa_name)
            guard countsInterface(name) else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let size = socklen_t(MemoryLayout<sockaddr_in>.size)
            guard getnameinfo(address, size, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 else { continue }
            let text = String(decoding: host.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
            candidates.append(NetworkAddress(interface: name, address: text))
        }
        // en0 is the built-in Wi-Fi or Ethernet on most Macs.
        return candidates.min { $0.interface < $1.interface }
    }
}
