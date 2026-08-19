import SwiftUI

/// The big glowing call-to-action button (RIDE, CONTINUE, purchase CTAs).
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.accentRed
    var textColor: Color = .black

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .foregroundStyle(textColor)
            .padding(.horizontal, 46)
            .padding(.vertical, 17)
            .background(
                LinearGradient(colors: [color, color.opacity(0.78)], startPoint: .top, endPoint: .bottom),
                in: Capsule()
            )
            .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: color.opacity(configuration.isPressed ? 0.25 : 0.55), radius: configuration.isPressed ? 6 : 18, y: configuration.isPressed ? 2 : 8)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Outlined secondary buttons (CAREER / GARAGE / ENDLESS pills).
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(Theme.cardFill, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(configuration.isPressed ? 0.55 : 0.3), lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Small circular icon buttons (trophy / bag / gear / back chevron).
struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.textPrimary.opacity(0.85))
            .frame(width: 40, height: 40)
            .background(Theme.cardFill, in: Circle())
            .overlay(Circle().stroke(Theme.cardStroke, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Generic "press to shrink slightly" wrapper for tappable rows/cards.
struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}
