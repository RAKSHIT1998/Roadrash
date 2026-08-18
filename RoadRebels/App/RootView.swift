import SwiftUI

struct RootView: View {
    @StateObject private var gameState = GameState()
    @StateObject private var careerState = CareerState()

    var body: some View {
        Group {
            switch gameState.screen {
            case .menu:
                MenuView(
                    onRide: { gameState.startRace(config: .quickRace) },
                    onCareer: gameState.openCareerMap
                )
            case .careerMap:
                CareerMapView(
                    careerState: careerState,
                    onSelectRace: { race in gameState.startRace(config: RaceConfiguration(careerRace: race)) },
                    onBack: gameState.returnToMenu
                )
            case .racing(let config):
                RaceView(gameState: gameState, config: config)
            case .raceFinished(let result):
                FinishView(
                    result: result,
                    careerState: careerState,
                    onContinue: result.careerRaceID != nil ? gameState.openCareerMap : gameState.returnToMenu
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}
