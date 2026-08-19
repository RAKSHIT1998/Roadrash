import SwiftUI

/// Shared visual language for every screen — one place to keep colors,
/// spacing, and effects consistent instead of re-deriving them per view.
enum Theme {
    static let backgroundTop = Color(red: 0.10, green: 0.045, blue: 0.16)
    static let backgroundBottom = Color(red: 0.015, green: 0.008, blue: 0.03)

    static let accentRed = Color(red: 1.00, green: 0.25, blue: 0.24)
    static let accentRedDeep = Color(red: 0.85, green: 0.10, blue: 0.16)
    static let accentCyan = Color(red: 0.32, green: 0.86, blue: 1.00)
    static let accentYellow = Color(red: 1.00, green: 0.82, blue: 0.20)
    static let accentGreen = Color(red: 0.30, green: 0.92, blue: 0.55)
    static let accentViolet = Color(red: 0.62, green: 0.35, blue: 1.00)

    static let cardFill = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.10)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.38)

    static let cardRadius: CGFloat = 16
    static let pillRadius: CGFloat = 100
}

/// Full-bleed dark gradient with soft color glows, used behind every
/// non-gameplay screen so the app reads as one consistent product instead
/// of a stack of plain black screens.
struct GameBackground: View {
    var accent: Color = Theme.accentRed

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.backgroundTop, Theme.backgroundBottom],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [accent.opacity(0.22), .clear],
                center: .topTrailing, startRadius: 20, endRadius: 620
            )
            RadialGradient(
                colors: [Theme.accentCyan.opacity(0.14), .clear],
                center: .bottomLeading, startRadius: 20, endRadius: 560
            )
        }
        .ignoresSafeArea()
    }
}

/// Slow-drifting diagonal streaks — the app icon's motif, reused as ambient
/// motion behind menus so the game feels alive even standing still.
struct SpeedLinesBackground: View {
    var opacity: Double = 0.05

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let offset = (t * 40).truncatingRemainder(dividingBy: 260)
                var y: CGFloat = -260
                var index = 0
                while y < size.height + 260 {
                    let lineOpacity = opacity * (index % 2 == 0 ? 1.0 : 1.4)
                    var path = Path()
                    let startY = y + offset
                    path.move(to: CGPoint(x: -120, y: startY - 90))
                    path.addLine(to: CGPoint(x: size.width + 120, y: startY + 90))
                    ctx.stroke(path, with: .color(.white.opacity(lineOpacity)), lineWidth: 30)
                    y += 130
                    index += 1
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Card container with consistent fill/stroke/shadow — the base every list
/// row and info panel builds on.
struct CardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
            .fill(Theme.cardFill)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        background(CardBackground())
    }
}
