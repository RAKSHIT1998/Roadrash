import SwiftUI
import GameKit

/// Home screen: RIDE drops straight into a quick race, CAREER opens the
/// region/race map, GARAGE manages bikes/upgrades, ENDLESS starts the
/// Highway Rush survival mode. The trophy button opens Game Center's native
/// leaderboard/achievements UI. Settings arrives in a later phase.
struct MenuView: View {
    let onRide: () -> Void
    let onCareer: () -> Void
    let onGarage: () -> Void
    let onEndless: () -> Void
    let onStore: () -> Void

    @State private var showingGameCenter = false

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

            VStack {
                HStack {
                    Button(action: onStore) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(12)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button {
                        showingGameCenter = true
                    } label: {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(12)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showingGameCenter) {
            GameCenterView(state: .leaderboards) { showingGameCenter = false }
                .ignoresSafeArea()
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
