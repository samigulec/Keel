import SwiftUI

/// The little helpers from the design, one per section: Kee (Akıllı Tarama),
/// Puf (Temizlik), Zip (Performans), Roket (Optimizasyon), Blok
/// (Uygulamalar), Kutu (Büyük Dosyalar) and Bilge (Keel AI).
/// Drawn on the design's 64×64 grid so they stay sharp at any size.
struct Mascot: View {
    enum Character {
        case kee, puf, zip, roket, blok, kutu, bilge
    }

    let character: Character
    var size: CGFloat = 34

    var body: some View {
        Canvas { context, canvasSize in
            context.scaleBy(x: canvasSize.width / 64, y: canvasSize.height / 64)
            switch character {
            case .kee: Self.drawKee(in: &context)
            case .puf: Self.drawPuf(in: &context)
            case .zip: Self.drawZip(in: &context)
            case .roket: Self.drawRoket(in: &context)
            case .blok: Self.drawBlok(in: &context)
            case .kutu: Self.drawKutu(in: &context)
            case .bilge: Self.drawBilge(in: &context)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    // MARK: Characters

    private static func drawKee(in context: inout GraphicsContext) {
        var body = Path()
        body.move(to: CGPoint(x: 32, y: 12))
        body.addCurve(to: CGPoint(x: 54, y: 34), control1: CGPoint(x: 45, y: 12), control2: CGPoint(x: 54, y: 21))
        body.addCurve(to: CGPoint(x: 32, y: 56), control1: CGPoint(x: 54, y: 47), control2: CGPoint(x: 46, y: 56))
        body.addCurve(to: CGPoint(x: 10, y: 34), control1: CGPoint(x: 18, y: 56), control2: CGPoint(x: 10, y: 47))
        body.addCurve(to: CGPoint(x: 32, y: 12), control1: CGPoint(x: 10, y: 21), control2: CGPoint(x: 19, y: 12))
        body.closeSubpath()
        context.fill(body, with: gradient(0x8CFAD6, 0x1BA7D6, in: CGRect(x: 10, y: 12, width: 44, height: 44)))
        highlight(in: &context, center: CGPoint(x: 23, y: 21), radii: CGSize(width: 8, height: 4.5), degrees: -25)
        context.fill(sparkle(), with: .color(Color(hex: 0xFFE58A)))
        face(in: &context)
    }

    private static func drawPuf(in context: inout GraphicsContext) {
        let body = Path(ellipseIn: CGRect(x: 12, y: 18, width: 40, height: 38))
        context.fill(body, with: gradient(0x8CE9FF, 0x2F6FE0, in: body.boundingRect))
        for (x, y, r) in [(22.0, 17.0, 6.5), (44.0, 18.0, 5.5), (33.0, 12.0, 8.0)] {
            let foam = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            context.fill(foam, with: .color(Color(hex: 0xEAFBFF)))
            context.stroke(foam, with: .color(Color(hex: 0x8CE9FF)), lineWidth: 1.5)
        }
        face(in: &context)
    }

    private static func drawZip(in context: inout GraphicsContext) {
        var body = Path()
        body.move(to: CGPoint(x: 32, y: 14))
        body.addCurve(to: CGPoint(x: 52, y: 42), control1: CGPoint(x: 42, y: 22), control2: CGPoint(x: 52, y: 30))
        body.addCurve(to: CGPoint(x: 32, y: 57), control1: CGPoint(x: 52, y: 51), control2: CGPoint(x: 43, y: 57))
        body.addCurve(to: CGPoint(x: 12, y: 42), control1: CGPoint(x: 21, y: 57), control2: CGPoint(x: 12, y: 51))
        body.addCurve(to: CGPoint(x: 32, y: 14), control1: CGPoint(x: 12, y: 30), control2: CGPoint(x: 22, y: 22))
        body.closeSubpath()
        context.fill(body, with: gradient(0xFFE08A, 0xF0782F, in: CGRect(x: 12, y: 14, width: 40, height: 43)))

        var bolt = Path()
        bolt.addLines([
            CGPoint(x: 36, y: 1), CGPoint(x: 27, y: 13), CGPoint(x: 32.5, y: 13),
            CGPoint(x: 30, y: 21), CGPoint(x: 39, y: 9), CGPoint(x: 33.5, y: 9),
        ])
        bolt.closeSubpath()
        context.fill(bolt, with: .color(Color(hex: 0xFFF6C2)))
        context.stroke(bolt, with: .color(Color(hex: 0xF0782F)), style: StrokeStyle(lineWidth: 1.2, lineJoin: .round))

        var lowered = context
        lowered.translateBy(x: 0, y: 3)
        face(in: &lowered)
    }

    private static func drawBlok(in context: inout GraphicsContext) {
        context.fill(Path(roundedRect: CGRect(x: 20, y: 4, width: 11, height: 11), cornerRadius: 2.5), with: .color(Color(hex: 0xFFC46B)))
        context.fill(Path(roundedRect: CGRect(x: 33, y: 7, width: 9, height: 9), cornerRadius: 2.5), with: .color(Color(hex: 0x7EF0C8)))
        let rect = CGRect(x: 8, y: 15, width: 48, height: 41)
        context.fill(Path(roundedRect: rect, cornerRadius: 7), with: gradient(0xB3D2FF, 0x4F5BD5, in: rect))
        highlight(in: &context, center: CGPoint(x: 19, y: 22), radii: CGSize(width: 6, height: 3), degrees: 0)
        var lowered = context
        lowered.translateBy(x: 0, y: 1)
        face(in: &lowered)
    }

    /// A small rocket with fins and a flame: lighter and quicker.
    private static func drawRoket(in context: inout GraphicsContext) {
        for side in [-1.0, 1.0] {
            var fin = Path()
            fin.addLines([
                CGPoint(x: 32 + side * 15, y: 34), CGPoint(x: 32 + side * 24, y: 52), CGPoint(x: 32 + side * 15, y: 49),
            ])
            fin.closeSubpath()
            context.fill(fin, with: .color(Color(hex: 0xA08BFF)))
        }

        var flame = Path()
        flame.move(to: CGPoint(x: 25, y: 52))
        flame.addQuadCurve(to: CGPoint(x: 32, y: 63), control: CGPoint(x: 25, y: 59))
        flame.addQuadCurve(to: CGPoint(x: 39, y: 52), control: CGPoint(x: 39, y: 59))
        flame.closeSubpath()
        context.fill(flame, with: gradient(0xFFE08A, 0xF0782F, in: flame.boundingRect))

        var body = Path()
        body.move(to: CGPoint(x: 32, y: 5))
        body.addCurve(to: CGPoint(x: 49, y: 34), control1: CGPoint(x: 43, y: 12), control2: CGPoint(x: 49, y: 23))
        body.addLine(to: CGPoint(x: 49, y: 47))
        body.addQuadCurve(to: CGPoint(x: 15, y: 47), control: CGPoint(x: 32, y: 56))
        body.addLine(to: CGPoint(x: 15, y: 34))
        body.addCurve(to: CGPoint(x: 32, y: 5), control1: CGPoint(x: 15, y: 23), control2: CGPoint(x: 21, y: 12))
        body.closeSubpath()
        context.fill(body, with: gradient(0x9DF5C8, 0x2FB6A0, in: CGRect(x: 15, y: 5, width: 34, height: 47)))
        // A porthole above the face.
        context.fill(Path(ellipseIn: CGRect(x: 27, y: 14, width: 10, height: 10)), with: .color(Color(hex: 0xEAFBFF)))
        context.stroke(Path(ellipseIn: CGRect(x: 27, y: 14, width: 10, height: 10)), with: .color(Color(hex: 0x2FB6A0)), lineWidth: 2)
        highlight(in: &context, center: CGPoint(x: 22, y: 28), radii: CGSize(width: 3, height: 6), degrees: 10)
        var lowered = context
        lowered.translateBy(x: 0, y: 2)
        face(in: &lowered)
    }

    /// A cardboard box holding big things, its lid a little open.
    private static func drawKutu(in context: inout GraphicsContext) {
        let rect = CGRect(x: 9, y: 22, width: 46, height: 35)
        context.fill(Path(roundedRect: rect, cornerRadius: 7), with: gradient(0xFFC46B, 0xF0782F, in: rect))
        var lid = context
        lid.translateBy(x: 32, y: 17)
        lid.rotate(by: .degrees(-6))
        lid.fill(Path(roundedRect: CGRect(x: -26, y: -6, width: 52, height: 11), cornerRadius: 4), with: .color(Color(hex: 0xFFE08A)))
        context.fill(Path(roundedRect: CGRect(x: 29, y: 22, width: 6, height: 9), cornerRadius: 1.5), with: .color(Color(hex: 0xFFF6C2).opacity(0.8)))
        highlight(in: &context, center: CGPoint(x: 19, y: 28), radii: CGSize(width: 6, height: 3), degrees: 0)
        var lowered = context
        lowered.translateBy(x: 0, y: 2)
        face(in: &lowered)
    }

    private static func drawBilge(in context: inout GraphicsContext) {
        var antenna = Path()
        antenna.move(to: CGPoint(x: 32, y: 18))
        antenna.addLine(to: CGPoint(x: 32, y: 9))
        context.stroke(antenna, with: .color(Color(hex: 0xC9BDFF)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        context.fill(Path(ellipseIn: CGRect(x: 27.5, y: 2.5, width: 9, height: 9)), with: .color(Color(hex: 0x7EF0C8)))
        for x in [4.0, 54.0] {
            context.fill(Path(roundedRect: CGRect(x: x, y: 31, width: 6, height: 12), cornerRadius: 3), with: .color(Color(hex: 0x8F7BF0)))
        }
        let rect = CGRect(x: 8, y: 17, width: 48, height: 39)
        context.fill(Path(roundedRect: rect, cornerRadius: 12), with: gradient(0xC9BDFF, 0x4C8DF6, in: rect))
        highlight(in: &context, center: CGPoint(x: 20, y: 24), radii: CGSize(width: 6, height: 3), degrees: 0)
        face(in: &context)
    }

    // MARK: Shared parts

    /// Eyes with a shine, rosy cheeks and a small smile, as every helper has.
    private static func face(in context: inout GraphicsContext) {
        let ink = Color(hex: 0x0B1B2B)
        for x in [25.0, 39.0] {
            context.fill(Path(ellipseIn: CGRect(x: x - 3.4, y: 36 - 4.4, width: 6.8, height: 8.8)), with: .color(ink))
            context.fill(Path(ellipseIn: CGRect(x: x + 1.3 - 1.4, y: 34.3 - 1.4, width: 2.8, height: 2.8)), with: .color(.white))
        }
        for x in [19.0, 45.0] {
            context.fill(
                Path(ellipseIn: CGRect(x: x - 3.6, y: 43 - 2.2, width: 7.2, height: 4.4)),
                with: .color(Color(hex: 0xFF7FA8).opacity(0.6))
            )
        }
        var smile = Path()
        smile.move(to: CGPoint(x: 28.5, y: 44))
        smile.addQuadCurve(to: CGPoint(x: 35.5, y: 44), control: CGPoint(x: 32, y: 47.2))
        context.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
    }

    private static func highlight(in context: inout GraphicsContext, center: CGPoint, radii: CGSize, degrees: Double) {
        var shine = context
        shine.translateBy(x: center.x, y: center.y)
        shine.rotate(by: .degrees(degrees))
        let rect = CGRect(x: -radii.width, y: -radii.height, width: radii.width * 2, height: radii.height * 2)
        shine.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.4)))
    }

    private static func sparkle() -> Path {
        var star = Path()
        star.addLines([
            CGPoint(x: 45, y: 2), CGPoint(x: 46.8, y: 6.6), CGPoint(x: 51.5, y: 8.5), CGPoint(x: 46.8, y: 10.3),
            CGPoint(x: 45, y: 15), CGPoint(x: 43.2, y: 10.3), CGPoint(x: 38.5, y: 8.5), CGPoint(x: 43.2, y: 6.6),
        ])
        star.closeSubpath()
        return star
    }

    /// The design's top-left to bottom-right body gradient.
    private static func gradient(_ from: UInt32, _ to: UInt32, in rect: CGRect) -> GraphicsContext.Shading {
        .linearGradient(
            Gradient(colors: [Color(hex: from), Color(hex: to)]),
            startPoint: CGPoint(x: rect.minX, y: rect.minY),
            endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
        )
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
}
