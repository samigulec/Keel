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
            .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
    }
}

/// Interactive clickable card that subtly brightens and lifts on pointer hover.
struct InteractiveCardModifier: ViewModifier {
    var padding: CGFloat
    var radius: CGFloat
    var accent: Color?
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isHovered ? Palette.cardHover : Palette.card,
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        isHovered
                            ? AnyShapeStyle((accent ?? Color.white).opacity(accent == nil ? 0.22 : 0.42))
                            : AnyShapeStyle(Palette.borderHighlight),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: (isHovered ? (accent ?? .black) : .black).opacity(isHovered ? 0.22 : 0.16),
                radius: isHovered ? 16 : 10,
                y: isHovered ? 8 : 5
            )
            .offset(y: isHovered ? -1.5 : 0)
            .onHover { isHovered = $0 }
            .animation(.easeOut(duration: 0.16), value: isHovered)
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

    func keelInteractiveCard(padding: CGFloat = 18, radius: CGFloat = 16, accent: Color? = nil) -> some View {
        modifier(InteractiveCardModifier(padding: padding, radius: radius, accent: accent))
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
            .animation(.easeOut(duration: 0.14), value: isHovered)
    }
}

/// CleanMyMac-inspired signature tactile pill CTA for hero scan & clean actions.
struct HeroPillButtonStyle: ButtonStyle {
    var colors: [Color] = [Color(hex: 0x34D399), Color(hex: 0x0EA5A4)]

    func makeBody(configuration: Configuration) -> some View {
        let primary = colors.first ?? Palette.keelGreen
        let secondary = colors.last ?? primary
        InteractiveButtonShell { hovered in
            configuration.label
                .font(.keel(15, .extraBold))
                .tracking(-0.15)
                .foregroundStyle(Palette.onAccent)
                .padding(.horizontal, 28)
                .frame(minHeight: 46)
                .background(
                    LinearGradient(colors: [primary, secondary], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(hovered ? 0.28 : 0.20), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
                .overlay {
                    Capsule()
                        .strokeBorder(Color.white.opacity(hovered ? 0.48 : 0.28), lineWidth: 1)
                }
                .brightness(hovered ? 0.05 : 0)
                .shadow(color: primary.opacity(hovered ? 0.48 : 0.30), radius: hovered ? 20 : 14, y: hovered ? 8 : 6)
                .scaleEffect(configuration.isPressed ? 0.97 : (hovered ? 1.015 : 1))
                .opacity(configuration.isPressed ? 0.92 : 1)
                .contentShape(Capsule())
        }
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
                        .strokeBorder(Color.white.opacity(hovered ? 0.38 : 0.20), lineWidth: 1)
                }
                .brightness(hovered ? 0.05 : 0)
                .shadow(color: Palette.keelGreen.opacity(hovered ? 0.32 : 0.18), radius: 10, y: 4)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
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
                        .strokeBorder(hovered ? Color.white.opacity(0.22) : Palette.controlBorder, lineWidth: 1)
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
                        .strokeBorder(Color.white.opacity(hovered ? 0.38 : 0.20), lineWidth: 1)
                }
                .brightness(hovered ? 0.05 : 0)
                .shadow(color: Palette.keelGreen.opacity(hovered ? 0.34 : 0.20), radius: 12, y: 5)
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
                .opacity(configuration.isPressed ? 0.9 : 1)
                .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
    }
}

extension ButtonStyle where Self == HeroPillButtonStyle {
    static var keelHeroPill: HeroPillButtonStyle { HeroPillButtonStyle() }
    static func keelHeroPill(colors: [Color]) -> HeroPillButtonStyle { HeroPillButtonStyle(colors: colors) }
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

// MARK: - Data Visualizations & Indicators

/// Sensei / Apple Watch-style circular ring gauge with smooth animated arc.
struct CircularGauge: View {
    var fraction: Double
    var tint: Color = Palette.keelGreen
    var secondaryTint: Color? = nil
    var track: Color = Palette.track
    var lineWidth: CGFloat = 6
    var size: CGFloat = 52
    var centerText: String? = nil
    var centerSubtitle: String? = nil

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        let endColor = secondaryTint ?? tint
        ZStack {
            Circle()
                .stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(clamped, clamped > 0 ? 0.02 : 0))
                .stroke(
                    LinearGradient(
                        colors: [tint, endColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.32), radius: lineWidth * 0.8)
                .animation(.easeOut(duration: 0.45), value: clamped)

            if let centerText {
                VStack(spacing: -1) {
                    Text(centerText)
                        .font(.keelMono(size * 0.25, .semibold))
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let centerSubtitle {
                        Text(centerSubtitle)
                            .font(.keel(max(8.5, size * 0.16), .bold))
                            .foregroundStyle(Palette.muted)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, lineWidth + 2)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityValue(Text(verbatim: "%\(Int((clamped * 100).rounded()))"))
    }
}

/// DaisyDisk / macOS Storage-style proportional horizontal breakdown bar with legend.
struct SegmentedBar: View {
    struct Segment: Identifiable {
        let id: String
        let title: String
        let value: Int64
        let color: Color
    }

    let segments: [Segment]
    var height: CGFloat = 11
    var showsLegend: Bool = true

    private var total: Int64 {
        segments.reduce(0) { $0 + max($1.value, 0) }
    }

    private var nonEmpty: [Segment] {
        segments.filter { $0.value > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { proxy in
                let gap: CGFloat = 2
                let count = nonEmpty.count
                let usable = max(0, proxy.size.width - CGFloat(max(count - 1, 0)) * gap)
                HStack(spacing: gap) {
                    if total > 0 {
                        ForEach(nonEmpty) { segment in
                            let share = Double(segment.value) / Double(total)
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(segment.color)
                                .frame(width: max(4, usable * share))
                                .help("\(segment.title): \(ByteFormat.string(segment.value))")
                        }
                    } else {
                        Capsule().fill(Palette.track)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.track, in: Capsule())
                .clipShape(Capsule())
            }
            .frame(height: height)
            .accessibilityHidden(true)

            if showsLegend, !nonEmpty.isEmpty {
                FlowLayout(spacing: 12) {
                    ForEach(nonEmpty) { segment in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(segment.color)
                                .frame(width: 8, height: 8)
                            Text(segment.title)
                                .font(.keel(12, .semibold))
                                .foregroundStyle(Palette.subtle)
                            Text(ByteFormat.string(segment.value))
                                .font(.keelMono(11.5, .medium))
                                .foregroundStyle(Palette.slate)
                        }
                    }
                }
            }
        }
    }
}

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
                .animation(.easeOut(duration: 0.35), value: fraction)
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityValue(Text(verbatim: "%\(Int((fraction * 100).rounded()))"))
    }
}

/// Sensei / iStat Menus-inspired smooth area-line sparkline chart.
/// Keeps the exact call-site contract across PerformanceView and MenuBarContent.
struct Sparkline: View {
    let values: [Double]
    /// The value that fills the chart height; nil scales to the largest value shown.
    var maxValue: Double? = 1
    var tint: Color = Palette.keelGreen
    var height: CGFloat = 56

    var body: some View {
        let count = max(SystemStatus.historyLength, values.count)
        let padded = Array(repeating: 0.0, count: max(count - values.count, 0)) + values
        let scale = maxValue ?? max(padded.max() ?? 0, 1)
        let isCompact = height < 28

        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let insetTop: CGFloat = isCompact ? 2.5 : 4
            let insetBottom: CGFloat = 1.5
            let usableH = max(h - insetTop - insetBottom, 1)
            let points: [CGPoint] = padded.enumerated().map { idx, val in
                let x = padded.count > 1 ? w * CGFloat(idx) / CGFloat(padded.count - 1) : w
                let norm = min(max(val / scale, 0), 1)
                let y = insetTop + usableH * (1 - CGFloat(norm))
                return CGPoint(x: x, y: y)
            }

            ZStack {
                // Subtle chart container + reference gridlines on taller charts
                RoundedRectangle(cornerRadius: isCompact ? 5 : 8, style: .continuous)
                    .fill(Color.white.opacity(isCompact ? 0.035 : 0.028))

                if !isCompact {
                    Path { grid in
                        for step in [0.25, 0.5, 0.75] {
                            let y = insetTop + usableH * step
                            grid.move(to: CGPoint(x: 0, y: y))
                            grid.addLine(to: CGPoint(x: w, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.05), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                }

                if points.count >= 2 {
                    let line = smoothPath(points)

                    // Gradient area fill beneath curve
                    Path { area in
                        area.addPath(line)
                        if let last = points.last, let first = points.first {
                            area.addLine(to: CGPoint(x: last.x, y: h))
                            area.addLine(to: CGPoint(x: first.x, y: h))
                            area.closeSubpath()
                        }
                    }
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(isCompact ? 0.34 : 0.28), tint.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Crisp glowing curve stroke
                    line
                        .stroke(
                            tint,
                            style: StrokeStyle(lineWidth: isCompact ? 1.5 : 1.9, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: tint.opacity(0.35), radius: isCompact ? 2 : 4, y: 1)

                    // Live endpoint dot
                    if let last = points.last {
                        Circle()
                            .fill(tint)
                            .frame(width: isCompact ? 4 : 5.5, height: isCompact ? 4 : 5.5)
                            .overlay {
                                Circle().stroke(Color.white.opacity(0.75), lineWidth: 1)
                            }
                            .position(x: min(last.x, w - 2.5), y: last.y)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: isCompact ? 5 : 8, style: .continuous))
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    private func smoothPath(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for idx in 1..<points.count {
            let prev = points[idx - 1]
            let curr = points[idx]
            let midX = (prev.x + curr.x) * 0.5
            path.addCurve(
                to: curr,
                control1: CGPoint(x: midX, y: prev.y),
                control2: CGPoint(x: midX, y: curr.y)
            )
        }
        return path
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
                Capsule().strokeBorder(foreground.opacity(0.24), lineWidth: 1)
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
            .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
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
                .font(.keel(25, .extraBold))
                .tracking(-0.55)
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
