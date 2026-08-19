import SwiftUI
import GameKit

/// Home screen: RIDE drops straight into a quick race, CAREER opens the
/// region/race map, GARAGE manages bikes/upgrades, ENDLESS starts the
/// Highway Rush survival mode. The trophy button opens Game Center's native
/// leaderboard/achievements UI; the bag opens the Store; the gear opens
/// audio/haptics/accessibility Settings.
struct MenuView: View {
    let onRide: () -> Void
    let onCareer: () -> Void
    let onGarage: () -> Void
    let onEndless: () -> Void
    let onStore: () -> Void
    let onSettings: () -> Void

    @State private var showingGameCenter = false
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            GameBackground()
            SpeedLinesBackground(opacity: 0.045)

            VStack(spacing: 34) {
                titleBlock
                actionBlock
            }
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(hasAppeared ? 1 : 0.92)

            topBar
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                hasAppeared = true
            }
        }
        .sheet(isPresented: $showingGameCenter) {
            GameCenterView(state: .leaderboards) { showingGameCenter = false }
                .ignoresSafeArea()
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("ROAD REBELS")
                .font(.system(size: 50, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.white, .white.opacity(0.82)], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: Theme.accentRed.opacity(0.45), radius: 22, y: 6)
            HStack(spacing: 8) {
                Text("RIDE")
                Circle().fill(Theme.accentRed).frame(width: 4, height: 4)
                Text("FIGHT")
                Circle().fill(Theme.accentRed).frame(width: 4, height: 4)
                Text("SURVIVE")
            }
            .font(.system(size: 13, weight: .bold))
            .tracking(4)
            .foregroundStyle(Theme.textSecondary)
        }
    }

    private var actionBlock: some View {
        VStack(spacing: 16) {
            Button(action: onRide) {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                    Text("RIDE")
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            HStack(spacing: 12) {
                secondaryButton("CAREER", icon: "flag.checkered", action: onCareer)
                secondaryButton("GARAGE", icon: "wrench.fill", action: onGarage)
                secondaryButton("ENDLESS", icon: "infinity", action: onEndless)
            }
        }
    }

    private var topBar: some View {
        VStack {
            HStack {
                Button(action: onStore) {
                    Image(systemName: "bag.fill")
                }
                .buttonStyle(IconButtonStyle())
                Spacer()
                Button {
                    showingGameCenter = true
                } label: {
                    Image(systemName: "trophy.fill")
                }
                .buttonStyle(IconButtonStyle())
                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                }
                .buttonStyle(IconButtonStyle())
            }
            .padding(16)
            Spacer()
        }
    }

    private func secondaryButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
            }
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}
