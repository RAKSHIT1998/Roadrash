import Foundation

/// Local high-score tracking for Endless mode. Game Center leaderboard
/// submission (mega-spec section 27) hooks in here once Phase 7 adds
/// GameKit — this stays the single source of truth for "is this a new best"
/// either way.
@MainActor
final class EndlessState: ObservableObject {
    @Published private(set) var highScore: Int
    private let saveManager: SaveManager

    init(saveManager: SaveManager = .shared) {
        self.saveManager = saveManager
        self.highScore = saveManager.loadEndlessHighScore()
    }

    @discardableResult
    func submit(score: Int) -> Bool {
        guard score > highScore else { return false }
        highScore = score
        saveManager.saveEndlessHighScore(score)
        return true
    }
}
