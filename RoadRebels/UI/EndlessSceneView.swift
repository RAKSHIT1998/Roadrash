import SwiftUI
import RealityKit
import UIKit

struct EndlessSceneView: UIViewRepresentable {
    let controller: EndlessController

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.environment.background = .color(UIColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 1.0))
        arView.renderOptions.insert(.disableMotionBlur)
        arView.scene.addAnchor(controller.sceneAnchor)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
