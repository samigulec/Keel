import KeelCore
import SwiftUI

struct Sidebar: View {
    @Binding var selection: AppSection
    @Environment(SystemStatus.self) private var status

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(spacing: 10) {
                KeelLogoTile()
                Text("Keel")
                    .font(.keel(22, .extraBold))
                    .tracking(-0.4)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)

            VStack(spacing: 6) {
                ForEach(AppSection.allCases) { section in
                    SidebarItem(section: section, isSelected: section == selection) {
                        selection = section
                    }
                }
            }

            Spacer(minLength: 0)

            DiskWidget(disk: status.disk)
        }
        .padding(.horizontal, 16)
        .padding(.top, 52) // clears the window's traffic lights
        .padding(.bottom, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Palette.Sidebar.background)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Palette.divider).frame(width: 1)
        }
    }
}

private struct SidebarItem: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Mascot(character: section.mascot, size: 34)
                Text(section.title)
                    .font(.keel(15, isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? .white : Palette.Sidebar.text)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if section == .assistant {
                    Text("YENİ")
                        .font(.keel(11, .extraBold))
                        .foregroundStyle(Palette.onAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Palette.accentBar, in: Capsule())
                } else if section.phase > 1 {
                    Image(systemName: "clock")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.Sidebar.eyebrow)
                        .help("Yakında")
                        .accessibilityLabel("Yakında")
                }
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 48)
            .background(
                isSelected ? Palette.Sidebar.selectedBackground : .clear,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Palette.Sidebar.selectedBorder : .clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct DiskWidget: View {
    let disk: DiskSpace?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Disk")
                    .font(.keel(13, .semibold))
                    .foregroundStyle(Palette.Sidebar.text)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    ByteAmount(bytes: disk?.usedBytes, size: 13, color: .white)
                    Text("/")
                        .font(.keel(13, .semibold))
                        .foregroundStyle(Palette.Sidebar.text)
                    ByteAmount(bytes: disk?.totalBytes, size: 13, color: .white)
                }
            }
            ProgressBar(
                fraction: disk?.usedFraction ?? 0,
                track: Palette.Sidebar.widgetTrack,
                height: 6
            )
        }
        .padding(16)
        .background(Palette.Sidebar.widgetBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.border)
        }
        .accessibilityElement(children: .combine)
    }
}
