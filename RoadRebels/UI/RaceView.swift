import SwiftUI

/// Hosts the RealityKit scene, HUD, and touch controls for one race, and
/// owns the RaceController + GameLoop lifecycle for as long as this view is
/// on screen.
struct RaceView: View {
    @ObservedObject var gameState: GameState
    let config: RaceConfiguration
    let tuning: BikeTuning
    @StateObject private var input = BikeInputController()
    @State private var raceController: RaceController?
    @State private var loop: GameLoop?

    var body: some View {
        ZStack {
            if let raceController {
                RaceSceneView(raceController: raceController)
                    .ignoresSafeArea()
            }
            RaceControlsOverlay(input: input)
            HUDView(gameState: gameState)
        }
        .statusBarHidden(true)
        .onAppear(perform: setup)
        .onDisappear {
            loop?.stop()
            loop = nil
            raceController = nil
        }
    }

    private func setup() {
        let controller = RaceController(input: input, gameState: gameState, config: config, tuning: tuning)
        controller.start()
        raceController = controller

        let gameLoop = GameLoop { [weak controller] dt in
            controller?.update(dt: dt)
        }
        loop = gameLoop
        gameLoop.start()
    }
}
