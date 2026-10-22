import SwiftUI

/// Colors from the Keel design canvas. The design is light-only for now,
/// so the main window pins the light appearance.
enum Palette {
    // Brand
    static let hull = Color(hex: 0x0F1A17)       // Deep Hull
    static let keelGreen = Color(hex: 0x2FBF8F)  // Keel Green
    static let mist = Color(hex: 0xF3F5F4)       // Mist, window background
    static let slate = Color(hex: 0x56635E)      // Slate, secondary text

    // Surfaces
    static let card = Color.white
    static let border = Color(hex: 0xE2E8E5)
    static let controlBorder = Color(hex: 0xDCE3E0)
    static let divider = Color(hex: 0xEDF1EF)
    static let track = Color(hex: 0xE6EEEA)

    // Tints
    static let mint = Color(hex: 0xE3F5EE)
    static let mintText = Color(hex: 0x0B6B53)
    static let warning = Color(hex: 0xC2570C)
    static let warningText = Color(hex: 0xA8480A)
    static let warningTint = Color(hex: 0xFDEEE3)
    static let danger = Color(hex: 0xB42318)

    // Sidebar (on Deep Hull)
    enum Sidebar {
        static let text = Color(hex: 0xB9C8C2)
        static let selectedBackground = Color(hex: 0x22352F)
        static let widgetBackground = Color(hex: 0x1A2B26)
        static let widgetTrack = Color(hex: 0x33463F)
        static let eyebrow = Color(hex: 0x9FD9C3)
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
