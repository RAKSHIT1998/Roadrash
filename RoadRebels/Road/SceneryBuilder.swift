import RealityKit
import UIKit
import simd

/// Scatters simple procedural trees/rocks alongside the road so it reads as
/// a place instead of a bare strip of gray — same "no real art needed"
/// approach as the rest of the scene, built purely from primitives.
enum SceneryBuilder {
    static func buildProps(spline: RoadSpline, from: Float, to: Float, theme: RegionTheme) -> Entity {
        let root = Entity()
        var distance = max(0, from)
        let spacing: Float = 34

        while distance < to {
            for side: Float in [-1, 1] {
                guard Float.random(in: 0...1) < 0.55 else { continue }
                let lateralOffset = side * (GameConstants.roadWidth / 2 + Float.random(in: 4...16))
                let t = spline.transform(atDistance: distance, lateralOffset: lateralOffset)
                let prop = Float.random(in: 0...1) < 0.7 ? buildTree(theme: theme) : buildRock()
                prop.position = t.position
                prop.transform.rotation = simd_quatf(angle: Float.random(in: 0...(.pi * 2)), axis: SIMD3<Float>(0, 1, 0))
                root.addChild(prop)
            }
            distance += spacing
        }
        return root
    }

    private static func buildTree(theme: RegionTheme) -> Entity {
        let root = Entity()
        let scale = Float.random(in: 0.75...1.35)

        let trunk = ModelEntity(
            mesh: .generateCylinder(height: 1.6 * scale, radius: 0.14 * scale),
            materials: [SimpleMaterial(color: UIColor(red: 0.32, green: 0.20, blue: 0.11, alpha: 1), isMetallic: false)]
        )
        trunk.position.y = 0.8 * scale
        root.addChild(trunk)

        let foliage = ModelEntity(
            mesh: .generateCone(height: 2.3 * scale, radius: 1.0 * scale),
            materials: [SimpleMaterial(color: foliageColor(theme: theme), isMetallic: false)]
        )
        foliage.position.y = 2.4 * scale
        root.addChild(foliage)
        return root
    }

    private static func buildRock() -> Entity {
        let size = Float.random(in: 0.55...1.5)
        let rock = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(size, size * 0.65, size), cornerRadius: size * 0.18),
            materials: [SimpleMaterial(color: UIColor(white: CGFloat.random(in: 0.32...0.48), alpha: 1), isMetallic: false)]
        )
        rock.position.y = size * 0.32
        return rock
    }

    private static func foliageColor(theme: RegionTheme) -> UIColor {
        // Slightly tint foliage toward the region's palette so scenery
        // doesn't clash with a desert/night/canyon sky.
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        theme.skyColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let baseGreen = UIColor(red: 0.16, green: 0.42, blue: 0.20, alpha: 1)
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        baseGreen.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let mix: CGFloat = 0.15
        return UIColor(red: br * (1 - mix) + r * mix, green: bg * (1 - mix) + g * mix, blue: bb * (1 - mix) + b * mix, alpha: 1)
    }
}
