import SwiftUI

/// Shared meter bar (health/nitro) used by both the race HUD and the
/// Endless HUD — an icon, a glowing gradient-filled capsule, one look.
struct HUDBar: View {
    let icon: String
    let value: Float // 0...1
    let color: Color
    var width: CGFloat = 150

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 14)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.45))
                Capsule()
                    .fill(LinearGradient(colors: [color.opacity(0.7), color], startPoint: .leading, endPoint: .trailing))
                    .frame(width: width * CGFloat(max(0, min(1, value))))
                    .shadow(color: color.opacity(0.7), radius: 4)
            }
            .frame(width: width, height: 10)
            .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
        }
    }
}

/// The "1ST / 2ND / ..." badge shown top-left during a race.
struct PositionBadge: View {
    let position: Int

    var body: some View {
        Text(ordinal(position))
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(colors: [Theme.accentRed, Theme.accentRedDeep], startPoint: .top, endPoint: .bottom),
                in: Capsule()
            )
            .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
            .shadow(color: Theme.accentRed.opacity(0.5), radius: 10, y: 4)
    }

    private func ordinal(_ position: Int) -> String {
        switch position {
        case 1: return "1ST"
        case 2: return "2ND"
        case 3: return "3RD"
        default: return "\(position)TH"
        }
    }
}

/// Speed readout with a small icon and big monospaced number.
struct SpeedReadout: View {
    let speed: Float // m/s

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text("\(Int(speed * 3.6))")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("KM/H")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
        }
        .shadow(radius: 4)
    }
}
