import AppKit
import KeelCore
import SwiftUI

struct MenuBarContent: View {
    @Environment(SystemStatus.self) private var status
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                KeelLogoTile(size: 26)
                Text("Keel")
                    .font(.keel(17, .extraBold))
                    .foregroundStyle(Palette.text)
            }

            StatRow(title: "İşlemci", fraction: status.cpuUsage) {
                Text(status.cpuUsage.map { "%\(Int(($0 * 100).rounded()))" } ?? "—")
                    .font(.keelMono(13, .semibold))
                    .foregroundStyle(Palette.text)
            }
            StatRow(title: "Bellek", fraction: status.memory?.usedFraction) {
                ByteAmount(bytes: status.memory.map { Int64($0.usedBytes) }, size: 13, base: .binary)
            }
            StatRow(title: "Disk", fraction: status.disk?.usedFraction) {
                ByteAmount(bytes: status.disk?.availableBytes, size: 13)
                Text("boş")
                    .font(.keel(13, .semibold))
                    .foregroundStyle(Palette.slate)
            }

            if let thermals = status.thermals, let hottest = thermals.summary(.cpu)?.hottest ?? thermals.summaries.map(\.hottest).max() {
                HStack(spacing: 4) {
                    Text("Sıcaklık").eyebrowStyle()
                    Spacer()
                    Text(thermalText(hottest, fans: thermals.fans))
                        .font(.keelMono(12, .semibold))
                        .foregroundStyle(Thermal.color(hottest))
                }
                .accessibilityElement(children: .combine)
            }

            HStack(spacing: 4) {
                Text("Ağ").eyebrowStyle()
                Spacer()
                Text(networkText)
                    .font(.keelMono(12, .semibold))
                    .foregroundStyle(Palette.text)
            }
            .accessibilityElement(children: .combine)

            Divider()

            Button("Keel'i aç") {
                openWindow(id: KeelApp.mainWindowID)
                NSApp.activate()
            }
            .buttonStyle(.keelPrimary)
            .frame(maxWidth: .infinity)

            Button("Çıkış") { NSApp.terminate(nil) }
                .buttonStyle(.plain)
                .font(.keel(13, .semibold))
                .foregroundStyle(Palette.slate)
                .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(width: 260)
        .background(Palette.raised)
        .preferredColorScheme(.dark)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(title).eyebrowStyle()
                Spacer()
                value
            }
            ProgressBar(fraction: fraction ?? 0, tint: Palette.keelGreen, height: 6)
        }
        .accessibilityElement(children: .combine)
    }
}
