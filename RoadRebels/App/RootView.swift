import SwiftUI

struct RootView: View {
    @StateObject private var gameState = GameState()
    @StateObject private var careerState = CareerState()
    @StateObject private var garageState = GarageState()
    @StateObject private var endlessState = EndlessState()
    @StateObject private var playerStats = PlayerStatsState()
    @StateObject private var gameCenter = GameCenterService.shared
    @StateObject private var storeService = StoreService.shared
    @StateObject private var settingsState = SettingsState()
    @StateObject private var tutorialState = TutorialState()

    private var progression: ProgressionCoordinator {
        ProgressionCoordinator(playerStats: playerStats, careerState: careerState, endlessState: endlessState, gameCenter: gameCenter)
    }

    private var purchaseCoordinator: PurchaseCoordinator {
        PurchaseCoordinator(storeService: storeService, careerState: careerState, garageState: garageState)
    }

    var body: some View {
        Group {
            switch gameState.screen {
            case .menu:
                MenuView(
                    onRide: {
                        progression.handleRaceStart()
                        gameState.startRace(config: .quickRace)
                    },
                    onCareer: gameState.openCareerMap,
                    onGarage: gameState.openGarage,
                    onEndless: {
                        progression.handleRaceStart()
                        gameState.startEndless()
                    },
                    onStore: gameState.openStore,
                    onSettings: gameState.openSettings
                )
            case .careerMap:
                CareerMapView(
                    careerState: careerState,
                    onSelectRace: { race in
                        progression.handleRaceStart()
                        gameState.startRace(config: RaceConfiguration(careerRace: race))
                    },
                    onBack: gameState.returnToMenu
                )
            case .garage:
                GarageView(garageState: garageState, careerState: careerState, onBack: gameState.returnToMenu)
            case .store:
                StoreView(storeService: storeService, coordinator: purchaseCoordinator, onBack: gameState.returnToMenu)
            case .settings:
                SettingsView(settings: settingsState, onBack: gameState.returnToMenu)
            case .racing(let config):
                RaceView(gameState: gameState, config: config, tuning: garageState.tuning(for: garageState.selectedBikeID), appearance: garageState.appearance, tutorialState: tutorialState)
            case .raceFinished(let result):
                FinishView(
                    result: result,
                    careerState: careerState,
                    progression: progression,
                    onContinue: result.careerRaceID != nil ? gameState.openCareerMap : gameState.returnToMenu
                )
            case .endless:
                EndlessView(gameState: gameState, endlessState: endlessState, tuning: garageState.tuning(for: garageState.selectedBikeID), appearance: garageState.appearance)
            case .endlessFinished(let result):
                EndlessResultView(result: result, progression: progression, onContinue: gameState.returnToMenu)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            gameCenter.authenticate()
            AnalyticsService.shared.log(.gameStarted)
        }
    }
}
