import KeelCore
import SwiftUI

struct Sidebar: View {
    @Binding var selection: AppSection
    @Environment(SystemStatus.self) private var status
    @Environment(\.openSettings) private var openSettings

    private struct GroupSpec: Identifiable {
        let id: String
        let title: String?
        let sections: [AppSection]
    }

    private static let groups: [GroupSpec] = [
        GroupSpec(id: "overview", title: nil, sections: [.smartScan]),
        GroupSpec(id: "storage", title: "Depolama & Temizlik", sections: [.cleanup, .applications, .largeFiles]),
        GroupSpec(id: "system", title: "Sistem", sections: [.performance, .optimization]),
        GroupSpec(id: "ai", title: "Asistan", sections: [.assistant]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                KeelLogoTile(size: 30)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Keel")
                        .font(.keel(16.5, .extraBold))
                        .tracking(-0.3)
                        .foregroundStyle(Palette.text)
                    Text("macOS Bakım")
                        .font(.keel(10.5, .semibold))
                        .foregroundStyle(Palette.muted)
                }
            }
            .padding(.horizontal, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(Self.groups) { group in
                        VStack(alignment: .leading, spacing: 3) {
                            if let title = group.title {
                                Text(title)
                                    .font(.keel(10.5, .bold))
                                    .tracking(0.75)
                                    .textCase(.uppercase)
                                    .foregroundStyle(Palette.muted)
                                    .padding(.horizontal, 10)
                                    .padding(.bottom, 4)
                            }
                            ForEach(group.sections) { section in
                                SidebarItem(
                                    section: section,
                                    shortcutNumber: (AppSection.allCases.firstIndex(of: section) ?? 0) + 1,
                                    isSelected: section == selection
                                ) {
                                    selection = section
                                }
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.never)

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                SystemPulseWidget(status: status) {
                    selection = .performance
                }

                SettingsFooterButton {
                    openSettings()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 44) // clears traffic lights cleanly
        .padding(.bottom, 14)
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            ZStack {
                VisualEffectBackground(material: .sidebar, blendingMode: .behindWindow)
                Palette.Sidebar.background
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle().fill(Palette.divider).frame(width: 1)
        }
    }
}

private struct SidebarItem: View {
    let section: AppSection
    let shortcutNumber: Int
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                IconMedallion(
                    symbol: section.symbolName,
                    colors: section.gradientColors,
                    size: 25,
                    symbolScale: 0.48,
                    filled: isSelected || isHovered
                )

                Text(section.title)
                    .font(.keel(13.5, isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? Palette.text : (isHovered ? Palette.text : Palette.Sidebar.text))
                    .lineLimit(1)

                Spacer(minLength: 4)

                if isHovered || isSelected {
                    Text("⌘\(shortcutNumber)")
                        .font(.keelMono(10, .medium))
                        .foregroundStyle(isSelected ? section.accentColor.opacity(0.9) : Palette.muted)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 38)
            .background(
                isSelected
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [section.accentColor.opacity(0.18), Palette.Sidebar.selectedBackground],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    : AnyShapeStyle(isHovered ? Palette.Sidebar.hoverBackground : .clear),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? section.accentColor.opacity(0.32) : .clear, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.14), value: isHovered)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Compact Sensei / CleanMyMac-style live system dock at the bottom of the sidebar.
private struct SystemPulseWidget: View {
    let status: SystemStatus
    let openPerformance: () -> Void
    @State private var isHovered = false

    var body: some View {
        let diskUsed = status.disk?.usedFraction ?? 0
        let diskTint = diskUsed > 0.88 ? Palette.warning : Palette.keelGreen
        Button(action: openPerformance) {
            HStack(spacing: 12) {
                CircularGauge(
                    fraction: diskUsed,
                    tint: diskTint,
                    secondaryTint: diskUsed > 0.88 ? Palette.danger : Palette.info,
                    track: Palette.Sidebar.widgetTrack,
                    lineWidth: 5,
                    size: 46,
                    centerText: status.disk.map { "%\(Int(($0.usedFraction * 100).rounded()))" } ?? "—",
                    centerSubtitle: "SSD"
                )

                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Disk")
                            .font(.keel(10.5, .bold))
                            .foregroundStyle(Palette.muted)
                        if let disk = status.disk {
                            Text("\(ByteFormat.string(disk.availableBytes)) boş")
                                .font(.keelMono(12, .semibold))
                                .foregroundStyle(Palette.text)
                                .lineLimit(1)
                        } else {
                            Text("Ölçülüyor…")
                                .font(.keel(11.5, .medium))
                                .foregroundStyle(Palette.slate)
                        }
                    }

                    HStack(spacing: 8) {
                        miniStat(
                            label: "CPU",
                            value: status.cpuUsage.map { "%\(Int(($0 * 100).rounded()))" } ?? "—",
                            tint: (status.cpuUsage ?? 0) > 0.8 ? Palette.warningText : Palette.mintText
                        )
                        miniStat(
                            label: "RAM",
                            value: status.memory.map { "%\(Int(($0.usedFraction * 100).rounded()))" } ?? "—",
                            tint: status.memory?.pressure == .normal ? Palette.info : Palette.warningText
                        )
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(11)
            .background(
                isHovered ? Palette.mistHover : Palette.Sidebar.widgetBackground,
                in: RoundedRectangle(cornerRadius: 13, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(isHovered ? Color.white.opacity(0.16) : Palette.border, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.14), value: isHovered)
        .help("Performans ekranını aç")
        .accessibilityElement(children: .combine)
    }

    private func miniStat(label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(tint).frame(width: 5, height: 5)
            Text(label)
                .font(.keel(10, .bold))
                .foregroundStyle(Palette.muted)
            Text(value)
                .font(.keelMono(10.5, .semibold))
                .foregroundStyle(Palette.subtle)
        }
    }
}

private struct SettingsFooterButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(isHovered ? Palette.text : Palette.slate)
                Text("Ayarlar")
                    .font(.keel(12.5, .semibold))
                    .foregroundStyle(isHovered ? Palette.text : Palette.slate)
                Spacer()
                ShortcutCap(text: "⌘,")
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(isHovered ? Palette.Sidebar.hoverBackground : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}
