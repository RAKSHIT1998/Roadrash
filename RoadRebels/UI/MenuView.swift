import SwiftUI

/// Phase 1 home screen: just enough to get into a race. Garage/career/
/// leaderboard entry points arrive in their respective phases.
struct MenuView: View {
    let onRide: () -> Void

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

                Button(action: onRide) {
                    Text("RIDE")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 52)
                        .padding(.vertical, 18)
                        .background(Color.red, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
