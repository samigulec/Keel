import AppKit
import SwiftUI

/// Raycast/Linear-style keyboard command palette (⌘K) for jumping to any section
/// or running safe, read-only navigation and scan triggers in milliseconds.
struct CommandPalette: View {
    struct Command: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let symbol: String
        let tint: Color
        let shortcut: String?
        let run: @MainActor () -> Void
    }

    let commands: [Command]
    let dismiss: () -> Void

    @State private var query = ""
    @State private var selectedIndex = 0
    @FocusState private var searchFocused: Bool

    private var filtered: [Command] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return commands }
        return commands.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.subtitle.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.slate)
                    TextField("Bölüm veya eylem ara…", text: $query)
                        .textFieldStyle(.plain)
                        .font(.keel(15, .medium))
                        .foregroundStyle(Palette.text)
                        .focused($searchFocused)
                        .onSubmit { executeSelected() }
                    ShortcutCap(text: "ESC")
                }
                .padding(.horizontal, 16)
                .frame(height: 50)

                Divider().overlay(Palette.divider)

                if filtered.isEmpty {
                    Text("\"\(query)\" ile eşleşen komut yok.")
                        .font(.keel(13, .medium))
                        .foregroundStyle(Palette.slate)
                        .frame(maxWidth: .infinity, minHeight: 88)
                } else {
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, command in
                                PaletteRow(command: command, isSelected: index == selectedIndex) {
                                    dismiss()
                                    command.run()
                                }
                            }
                        }
                        .padding(8)
                    }
                    .frame(maxHeight: 340)
                }
            }
            .frame(width: 520)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Palette.borderHighlight, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.55), radius: 34, y: 18)
            .padding(.bottom, 80)
        }
        .onAppear { searchFocused = true }
        .onChange(of: query) { _, _ in selectedIndex = 0 }
        .onKeyPress(.upArrow) {
            if !filtered.isEmpty { selectedIndex = max(selectedIndex - 1, 0) }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if !filtered.isEmpty { selectedIndex = min(selectedIndex + 1, filtered.count - 1) }
            return .handled
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }

    private func executeSelected() {
        guard filtered.indices.contains(selectedIndex) else { return }
        let command = filtered[selectedIndex]
        dismiss()
        command.run()
    }
}

private struct PaletteRow: View {
    let command: CommandPalette.Command
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(command.tint.opacity(0.16))
                    Image(systemName: command.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(command.tint)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text(command.title)
                        .font(.keel(13.5, .bold))
                        .foregroundStyle(Palette.text)
                    Text(command.subtitle)
                        .font(.keel(11.5, .medium))
                        .foregroundStyle(Palette.slate)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                if let shortcut = command.shortcut {
                    ShortcutCap(text: shortcut)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 42)
            .background(
                isSelected ? Palette.Sidebar.selectedBackground : (isHovered ? Palette.mist : .clear),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? Palette.Sidebar.selectedBorder : .clear, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
