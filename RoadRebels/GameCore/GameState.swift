import Foundation

enum AppScreen: Equatable {
    case menu
    case careerMap
    case garage
    case store
    case settings
    case racing(RaceConfiguration)
    case raceFinished(result: RaceResult)
    case endless
    case endlessFinished(result: EndlessResult)
}

struct RaceResult: Equatable {
    let position: Int
    let totalRiders: Int
    let elapsedTime: TimeInterval
    let didWin: Bool
    let careerRaceID: String?
    let creditsEarned: Int
    let hadAnyCollision: Bool
    let tookAnyDamage: Bool
    let nearMisses: Int
}

/// Top-level observable state shared between SwiftUI and the game world.
@MainActor
final class GameState: ObservableObject {
    @Published var screen: AppScreen = .menu

    // Live race telemetry consumed by the HUD.
    @Published var playerPosition: Int = 1
    @Published var playerSpeed: Float = 0
    @Published var playerHealth: Float = GameConstants.riderMaxHealth
    @Published var playerMaxHealth: Float = GameConstants.riderMaxHealth
    @Published var raceProgress: Float = 0 // 0...1
    @Published var nitroMeter: Float = 0 // 0...1
    @Published var endlessDistance: Float = 0
    @Published var endlessPoliceGap: Float?
    @Published var endlessBustProgress: Float = 0

    func openCareerMap() {
        screen = .careerMap
    }

    func openGarage() {
        screen = .garage
    }

    func openStore() {
        AnalyticsService.shared.log(.storeOpened)
        screen = .store
    }

    func openSettings() {
        screen = .settings
    }

    func startRace(config: RaceConfiguration) {
        resetTelemetry()
        AnalyticsService.shared.log(.raceStarted(mode: config.careerRaceID != nil ? "career" : "quick"))
        screen = .racing(config)
    }

    func finishRace(result: RaceResult) {
        let mode = result.careerRaceID != nil ? "career" : "quick"
        AnalyticsService.shared.log(.raceFinished(mode: mode, position: result.position))
        AnalyticsService.shared.log(result.didWin ? .raceWon(mode: mode) : .raceLost(mode: mode))
        screen = .raceFinished(result: result)
    }

    func startEndless() {
        resetTelemetry()
        AnalyticsService.shared.log(.endlessStarted)
        screen = .endless
    }

    func finishEndless(result: EndlessResult) {
        AnalyticsService.shared.log(.endlessFinished(score: result.score))
        screen = .endlessFinished(result: result)
    }

    func returnToMenu() {
        screen = .menu
    }

    private func resetTelemetry() {
        playerPosition = 1
        playerSpeed = 0
        playerHealth = GameConstants.riderMaxHealth
        playerMaxHealth = GameConstants.riderMaxHealth
        raceProgress = 0
        nitroMeter = 0
        endlessDistance = 0
        endlessPoliceGap = nil
        endlessBustProgress = 0
    }
}
