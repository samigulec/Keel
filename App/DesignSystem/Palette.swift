import AppKit
import SwiftUI

/// Refined obsidian-slate palette with architectural emerald accents and
/// per-module atmospheric tints inspired by classic macOS maintenance tools.
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
    static let navy = Color(hex: 0x090D14)
    /// Subtle control fills: chips, segmented buttons, inline icon buttons.
    static let mist = Color.white.opacity(0.06)
    static let mistHover = Color.white.opacity(0.10)

    // Surfaces (3-tier elevation)
    static let card = Color(hex: 0x111824).opacity(0.84)
    static let cardHover = Color(hex: 0x172030).opacity(0.92)
    static let border = Color.white.opacity(0.085)
    static let borderHighlight = LinearGradient(
        colors: [Color.white.opacity(0.16), Color.white.opacity(0.045)],
        startPoint: .top,
        endPoint: .bottom
    )
    static let controlBorder = Color.white.opacity(0.14)
    static let divider = Color.white.opacity(0.07)
    static let track = Color.white.opacity(0.095)
    /// Opaque elevated surface for popovers, menus, and sheets.
    static let raised = Color(hex: 0x121926)

    // Semantic tints
    static let mint = Color(hex: 0x34D399).opacity(0.14)
    static let mintText = Color(hex: 0x6EE7B7)
    static let warning = Color(hex: 0xF59E0B)
    static let warningText = Color(hex: 0xFBBF24)
    static let warningTint = Color(hex: 0xF59E0B).opacity(0.14)
    static let danger = Color(hex: 0xF87171)
    static let dangerTint = Color(hex: 0xF87171).opacity(0.14)
    static let info = Color(hex: 0x38BDF8)

    // Gradients (luminous, desktop-native)
    static let accent = LinearGradient(
        colors: [Color(hex: 0x34D399), Color(hex: 0x0EA5A4)],
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
    /// Highlighted summary panels — calm emerald-teal glass over deep slate.
    static let summary = LinearGradient(
        colors: [Color(hex: 0x0E2B2A).opacity(0.92), Color(hex: 0x111E2F).opacity(0.94)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let summaryBorder = Color(hex: 0x34D399).opacity(0.30)

    enum Sidebar {
        static let text = Color(hex: 0xCBD5E1)
        static let selectedBackground = Color.white.opacity(0.10)
        static let selectedBorder = Color.white.opacity(0.14)
        static let hoverBackground = Color.white.opacity(0.055)
        static let background = Color(hex: 0x0B1018).opacity(0.68)
        static let widgetBackground = Color.white.opacity(0.055)
        static let widgetTrack = Color.white.opacity(0.12)
        static let eyebrow = Color(hex: 0x6EE7B7)
    }
}

/// Native macOS `NSVisualEffectView` wrapper so sidebars, popovers, and
/// overlays pick up genuine desktop vibrancy.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .followsWindowActiveState

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
    }
}

/// Atmospheric dark canvas that gently adapts its ambient glow to the active
/// module — giving each section a subtle signature mood like CleanMyMac.
struct KeelBackground: View {
    var accent: Color = Palette.keelGreen

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let span = max(size.width, size.height)
            ZStack {
                Palette.navy
                // Signature top-center module aura
                RadialGradient(
                    colors: [accent.opacity(0.17), accent.opacity(0.04), .clear],
                    center: UnitPoint(x: 0.56, y: -0.08),
                    startRadius: 20,
                    endRadius: span * 0.62
                )
                // Cool slate-blue counterweight on the far right
                RadialGradient(
                    colors: [Color(hex: 0x1D4ED8).opacity(0.13), .clear],
                    center: UnitPoint(x: 0.96, y: 0.88),
                    startRadius: 10,
                    endRadius: span * 0.52
                )
                // Subtle teal anchor bottom-left
                RadialGradient(
                    colors: [Color(hex: 0x0D9488).opacity(0.11), .clear],
                    center: UnitPoint(x: 0.12, y: 1.05),
                    startRadius: 0,
                    endRadius: span * 0.45
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
