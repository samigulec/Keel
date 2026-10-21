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

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Disk").eyebrowStyle()
                    Spacer()
                    Text(status.disk.map { "\(ByteFormat.string($0.availableBytes)) boş" } ?? "—")
                        .font(.keelMono(13, .semibold))
                        .foregroundStyle(Palette.hull)
                }
                ProgressBar(fraction: status.disk?.usedFraction ?? 0, tint: Palette.keelGreen, height: 6)
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
