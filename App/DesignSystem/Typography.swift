import SwiftUI

/// Manrope for UI text, JetBrains Mono for numbers. Both ship in
/// Resources/Fonts and are registered through ATSApplicationFontsPath.
enum KeelWeight: String {
    case medium = "Manrope-Medium"
    case semibold = "Manrope-SemiBold"
    case bold = "Manrope-Bold"
    case extraBold = "Manrope-ExtraBold"
}

enum KeelMonoWeight: String {
    case medium = "JetBrainsMono-Medium"
    case semibold = "JetBrainsMono-SemiBold"
}

extension Font {
    static func keel(_ size: CGFloat, _ weight: KeelWeight = .semibold) -> Font {
        .custom(weight.rawValue, size: size)
    }

    static func keelMono(_ size: CGFloat, _ weight: KeelMonoWeight = .semibold) -> Font {
        .custom(weight.rawValue, size: size)
    }
}

extension View {
    /// Small uppercase label used above stat values ("DEPOLAMA").
    func eyebrowStyle(color: Color = Palette.slate) -> some View {
        font(.keel(12, .bold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}
