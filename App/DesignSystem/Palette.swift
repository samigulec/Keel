import SwiftUI

/// Refined dark obsidian-slate palette with architectural emerald accents.
/// Pinned to dark appearance so native macOS controls stay cohesive.
enum Palette {
    // Text
    static let text = Color(hex: 0xF1F5F9)
    /// Secondary labels and captions.
    static let slate = Color(hex: 0x8FA1B5)
    /// Body copy under titles, slightly higher contrast than labels.
    static let subtle = Color(hex: 0xCBD5E1)
    /// Muted metadata and keyboard shortcut hints.
    static let muted = Color(hex: 0x64748B)
    /// High-contrast ink on bright accent buttons.
    static let onAccent = Color(hex: 0x04130F)

    // Brand
    static let keelGreen = Color(hex: 0x34D399)
    static let navy = Color(hex: 0x0A0E14)
    /// Subtle control fills: chips, segmented buttons, inline icon buttons.
    static let mist = Color.white.opacity(0.055)
    static let mistHover = Color.white.opacity(0.095)

    // Surfaces (3-tier elevation)
    static let card = Color(hex: 0x111722).opacity(0.92)
    static let cardHover = Color(hex: 0x161E2C)
    static let border = Color.white.opacity(0.085)
    static let borderHighlight = LinearGradient(
        colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
        startPoint: .top,
        endPoint: .bottom
    )
    static let controlBorder = Color.white.opacity(0.13)
    static let divider = Color.white.opacity(0.065)
    static let track = Color.white.opacity(0.09)
    /// Opaque elevated surface for popovers, menus, and sheets.
    static let raised = Color(hex: 0x131A26)

    // Semantic tints
    static let mint = Color(hex: 0x34D399).opacity(0.13)
    static let mintText = Color(hex: 0x6EE7B7)
    static let warning = Color(hex: 0xF59E0B)
    static let warningText = Color(hex: 0xFBBF24)
    static let warningTint = Color(hex: 0xF59E0B).opacity(0.13)
    static let danger = Color(hex: 0xF87171)
    static let dangerTint = Color(hex: 0xF87171).opacity(0.13)
    static let info = Color(hex: 0x38BDF8)

    // Gradients (restrained, desktop-native)
    static let accent = LinearGradient(
        colors: [Color(hex: 0x34D399), Color(hex: 0x14B8A6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let accentBar = LinearGradient(
        colors: [Color(hex: 0x34D399), Color(hex: 0x38BDF8)],
        startPoint: .leading,
        endPoint: .trailing
    )
    /// Keel AI signature violet-indigo gradient.
    static let assistant = LinearGradient(
        colors: [Color(hex: 0x8B5CF6), Color(hex: 0x6366F1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    /// Subtle highlighted summary panels — calm emerald-slate, never loud neon.
    static let summary = LinearGradient(
        colors: [Color(hex: 0x0F2625), Color(hex: 0x111C2B)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let summaryBorder = Color(hex: 0x34D399).opacity(0.26)

    enum Sidebar {
        static let text = Color(hex: 0xCBD5E1)
        static let selectedBackground = Color(hex: 0x34D399).opacity(0.12)
        static let selectedBorder = Color(hex: 0x34D399).opacity(0.24)
        static let hoverBackground = Color.white.opacity(0.05)
        static let background = Color(hex: 0x0D121B).opacity(0.92)
        static let widgetBackground = Color.white.opacity(0.04)
        static let widgetTrack = Color.white.opacity(0.11)
        static let eyebrow = Color(hex: 0x6EE7B7)
    }
}

/// Calm obsidian-slate canvas with whisper-subtle atmospheric depth.
struct KeelBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Palette.navy
                RadialGradient(
                    colors: [Color(hex: 0x1E3A5F).opacity(0.22), .clear],
                    center: UnitPoint(x: 0.85, y: -0.05),
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.55
                )
                RadialGradient(
                    colors: [Color(hex: 0x0F4C46).opacity(0.18), .clear],
                    center: UnitPoint(x: 0.05, y: 1.05),
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.5
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
