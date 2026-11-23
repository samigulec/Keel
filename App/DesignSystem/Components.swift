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
                        .strokeBorder(Palette.borderHighlight, lineWidth: 1)
                } else {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Palette.border, lineWidth: 1)
                }
            }
    }
}

/// Highlighted summary panel: deep emerald-slate surface with a refined emerald hairline.
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
                    .strokeBorder(Palette.summaryBorder, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
    }
}

extension View {
    func keelCard(padding: CGFloat = 20, radius: CGFloat = 16, fill: Color = Palette.card) -> some View {
        modifier(CardModifier(padding: padding, radius: radius, fill: fill))
    }

    func keelSummaryCard(padding: CGFloat = 20, radius: CGFloat = 16) -> some View {
        modifier(SummaryCardModifier(padding: padding, radius: radius))
    }
}

// MARK: - Buttons

/// Dims a button when disabled and tracks pointer hover for crisp desktop feedback.
private struct InteractiveButtonShell<Content: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    @ViewBuilder var content: (_ isHovered: Bool) -> Content

    var body: some View {
        content(isHovered && isEnabled)
            .opacity(isEnabled ? 1 : 0.42)
            .onHover { isHovered = $0 }
            .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        InteractiveButtonShell { hovered in
            configuration.label
                .font(.keel(13.5, .bold))
                .foregroundStyle(Palette.onAccent)
                .padding(.horizontal, 18)
                .frame(minHeight: 36)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(hovered ? 0.35 : 0.18), lineWidth: 1)
                }
                .brightness(hovered ? 0.05 : 0)
                .shadow(color: Palette.keelGreen.opacity(hovered ? 0.28 : 0.16), radius: 10, y: 4)
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
                .opacity(configuration.isPressed ? 0.9 : 1)
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        InteractiveButtonShell { hovered in
            configuration.label
                .font(.keel(13.5, .semibold))
                .foregroundStyle(Palette.text)
                .padding(.horizontal, 15)
                .frame(minHeight: 36)
                .background(
                    hovered ? Palette.mistHover : Palette.mist,
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(hovered ? Color.white.opacity(0.20) : Palette.controlBorder, lineWidth: 1)
                }
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
                .opacity(configuration.isPressed ? 0.85 : 1)
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

/// Full-width primary action button inside summary panels (e.g. "Temizle").
struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        InteractiveButtonShell { hovered in
            configuration.label
                .font(.keel(14.5, .bold))
                .foregroundStyle(Palette.onAccent)
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Color.white.opacity(hovered ? 0.35 : 0.18), lineWidth: 1)
                }
                .brightness(hovered ? 0.05 : 0)
                .shadow(color: Palette.keelGreen.opacity(hovered ? 0.30 : 0.18), radius: 12, y: 5)
                .scaleEffect(configuration.isPressed ? 0.99 : 1)
                .opacity(configuration.isPressed ? 0.9 : 1)
                .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
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
    /// nil, or Keel Green, draws the emerald-to-sky accent.
    var tint: Color? = nil
    var track: Color = Palette.track
    var height: CGFloat = 6

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

/// Bars over a faint track, so the chart reads even when values are low.
struct Sparkline: View {
    let values: [Double]
    /// The value that fills a bar; nil scales to the largest value shown.
    var maxValue: Double? = 1
    var tint: Color = Palette.keelGreen
    var height: CGFloat = 56

    var body: some View {
        let padded = Array(repeating: 0.0, count: max(SystemStatus.historyLength - values.count, 0)) + values
        let scale = maxValue ?? max(padded.max() ?? 0, 1)
        GeometryReader { proxy in
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(padded.enumerated()), id: \.offset) { index, value in
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Palette.track.opacity(0.6))
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(index == padded.count - 1 ? tint : tint.opacity(0.45))
                            .frame(height: max(2, proxy.size.height * min(value / scale, 1)))
                    }
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// A byte count formatted with tabular JetBrains Mono digits and Manrope units.
struct ByteAmount: View {
    var bytes: Int64?
    var size: CGFloat
    var color: Color = Palette.text
    var base: ByteFormat.Base = .decimal

    var body: some View {
        if let bytes {
            let parts = ByteFormat.parts(bytes, base: base)
            HStack(alignment: .firstTextBaseline, spacing: size * 0.16) {
                Text(parts.value).font(.keelMono(size, .semibold)).tracking(-size * 0.05)
                Text(parts.unit).font(.keel(size * 0.78, .bold))
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
            .font(.keel(11, .bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 3.5)
            .background(background, in: Capsule())
            .overlay {
                Capsule().strokeBorder(foreground.opacity(0.22), lineWidth: 1)
            }
    }
}

/// Subtle keyboard shortcut badge (`⌘K`, `⌘1`) for desktop polish.
struct ShortcutCap: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.keelMono(10.5, .medium))
            .foregroundStyle(Palette.muted)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            }
    }
}

// MARK: - Layout

struct PageHeader: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.keel(24, .extraBold))
                .tracking(-0.5)
                .foregroundStyle(Palette.text)
            Text(subtitle)
                .font(.keel(13.5, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Narrow content area, e.g. when the Keel AI companion panel is open beside it.
extension EnvironmentValues {
    @Entry var compactLayout = false
}
