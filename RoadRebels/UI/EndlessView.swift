import SwiftUI

struct EndlessView: View {
    @ObservedObject var gameState: GameState
    @ObservedObject var endlessState: EndlessState
    let tuning: BikeTuning
    @StateObject private var input = BikeInputController()
    @State private var controller: EndlessController?
    @State private var loop: GameLoop?

    var body: some View {
        ZStack {
            if let controller {
                EndlessSceneView(controller: controller)
                    .ignoresSafeArea()
            }
            EndlessControlsOverlay(input: input)
            EndlessHUDView(gameState: gameState, highScore: endlessState.highScore)
        }
        .statusBarHidden(true)
        .onAppear(perform: setup)
        .onDisappear {
            loop?.stop()
            loop = nil
            controller = nil
        }
    }

    private func setup() {
        let endlessController = EndlessController(input: input, gameState: gameState, tuning: tuning)
        endlessController.start()
        controller = endlessController

        let gameLoop = GameLoop { [weak endlessController] dt in
            endlessController?.update(dt: dt)
        }
        loop = gameLoop
        gameLoop.start()
    }
}
