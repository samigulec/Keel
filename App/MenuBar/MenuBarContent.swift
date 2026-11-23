import AppKit
import KeelCore
import SwiftUI

struct MenuBarContent: View {
    @Environment(SystemStatus.self) private var status
    @Environment(\.openWindow) private var openWindow

    private static let networkInColor = Color(hex: 0x4FD8F5)
    private static let networkOutColor = Color(hex: 0xA08BFF)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                KeelLogoTile(size: 22)
                Text("Keel")
                    .font(.keel(14.5, .extraBold))
                    .tracking(-0.2)
                    .foregroundStyle(Palette.text)
                Spacer()
                if let temp = status.thermals?.summary(.cpu)?.hottest ?? status.thermals?.summaries.map(\.hottest).max() {
                    Text(Thermal.degrees(temp))
                        .font(.keelMono(11, .semibold))
                        .foregroundStyle(Thermal.color(temp))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Thermal.color(temp).opacity(0.14), in: Capsule())
                }
            }

            // iStat Menus / CleanMyMac Menu glanceable 3-ring strip
            HStack(spacing: 0) {
                ringStat(
                    title: "CPU",
                    fraction: status.cpuUsage ?? 0,
                    label: status.cpuUsage.map { "%\(Int(($0 * 100).rounded()))" } ?? "—",
                    tint: (status.cpuUsage ?? 0) > 0.8 ? Palette.warning : Palette.keelGreen
                )
                ringStat(
                    title: "RAM",
                    fraction: status.memory?.usedFraction ?? 0,
                    label: status.memory.map { "%\(Int(($0.usedFraction * 100).rounded()))" } ?? "—",
                    tint: status.memory?.pressure == .normal ? Palette.info : Palette.warning
                )
                ringStat(
                    title: "Disk",
                    fraction: status.disk?.usedFraction ?? 0,
                    label: status.disk.map { "%\(Int(($0.usedFraction * 100).rounded()))" } ?? "—",
                    tint: (status.disk?.usedFraction ?? 0) > 0.88 ? Palette.warning : Color(hex: 0xA78BFA)
                )
            }
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Palette.border, lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 5) {
                StatRow(title: "İşlemci", fraction: status.cpuUsage) {
                    Text(status.cpuUsage.map { "%\(Int(($0 * 100).rounded()))" } ?? "—")
                        .font(.keelMono(12.5, .semibold))
                        .foregroundStyle(Palette.text)
                }
                Sparkline(values: status.cpuHistory, height: 20)
                Text("son 1 dk")
                    .font(.keel(10, .medium))
                    .foregroundStyle(Palette.muted)
            }

            StatRow(title: "Bellek", fraction: status.memory?.usedFraction) {
                ByteAmount(bytes: status.memory.map { Int64($0.usedBytes) }, size: 12.5, base: .binary)
            }
            StatRow(title: "Disk", fraction: status.disk?.usedFraction) {
                ByteAmount(bytes: status.disk?.availableBytes, size: 12.5)
                Text("boş")
                    .font(.keel(12, .semibold))
                    .foregroundStyle(Palette.slate)
            }

            if let thermals = status.thermals, let hottest = thermals.summary(.cpu)?.hottest ?? thermals.summaries.map(\.hottest).max() {
                HStack(spacing: 4) {
                    Text("Sıcaklık").eyebrowStyle()
                    Spacer()
                    Text(thermalText(hottest, fans: thermals.fans))
                        .font(.keelMono(11.5, .semibold))
                        .foregroundStyle(Thermal.color(hottest))
                }
                .accessibilityElement(children: .combine)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Text("Ağ").eyebrowStyle()
                    Spacer()
                    Text(networkText)
                        .font(.keelMono(11.5, .semibold))
                        .foregroundStyle(Palette.text)
                }
                .accessibilityElement(children: .combine)

                let networkScale = max((status.networkInHistory + status.networkOutHistory).max() ?? 0, 1)
                VStack(spacing: 3) {
                    Sparkline(values: status.networkInHistory, maxValue: networkScale, tint: Self.networkInColor, height: 16)
                    Sparkline(values: status.networkOutHistory, maxValue: networkScale, tint: Self.networkOutColor, height: 16)
                }
                Text("son 1 dk")
                    .font(.keel(10, .medium))
                    .foregroundStyle(Palette.muted)
            }

            Divider().overlay(Palette.divider)

            HStack(spacing: 8) {
                Button("Keel'i aç") {
                    openWindow(id: KeelApp.mainWindowID)
                    NSApp.activate()
                }
                .buttonStyle(.keelPrimary)
                .frame(maxWidth: .infinity)

                Button("Çıkış") { NSApp.terminate(nil) }
                    .buttonStyle(.keelSecondary)
            }
        }
        .padding(14)
        .frame(width: 260)
        .background {
            ZStack {
                VisualEffectBackground(material: .popover, blendingMode: .behindWindow)
                Palette.raised.opacity(0.76)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func ringStat(title: String, fraction: Double, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            CircularGauge(
                fraction: fraction,
                tint: tint,
                lineWidth: 4.5,
                size: 42,
                centerText: label
            )
            Text(title)
                .font(.keel(10, .bold))
                .foregroundStyle(Palette.slate)
        }
        .frame(maxWidth: .infinity)
    }

    /// "52 °C · 1.800 dev/dk"
    private func thermalText(_ celsius: Double, fans: [FanReading]) -> String {
        guard let fastest = fans.map(\.rpm).max(), fastest >= 1 else { return Thermal.degrees(celsius) }
        return "\(Thermal.degrees(celsius)) · \(Int(fastest.rounded())) dev/dk"
    }

    /// "↓ 1,2 MB/sn  ↑ 80 KB/sn"
    private var networkText: String {
        guard let rate = status.networkRate else { return "—" }
        func speed(_ value: Double) -> String {
            value < 1_000 ? "\(Int(value)) B/sn" : ByteFormat.string(Int64(value)) + "/sn"
        }
        return "↓ \(speed(rate.receivedPerSecond))  ↑ \(speed(rate.sentPerSecond))"
    }
}

private struct StatRow<Value: View>: View {
    let title: String
    let fraction: Double?
    @ViewBuilder var value: Value

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(title).eyebrowStyle()
                Spacer()
                value
            }
            ProgressBar(fraction: fraction ?? 0, tint: Palette.keelGreen, height: 5)
        }
        .accessibilityElement(children: .combine)
    }
}
