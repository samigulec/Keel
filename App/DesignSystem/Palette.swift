import SwiftUI

/// Colors from the Keel design canvas: a deep navy ground with soft teal
/// and blue light, glass cards and mint-to-cyan accents. The window pins
/// the dark appearance so system controls match.
enum Palette {
    // Text
    static let text = Color.white
    /// Secondary text and labels.
    static let slate = Color(hex: 0xA9C2CF)
    /// Body copy under titles, a step brighter than labels.
    static let subtle = Color(hex: 0xBFD3DC)
    /// Text and marks on the bright accent gradient.
    static let onAccent = Color(hex: 0x04121C)

    // Brand
    static let keelGreen = Color(hex: 0x2FE0A0)
    static let navy = Color(hex: 0x071423)
    /// Light fills: chips, rows, inactive segments.
    static let mist = Color.white.opacity(0.07)

    // Surfaces
    static let card = Color.white.opacity(0.06)
    static let border = Color.white.opacity(0.10)
    static let controlBorder = Color.white.opacity(0.16)
    static let divider = Color.white.opacity(0.08)
    static let track = Color.white.opacity(0.12)
    /// Opaque surface for menus and windows without the ground behind them.
    static let raised = Color(hex: 0x0D2135)

    // Tints
    static let mint = Color(hex: 0x2FE0A0).opacity(0.16)
    static let mintText = Color(hex: 0x7EF0C8)
    static let warning = Color(hex: 0xF0A23B)
    static let warningText = Color(hex: 0xFFC46B)
    static let warningTint = Color(hex: 0xFFC46B).opacity(0.16)
    static let danger = Color(hex: 0xFF8A80)
    static let info = Color(hex: 0x4FD8F5)

    // Gradients
    static let accent = LinearGradient(colors: [Color(hex: 0x5FF5C0), Color(hex: 0x22C7E8)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let accentBar = LinearGradient(colors: [Color(hex: 0x5FF5C0), Color(hex: 0x4FD8F5)], startPoint: .leading, endPoint: .trailing)
    /// Keel AI's own color.
    static let assistant = LinearGradient(colors: [Color(hex: 0xA08BFF), Color(hex: 0x4C8DF6)], startPoint: .topLeading, endPoint: .bottomTrailing)
    /// Highlighted summary panels, e.g. what a cleanup will free.
    static let summary = LinearGradient(colors: [Color(hex: 0x0B6E6A), Color(hex: 0x1B4F9C)], startPoint: .topLeading, endPoint: .bottomTrailing)

    // Text and tracks on the highlighted summary panels
    enum Sidebar {
        static let text = Color(hex: 0xD6E4EA)
        static let selectedBackground = Color.white.opacity(0.10)
        static let selectedBorder = Color.white.opacity(0.14)
        static let background = Color.white.opacity(0.04)
        static let widgetBackground = Color.white.opacity(0.06)
        static let widgetTrack = Color.white.opacity(0.18)
        static let eyebrow = Color(hex: 0xC9F5E6)
    }
}

/// The window's ground: navy with teal and blue light from opposite corners.
struct KeelBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Palette.navy
                RadialGradient(
                    colors: [Color(hex: 0x12407F), Color(hex: 0x12407F).opacity(0)],
                    center: UnitPoint(x: 0.8, y: -0.1),
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.6
                )
                RadialGradient(
                    colors: [Color(hex: 0x0F5C5A), Color(hex: 0x0F5C5A).opacity(0)],
                    center: UnitPoint(x: 0, y: 1.1),
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.55
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
