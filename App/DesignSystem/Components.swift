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

extension View {
    func keelCard(padding: CGFloat = 24, radius: CGFloat = 18, fill: Color = Palette.card) -> some View {
        modifier(CardModifier(padding: padding, radius: radius, fill: fill))
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
                .font(.keel(16, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .frame(minHeight: 52)
                .background(Palette.hull, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .opacity(configuration.isPressed ? 0.85 : 1)
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        EnabledAware {
            configuration.label
                .font(.keel(16, .bold))
                .foregroundStyle(Palette.hull)
                .padding(.horizontal, 22)
                .frame(minHeight: 52)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.controlBorder)
                }
                .opacity(configuration.isPressed ? 0.85 : 1)
        }
    }
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
    var tint: Color = Palette.hull
    var track: Color = Palette.track
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(tint)
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
    var color: Color = Palette.hull

    var body: some View {
        if let bytes {
            let parts = ByteFormat.parts(bytes)
            HStack(alignment: .firstTextBaseline, spacing: size * 0.18) {
                Text(parts.value).font(.keelMono(size, .semibold))
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
                .font(.keel(32, .extraBold))
                .tracking(-0.6)
                .foregroundStyle(Palette.hull)
            Text(subtitle)
                .font(.keel(15, .medium))
                .foregroundStyle(Palette.slate)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
