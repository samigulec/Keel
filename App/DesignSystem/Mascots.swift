import SwiftUI

/// Vibrant macOS System Settings / CleanMyMac-style filled gradient icon medallions.
/// Crisp white SF Symbols over saturated gradient squircles with subtle glass sheen.
struct Mascot: View {
    enum Character {
        case kee, puf, zip, roket, blok, kutu, bilge
    }

    let character: Character
    var size: CGFloat = 32

    var body: some View {
        let style = Self.style(for: character)
        IconMedallion(
            symbol: style.symbol,
            colors: [style.primary, style.secondary],
            size: size
        )
    }

    private struct Style {
        let symbol: String
        let primary: Color
        let secondary: Color
    }

    private static func style(for character: Character) -> Style {
        switch character {
        case .kee:
            Style(symbol: "checkmark.shield.fill", primary: Color(hex: 0x34D399), secondary: Color(hex: 0x0D9488))
        case .puf:
            Style(symbol: "sparkles", primary: Color(hex: 0x38BDF8), secondary: Color(hex: 0x2563EB))
        case .zip:
            Style(symbol: "waveform.path.ecg", primary: Color(hex: 0xFBBF24), secondary: Color(hex: 0xEA580C))
        case .roket:
            Style(symbol: "bolt.fill", primary: Color(hex: 0x2DD4BF), secondary: Color(hex: 0x0284C7))
        case .blok:
            Style(symbol: "square.grid.2x2.fill", primary: Color(hex: 0x818CF8), secondary: Color(hex: 0x4F46E5))
        case .kutu:
            Style(symbol: "externaldrive.fill", primary: Color(hex: 0xFB923C), secondary: Color(hex: 0xE11D48))
        case .bilge:
            Style(symbol: "wand.and.stars", primary: Color(hex: 0xA78BFA), secondary: Color(hex: 0x6366F1))
        }
    }
}

/// Reusable filled gradient squircle icon tile used across sidebar items,
/// cleanup categories, empty states, and section heroes.
struct IconMedallion: View {
    let symbol: String
    let colors: [Color]
    var size: CGFloat = 32
    var symbolScale: CGFloat = 0.46
    var filled: Bool = true

    var body: some View {
        let radius = size * 0.27
        let primary = colors.first ?? Palette.keelGreen
        let secondary = colors.last ?? primary
        ZStack {
            if filled {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [primary, secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                // Soft top specular sheen like macOS app icons
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.28), Color.white.opacity(0.02), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.40), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.9
                    )
                Image(systemName: symbol)
                    .font(.system(size: size * symbolScale, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.22), radius: 1.5, y: 1)
            } else {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(primary.opacity(0.15))
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(primary.opacity(0.24), lineWidth: 0.9)
                Image(systemName: symbol)
                    .font(.system(size: size * symbolScale, weight: .semibold))
                    .foregroundStyle(primary)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: filled ? primary.opacity(0.28) : .clear, radius: size * 0.18, y: size * 0.08)
        .accessibilityHidden(true)
    }
}

extension AppSection {
    var mascot: Mascot.Character {
        switch self {
        case .smartScan: .kee
        case .cleanup: .puf
        case .performance: .zip
        case .optimization: .roket
        case .applications: .blok
        case .largeFiles: .kutu
        case .assistant: .bilge
        }
    }

    var symbolName: String {
        switch self {
        case .smartScan: "checkmark.shield.fill"
        case .cleanup: "sparkles"
        case .performance: "waveform.path.ecg"
        case .optimization: "bolt.fill"
        case .applications: "square.grid.2x2.fill"
        case .largeFiles: "externaldrive.fill"
        case .assistant: "wand.and.stars"
        }
    }

    var accentColor: Color {
        switch self {
        case .smartScan: Color(hex: 0x34D399)
        case .cleanup: Color(hex: 0x38BDF8)
        case .performance: Color(hex: 0xFBBF24)
        case .optimization: Color(hex: 0x2DD4BF)
        case .applications: Color(hex: 0x818CF8)
        case .largeFiles: Color(hex: 0xFB923C)
        case .assistant: Color(hex: 0xA78BFA)
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .smartScan: [Color(hex: 0x34D399), Color(hex: 0x0D9488)]
        case .cleanup: [Color(hex: 0x38BDF8), Color(hex: 0x2563EB)]
        case .performance: [Color(hex: 0xFBBF24), Color(hex: 0xEA580C)]
        case .optimization: [Color(hex: 0x2DD4BF), Color(hex: 0x0284C7)]
        case .applications: [Color(hex: 0x818CF8), Color(hex: 0x4F46E5)]
        case .largeFiles: [Color(hex: 0xFB923C), Color(hex: 0xE11D48)]
        case .assistant: [Color(hex: 0xA78BFA), Color(hex: 0x6366F1)]
        }
    }
}
