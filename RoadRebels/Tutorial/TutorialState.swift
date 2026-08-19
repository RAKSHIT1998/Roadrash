import Foundation

/// Tracks whether the player has ever completed (or skipped) the in-race
/// tutorial overlay. Persisted so it only shows once, ever — per the
/// mega-spec's "teach through gameplay, not a text wall" requirement
/// (section 44), this doesn't block anything; it just decides whether
/// TutorialOverlay renders during the player's first race.
@MainActor
final class TutorialState: ObservableObject {
    @Published private(set) var hasCompletedTutorial: Bool

    private let saveManager: SaveManager

    init(saveManager: SaveManager = .shared) {
        self.saveManager = saveManager
        self.hasCompletedTutorial = saveManager.loadHasCompletedTutorial()
    }

    func markCompleted() {
        guard !hasCompletedTutorial else { return }
        hasCompletedTutorial = true
        saveManager.saveHasCompletedTutorial(true)
        AnalyticsService.shared.log(.tutorialCompleted)
    }
}
