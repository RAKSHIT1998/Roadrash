import Foundation

enum AppScreen: Equatable {
    case menu
    case racing
    case raceFinished(result: RaceResult)
}

struct RaceResult: Equatable {
    let position: Int
    let totalRiders: Int
    let elapsedTime: TimeInterval
    let didWin: Bool
}

/// Top-level observable state shared between SwiftUI and the game world.
@MainActor
final class GameState: ObservableObject {
    @Published var screen: AppScreen = .menu

    // Live race telemetry consumed by the HUD.
    @Published var playerPosition: Int = 1
    @Published var playerSpeed: Float = 0
    @Published var playerHealth: Float = GameConstants.riderMaxHealth
    @Published var raceProgress: Float = 0 // 0...1

    func startRace() {
        playerPosition = 1
        playerSpeed = 0
        playerHealth = GameConstants.riderMaxHealth
        raceProgress = 0
        screen = .racing
    }

    func finishRace(result: RaceResult) {
        screen = .raceFinished(result: result)
    }

    func returnToMenu() {
        screen = .menu
    }
}
