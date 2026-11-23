import SwiftUI

/// Manrope for UI text, JetBrains Mono for metrics. Both ship in
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
        .custom(weight.rawValue, size: size).monospacedDigit()
    }
}

extension View {
    /// Crisp uppercase micro-label used above stat values and sidebar groups.
    func eyebrowStyle(color: Color = Palette.slate) -> some View {
        font(.keel(11, .bold))
            .tracking(0.85)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}
