import AppKit
import SwiftUI

/// Spotlight / Raycast-style keyboard command palette (⌘K) with native macOS vibrancy.
struct CommandPalette: View {
    struct Command: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let symbol: String
        let colors: [Color]
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
            Color.black.opacity(0.52)
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
                .frame(height: 52)

                Divider().overlay(Palette.divider)

                if filtered.isEmpty {
                    Text("\"\(query)\" ile eşleşen komut yok.")
                        .font(.keel(13, .medium))
                        .foregroundStyle(Palette.slate)
                        .frame(maxWidth: .infinity, minHeight: 88)
                } else {
                    ScrollView {
                        VStack(spacing: 3) {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, command in
                                PaletteRow(command: command, isSelected: index == selectedIndex) {
                                    dismiss()
                                    command.run()
                                }
                            }
                        }
                        .padding(8)
                    }
                    .frame(maxHeight: 350)
                }
            }
            .frame(width: 530)
            .background {
                ZStack {
                    VisualEffectBackground(material: .hudWindow, blendingMode: .withinWindow)
                    Color(hex: 0x0E1522).opacity(0.82)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Palette.borderHighlight, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.58), radius: 36, y: 18)
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
        let accent = command.colors.first ?? Palette.keelGreen
        Button(action: action) {
            HStack(spacing: 12) {
                IconMedallion(
                    symbol: command.symbol,
                    colors: command.colors,
                    size: 28,
                    symbolScale: 0.46,
                    filled: isSelected || isHovered
                )

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
            .frame(height: 44)
            .background(
                isSelected ? accent.opacity(0.16) : (isHovered ? Palette.mist : .clear),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? accent.opacity(0.32) : .clear, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
