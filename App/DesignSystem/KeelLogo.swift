import SwiftUI

/// The Keel mark: a spark over a hull with its keel, drawn on a 64×64 grid.
struct KeelLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 64
        let originX = rect.midX - 32 * scale
        let originY = rect.midY - 32 * scale
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: originX + x * scale, y: originY + y * scale)
        }

        var path = Path()

        // Spark
        path.addLines([
            point(32, 4), point(34.4, 9.6), point(40, 12), point(34.4, 14.4),
            point(32, 20), point(29.6, 14.4), point(24, 12), point(29.6, 9.6),
        ])
        path.closeSubpath()

        // Hull: the lower half of a circle centred at (32, 26)
        path.move(to: point(10, 26))
        path.addLine(to: point(54, 26))
        let segments = 32
        for step in 1...segments {
            let angle = CGFloat(step) / CGFloat(segments) * .pi
            path.addLine(to: point(32 + 22 * cos(angle), 26 + 22 * sin(angle)))
        }
        path.closeSubpath()

        // Keel
        path.addLines([point(28, 46), point(36, 46), point(33.5, 60), point(30.5, 60)])
        path.closeSubpath()

        return path
    }
}

/// The architectural emerald Keel emblem tile.
struct KeelLogoTile: View {
    var size: CGFloat = 30

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0x34D399), Color(hex: 0x0D9488)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            }
            .overlay {
                KeelLogoShape()
                    .fill(Palette.onAccent)
                    .padding(size * 0.17)
            }
            .shadow(color: Palette.keelGreen.opacity(0.24), radius: size * 0.22, y: size * 0.08)
            .accessibilityHidden(true)
    }
}
