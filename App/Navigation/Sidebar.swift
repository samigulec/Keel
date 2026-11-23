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
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Self.groups) { group in
                        VStack(alignment: .leading, spacing: 2) {
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
        .background(Palette.Sidebar.background)
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
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected ? section.accentColor.opacity(0.18) : Color.white.opacity(isHovered ? 0.08 : 0.04))
                    Image(systemName: section.symbolName)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? section.accentColor : (isHovered ? Palette.text : Palette.slate))
                }
                .frame(width: 26, height: 26)

                Text(section.title)
                    .font(.keel(13.5, isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? Palette.text : (isHovered ? Palette.text : Palette.Sidebar.text))
                    .lineLimit(1)

                Spacer(minLength: 4)

                if isHovered || isSelected {
                    Text("⌘\(shortcutNumber)")
                        .font(.keelMono(10, .medium))
                        .foregroundStyle(isSelected ? Palette.mintText.opacity(0.8) : Palette.muted)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 36)
            .background(
                isSelected ? Palette.Sidebar.selectedBackground : (isHovered ? Palette.Sidebar.hoverBackground : .clear),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? Palette.Sidebar.selectedBorder : .clear, lineWidth: 1)
            }
            .overlay(alignment: .leading) {
                if isSelected {
                    Capsule()
                        .fill(section.accentColor)
                        .frame(width: 3, height: 16)
                        .padding(.leading, 2)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Compact glanceable live system card at the bottom of the sidebar.
private struct SystemPulseWidget: View {
    let status: SystemStatus
    let openPerformance: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: openPerformance) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    metricChip(
                        label: "CPU",
                        value: status.cpuUsage.map { "%\(Int(($0 * 100).rounded()))" } ?? "—",
                        tint: (status.cpuUsage ?? 0) > 0.8 ? Palette.warningText : Palette.mintText
                    )
                    metricChip(
                        label: "RAM",
                        value: status.memory.map { "%\(Int(($0.usedFraction * 100).rounded()))" } ?? "—",
                        tint: status.memory?.pressure == .normal ? Palette.info : Palette.warningText
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Disk")
                            .font(.keel(11.5, .semibold))
                            .foregroundStyle(Palette.slate)
                        Spacer()
                        if let disk = status.disk {
                            Text("\(ByteFormat.string(disk.availableBytes)) boş")
                                .font(.keelMono(11, .semibold))
                                .foregroundStyle(Palette.text)
                        } else {
                            Text("—")
                                .font(.keelMono(11, .semibold))
                                .foregroundStyle(Palette.slate)
                        }
                    }
                    ProgressBar(
                        fraction: status.disk?.usedFraction ?? 0,
                        tint: (status.disk?.usedFraction ?? 0) > 0.88 ? Palette.warning : nil,
                        track: Palette.Sidebar.widgetTrack,
                        height: 5
                    )
                }
            }
            .padding(12)
            .background(
                isHovered ? Palette.mistHover : Palette.Sidebar.widgetBackground,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isHovered ? Color.white.opacity(0.14) : Palette.border, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .help("Performans ekranını aç")
        .accessibilityElement(children: .combine)
    }

    private func metricChip(label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Circle().fill(tint).frame(width: 6, height: 6)
            Text(label)
                .font(.keel(10.5, .bold))
                .foregroundStyle(Palette.slate)
            Spacer(minLength: 2)
            Text(value)
                .font(.keelMono(11, .semibold))
                .foregroundStyle(Palette.text)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

private struct SettingsFooterButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
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
