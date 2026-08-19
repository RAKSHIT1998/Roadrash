import SwiftUI

/// Home screen: RIDE drops straight into a quick race, CAREER opens the
/// region/race map, GARAGE manages bikes/upgrades, ENDLESS starts the
/// Highway Rush survival mode. Leaderboard/settings entry points arrive in
/// their respective later phases.
struct MenuView: View {
    let onRide: () -> Void
    let onCareer: () -> Void
    let onGarage: () -> Void
    let onEndless: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.10, green: 0.05, blue: 0.16)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("ROAD REBELS")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("RIDE.  FIGHT.  SURVIVE.")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(5)
                        .foregroundStyle(.white.opacity(0.55))
                }

                VStack(spacing: 14) {
                    Button(action: onRide) {
                        Text("RIDE")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 52)
                            .padding(.vertical, 18)
                            .background(Color.red, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 12) {
                        secondaryButton("CAREER", action: onCareer)
                        secondaryButton("GARAGE", action: onGarage)
                        secondaryButton("ENDLESS", action: onEndless)
                    }
                }
            }
        }
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}
