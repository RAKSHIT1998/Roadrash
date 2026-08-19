import SwiftUI

/// Race HUD: position, progress, health, nitro, speed.
struct HUDView: View {
    @ObservedObject var gameState: GameState

    var body: some View {
        VStack {
            topRow
            Spacer()
            bottomRow
        }
        .padding(20)
        .allowsHitTesting(false)
    }

    private var topRow: some View {
        HStack(alignment: .top) {
            PositionBadge(position: gameState.playerPosition)
            Spacer()
            raceProgressBar
        }
    }

    private var raceProgressBar: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.black.opacity(0.4))
            Capsule()
                .fill(LinearGradient(colors: [Theme.accentRed, Theme.accentYellow], startPoint: .leading, endPoint: .trailing))
                .frame(width: 170 * CGFloat(max(0, min(1, gameState.raceProgress))))
        }
        .frame(width: 170, height: 8)
        .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
        .padding(.top, 10)
    }

    private var bottomRow: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                HUDBar(icon: "heart.fill", value: gameState.playerHealth / max(1, gameState.playerMaxHealth), color: Theme.accentRed)
                HUDBar(icon: "bolt.fill", value: gameState.nitroMeter, color: Theme.accentCyan)
            }
            Spacer()
            SpeedReadout(speed: gameState.playerSpeed)
        }
    }
}
