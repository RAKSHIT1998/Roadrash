import SwiftUI

struct RootView: View {
    @StateObject private var gameState = GameState()
    @StateObject private var careerState = CareerState()
    @StateObject private var garageState = GarageState()
    @StateObject private var endlessState = EndlessState()

    var body: some View {
        Group {
            switch gameState.screen {
            case .menu:
                MenuView(
                    onRide: { gameState.startRace(config: .quickRace) },
                    onCareer: gameState.openCareerMap,
                    onGarage: gameState.openGarage,
                    onEndless: gameState.startEndless
                )
            case .careerMap:
                CareerMapView(
                    careerState: careerState,
                    onSelectRace: { race in gameState.startRace(config: RaceConfiguration(careerRace: race)) },
                    onBack: gameState.returnToMenu
                )
            case .garage:
                GarageView(garageState: garageState, careerState: careerState, onBack: gameState.returnToMenu)
            case .racing(let config):
                RaceView(gameState: gameState, config: config, tuning: garageState.tuning(for: garageState.selectedBikeID))
            case .raceFinished(let result):
                FinishView(
                    result: result,
                    careerState: careerState,
                    onContinue: result.careerRaceID != nil ? gameState.openCareerMap : gameState.returnToMenu
                )
            case .endless:
                EndlessView(gameState: gameState, endlessState: endlessState, tuning: garageState.tuning(for: garageState.selectedBikeID))
            case .endlessFinished(let result):
                EndlessResultView(result: result, endlessState: endlessState, onContinue: gameState.returnToMenu)
            }
        }
        .preferredColorScheme(.dark)
    }
}
