import KeelCore
import SwiftUI

// MARK: - Surfaces

struct CardModifier: ViewModifier {
    var padding: CGFloat
    var radius: CGFloat
    var fill: Color

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                if fill == Palette.card {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Palette.border)
                }
            }
    }
}

/// The highlighted panel: teal to blue, raised off the ground.
struct SummaryCardModifier: ViewModifier {
    var padding: CGFloat
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.summary, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18))
            }
            .shadow(color: .black.opacity(0.35), radius: 30, y: 18)
    }
}

extension View {
    func keelCard(padding: CGFloat = 24, radius: CGFloat = 22, fill: Color = Palette.card) -> some View {
        modifier(CardModifier(padding: padding, radius: radius, fill: fill))
    }

    func keelSummaryCard(padding: CGFloat = 24, radius: CGFloat = 22) -> some View {
        modifier(SummaryCardModifier(padding: padding, radius: radius))
    }
}

// MARK: - Buttons

/// Dims a button when it is disabled; ButtonStyle cannot read the environment itself.
private struct EnabledAware<Content: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    @ViewBuilder var content: Content

    var body: some View {
        content.opacity(isEnabled ? 1 : 0.45)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        EnabledAware {
            configuration.label
                .font(.keel(16, .extraBold))
                .foregroundStyle(Palette.onAccent)
                .padding(.horizontal, 28)
                .frame(minHeight: 52)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Palette.keelGreen.opacity(0.35), radius: 14, y: 8)
                .opacity(configuration.isPressed ? 0.85 : 1)
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        EnabledAware {
            configuration.label
                .font(.keel(16, .bold))
                .foregroundStyle(Palette.text)
                .padding(.horizontal, 22)
                .frame(minHeight: 52)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.controlBorder)
                }
                .opacity(configuration.isPressed ? 0.85 : 1)
        }
    }
}

/// The full-width accent button on summary panels, e.g. "Temizle".
struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        EnabledAware {
            configuration.label
                .font(.keel(17, .extraBold))
                .foregroundStyle(Palette.onAccent)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Palette.keelGreen.opacity(0.4), radius: 15, y: 12)
                .opacity(configuration.isPressed ? 0.85 : 1)
        }
    }
}

extension ButtonStyle where Self == AccentButtonStyle {
    static var keelAccent: AccentButtonStyle { AccentButtonStyle() }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var keelPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var keelSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Indicators

struct ProgressBar: View {
    var fraction: Double
    /// nil, or Keel Green, draws the mint-to-cyan accent.
    var tint: Color? = nil
    var track: Color = Palette.track
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Group {
                    if let tint, tint != Palette.keelGreen {
                        Capsule().fill(tint)
                    } else {
                        Capsule().fill(Palette.accentBar)
                    }
                }
                .frame(width: proxy.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityValue(Text(verbatim: "%\(Int((fraction * 100).rounded()))"))
    }
}

/// A byte count as the design sets it: the number in JetBrains Mono, the unit
/// in Manrope, so monospaced spacing does not leave a wide gap before "GB".
struct ByteAmount: View {
    var bytes: Int64?
    var size: CGFloat
    var color: Color = Palette.text
    var base: ByteFormat.Base = .decimal

    var body: some View {
        if let bytes {
            let parts = ByteFormat.parts(bytes, base: base)
            HStack(alignment: .firstTextBaseline, spacing: size * 0.18) {
                // Monospaced digits leave a wide gap around the comma at large sizes.
                Text(parts.value).font(.keelMono(size, .semibold)).tracking(-size * 0.06)
                Text(parts.unit).font(.keel(size * 0.8, .bold))
            }
            .foregroundStyle(color)
            .accessibilityElement(children: .combine)
        } else {
            Text("—").font(.keelMono(size, .semibold)).foregroundStyle(color)
        }
    }
}

struct Pill: View {
    var text: String
    var background: Color = Palette.mint
    var foreground: Color = Palette.mintText

    var body: some View {
        Text(text)
            .font(.keel(12, .extraBold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background, in: Capsule())
    }
}

// MARK: - Layout

struct PageHeader: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.keel(36, .bold))
                .tracking(-1)
                .foregroundStyle(Palette.text)
            Text(subtitle)
                .font(.keel(16, .medium))
                .foregroundStyle(Palette.subtle)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Responsive layout

extension EnvironmentValues {
    /// True when the content area is narrow, e.g. beside the Keel AI panel
    /// or in a small window; screens stack their columns then.
    @Entry var compactLayout = false
}
