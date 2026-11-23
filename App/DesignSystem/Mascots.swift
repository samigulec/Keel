import SwiftUI

/// Refined architectural SF Symbol badges representing each Keel domain.
/// Replaces decorative cartoons with crisp, high-trust macOS utility iconography.
struct Mascot: View {
    enum Character {
        case kee, puf, zip, roket, blok, kutu, bilge
    }

    let character: Character
    var size: CGFloat = 32

    var body: some View {
        let style = Self.style(for: character)
        let radius = size * 0.28
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [style.primary.opacity(0.22), style.secondary.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [style.primary.opacity(0.38), style.secondary.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            Image(systemName: style.symbol)
                .font(.system(size: size * 0.46, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    LinearGradient(
                        colors: [style.primary, style.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private struct Style {
        let symbol: String
        let primary: Color
        let secondary: Color
    }

    private static func style(for character: Character) -> Style {
        switch character {
        case .kee:
            Style(symbol: "checkmark.shield.fill", primary: Color(hex: 0x34D399), secondary: Color(hex: 0x14B8A6))
        case .puf:
            Style(symbol: "sparkles", primary: Color(hex: 0x38BDF8), secondary: Color(hex: 0x3B82F6))
        case .zip:
            Style(symbol: "waveform.path.ecg", primary: Color(hex: 0xFBBF24), secondary: Color(hex: 0xF97316))
        case .roket:
            Style(symbol: "bolt.fill", primary: Color(hex: 0x34D399), secondary: Color(hex: 0x22D3EE))
        case .blok:
            Style(symbol: "square.grid.2x2.fill", primary: Color(hex: 0x818CF8), secondary: Color(hex: 0x3B82F6))
        case .kutu:
            Style(symbol: "externaldrive.fill", primary: Color(hex: 0xF59E0B), secondary: Color(hex: 0xFB7185))
        case .bilge:
            Style(symbol: "wand.and.stars", primary: Color(hex: 0xA78BFA), secondary: Color(hex: 0x6366F1))
        }
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
        case .smartScan: "checkmark.shield"
        case .cleanup: "sparkles"
        case .performance: "waveform.path.ecg"
        case .optimization: "bolt"
        case .applications: "square.grid.2x2"
        case .largeFiles: "externaldrive"
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
}
