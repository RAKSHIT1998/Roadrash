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
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(gameState.endlessDistance)) M")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                Text("BEST \(highScore)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
    }

    private var bottomRow: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                HealthBarView(value: gameState.playerHealth / max(1, gameState.playerMaxHealth), color: .red)
                NitroBarView(value: gameState.nitroMeter)
            }
            Spacer()
            Text("\(Int(gameState.playerSpeed * 3.6)) KM/H")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(radius: 4)
        }
    }
}

struct NitroBarView: View {
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

struct HealthBarView: View {
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
