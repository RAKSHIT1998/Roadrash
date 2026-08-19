import SwiftUI
import GameKit

/// Presents Apple's native Game Center UI (leaderboards/achievements) as a
/// sheet. If the player isn't authenticated, GameKit shows its own sign-in
/// prompt inside this view rather than us needing to build one.
struct GameCenterView: UIViewControllerRepresentable {
    let state: GKGameCenterViewControllerState
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let controller = GKGameCenterViewController(state: state)
        controller.gameCenterDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true, completion: onDismiss)
        }
    }
}
