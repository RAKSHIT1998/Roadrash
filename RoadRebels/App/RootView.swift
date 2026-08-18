import SwiftUI

struct RootView: View {
    @StateObject private var gameState = GameState()

    var body: some View {
        Group {
            switch gameState.screen {
            case .menu:
                MenuView(onRide: gameState.startRace)
            case .racing:
                RaceView(gameState: gameState)
            case .raceFinished(let result):
                FinishView(result: result, onContinue: gameState.returnToMenu)
            }
        }
        .preferredColorScheme(.dark)
    }
}
