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

            VStack(spacing: 4) {
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
        .background(Palette.hull)
    }
}

private struct SidebarItem: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: section.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? Palette.keelGreen : Palette.Sidebar.text)
                    .frame(width: 20)
                Text(section.title)
                    .font(.keel(15, isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? .white : Palette.Sidebar.text)
                Spacer(minLength: 4)
                if section.phase > 1 {
                    Text("YAKINDA")
                        .font(.keel(10, .extraBold))
                        .foregroundStyle(Palette.Sidebar.eyebrow)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Palette.Sidebar.widgetTrack, in: Capsule())
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(
                isSelected ? Palette.Sidebar.selectedBackground : .clear,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
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
                Text(usageText)
                    .font(.keelMono(13, .medium))
                    .foregroundStyle(.white)
            }
            ProgressBar(
                fraction: disk?.usedFraction ?? 0,
                tint: Palette.keelGreen,
                track: Palette.Sidebar.widgetTrack,
                height: 6
            )
        }
        .padding(16)
        .background(Palette.Sidebar.widgetBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var usageText: String {
        guard let disk else { return "—" }
        return "\(ByteFormat.string(disk.usedBytes)) / \(ByteFormat.string(disk.totalBytes))"
    }
}
