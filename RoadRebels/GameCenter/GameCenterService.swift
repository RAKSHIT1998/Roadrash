import GameKit
import UIKit

/// Thin wrapper over GameKit. Every outward-facing call guards on
/// `isAuthenticated` so the game plays identically offline or on a
/// simulator/device with no signed-in Game Center account — this is the
/// "isolated" integration point called for in the mega-spec (section 65
/// QA check: "Game Center integration is isolated").
@MainActor
final class GameCenterService: NSObject, ObservableObject {
    static let shared = GameCenterService()

    @Published private(set) var isAuthenticated = false
    @Published private(set) var localPlayerDisplayName: String?

    private override init() {
        super.init()
    }

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            if let viewController {
                Self.topViewController()?.present(viewController, animated: true)
                return
            }
            self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            self.localPlayerDisplayName = self.isAuthenticated ? GKLocalPlayer.local.displayName : nil
        }
    }

    func submitScore(_ score: Int, leaderboard: LeaderboardID) {
        guard isAuthenticated else { return }
        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboard.rawValue],
            completionHandler: { _ in }
        )
    }

    func reportAchievement(_ id: AchievementID, percentComplete: Double = 100) {
        guard isAuthenticated else { return }
        let achievement = GKAchievement(identifier: id.rawValue)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true
        GKAchievement.report([achievement], completionHandler: { _ in })
    }

    private static func topViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
