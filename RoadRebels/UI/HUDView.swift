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
            Text(ordinal(gameState.playerPosition))
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
            VStack(alignment: .leading, spacing: 8) {
                HealthBar(value: gameState.playerHealth / GameConstants.riderMaxHealth, color: .red)
                NitroBar(value: gameState.nitroMeter)
            }
            Spacer()
            Text("\(Int(gameState.playerSpeed * 3.6)) KM/H")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(radius: 4)
        }
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

private struct NitroBar: View {
    let value: Float
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.black.opacity(0.4))
            Capsule().fill(Color.cyan)
                .frame(width: 140 * CGFloat(max(0, min(1, value))))
        }
        .frame(width: 140, height: 10)
    }
}

private struct HealthBar: View {
    let value: Float
    let color: Color
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.black.opacity(0.4))
            Capsule().fill(color)
                .frame(width: 140 * CGFloat(max(0, min(1, value))))
        }
        .frame(width: 140, height: 14)
    }
}
