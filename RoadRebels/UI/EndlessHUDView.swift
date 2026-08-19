import SwiftUI

struct EndlessHUDView: View {
    @ObservedObject var gameState: GameState
    let highScore: Int

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
            VStack(alignment: .leading, spacing: 3) {
                Text("\(Int(gameState.endlessDistance)) M")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Theme.accentRed.opacity(0.4), radius: 8)
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("BEST \(highScore)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Theme.accentYellow.opacity(0.9))
            }
            Spacer()
        }
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
