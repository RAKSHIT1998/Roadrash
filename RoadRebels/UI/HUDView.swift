import SwiftUI

/// Minimal race HUD: position, progress, health, speed. Combo/nitro-meter/
/// near-miss readouts arrive with the Phase 2 game-feel pass.
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
            Text(gameState.playerPosition == 1 ? "1ST" : "2ND")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(radius: 4)
            Spacer()
            ProgressView(value: Double(gameState.raceProgress))
                .frame(width: 160)
                .tint(.red)
        }
    }

    private var bottomRow: some View {
        HStack(alignment: .bottom) {
            HealthBar(value: gameState.playerHealth / GameConstants.riderMaxHealth)
            Spacer()
            Text("\(Int(gameState.playerSpeed * 3.6)) KM/H")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(radius: 4)
        }
    }
}

private struct HealthBar: View {
    let value: Float
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.black.opacity(0.4))
            Capsule().fill(Color.red)
                .frame(width: 140 * CGFloat(max(0, min(1, value))))
        }
        .frame(width: 140, height: 14)
    }
}
