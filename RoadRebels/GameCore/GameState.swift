import Foundation

enum AppScreen: Equatable {
    case menu
    case careerMap
    case garage
    case store
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

    func openCareerMap() {
        screen = .careerMap
    }

    func openGarage() {
        screen = .garage
    }

    func openStore() {
        screen = .store
    }

    func startRace(config: RaceConfiguration) {
        resetTelemetry()
        screen = .racing(config)
    }

    func finishRace(result: RaceResult) {
        screen = .raceFinished(result: result)
    }

    func startEndless() {
        resetTelemetry()
        screen = .endless
    }

    func finishEndless(result: EndlessResult) {
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
    }
}
