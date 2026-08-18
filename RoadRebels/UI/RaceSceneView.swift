import SwiftUI
import RealityKit
import UIKit

/// Thin UIViewRepresentable bridge into RealityKit's ARView, run in `.nonAR`
/// mode — we want a virtual 3D scene with our own chase camera, not an
/// AR/camera-passthrough experience.
struct RaceSceneView: UIViewRepresentable {
    let raceController: RaceController

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.environment.background = .color(UIColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 1.0))
        arView.renderOptions.insert(.disableMotionBlur)
        arView.scene.addAnchor(raceController.sceneAnchor)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
