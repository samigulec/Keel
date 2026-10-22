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
                    .foregroundStyle(Palette.hull)
            }

            StatRow(title: "İşlemci", fraction: status.cpuUsage) {
                Text(status.cpuUsage.map { "%\(Int(($0 * 100).rounded()))" } ?? "—")
                    .font(.keelMono(13, .semibold))
                    .foregroundStyle(Palette.hull)
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
        .background(Palette.mist)
        .preferredColorScheme(.light)
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
