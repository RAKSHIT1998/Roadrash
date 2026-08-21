import RealityKit
import UIKit
import simd

/// Builds a procedural road mesh (plus sidewalks) by sampling the RoadSpline
/// into ribbons of quads. `buildRoadEntity` builds the whole thing at once
/// for bounded races; `buildRoadChunk` builds just one distance range, for
/// Endless mode to call each time it appends a new segment instead of
/// re-meshing the whole road.
enum RoadBuilder {
    static let sidewalkWidth: Float = 3.0
    static let sidewalkGap: Float = 0.3

    static func buildRoadEntity(spline: RoadSpline, finishDistance: Float) -> Entity {
        let root = Entity()
        root.addChild(buildRoadChunk(spline: spline, from: 0, to: spline.totalLength))
        root.addChild(buildCrossMarker(spline: spline, atDistance: 2, color: .white))
        root.addChild(buildCrossMarker(spline: spline, atDistance: finishDistance, color: .systemRed))
        return root
    }

    static func buildRoadChunk(spline: RoadSpline, from: Float, to: Float) -> Entity {
        let root = Entity()
        root.addChild(buildRibbon(spline: spline, width: GameConstants.roadWidth, centerOffset: 0, yOffset: 0,
                                   color: UIColor(white: 0.16, alpha: 1.0), from: from, to: to))
        root.addChild(buildRibbon(spline: spline, width: 0.18, centerOffset: 0, yOffset: 0.01,
                                   color: UIColor.systemYellow, from: from, to: to))

        let sidewalkCenter = GameConstants.roadWidth / 2 + sidewalkGap + sidewalkWidth / 2
        let sidewalkColor = UIColor(white: 0.62, alpha: 1.0)
        for side: Float in [-1, 1] {
            root.addChild(buildRibbon(spline: spline, width: sidewalkWidth, centerOffset: side * sidewalkCenter, yOffset: 0.08,
                                       color: sidewalkColor, from: from, to: to))
        }
        return root
    }

    /// The lateral distance from road center to the outer edge of the
    /// sidewalk — scenery placed beyond this doesn't stand in the road.
    static var sidewalkOuterEdge: Float {
        GameConstants.roadWidth / 2 + sidewalkGap + sidewalkWidth
    }

    private static func buildRibbon(spline: RoadSpline, width: Float, centerOffset: Float, yOffset: Float, color: UIColor, from: Float, to: Float) -> ModelEntity {
        let sampleSpacing: Float = 5.0
        let halfWidth = width / 2
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []

        // Start one sample before `from` (when possible) so this chunk's
        // ribbon seams seamlessly with the previous chunk's last quad.
        var distance: Float = max(0, from - sampleSpacing)
        var sampleIndex: UInt32 = 0
        while distance <= to {
            let t = spline.transform(atDistance: distance)
            let right = roadRight(forHeading: t.heading)
            let up = SIMD3<Float>(0, yOffset, 0)
            let center = t.position + right * centerOffset
            positions.append(center - right * halfWidth + up)
            positions.append(center + right * halfWidth + up)
            normals.append(SIMD3<Float>(0, 1, 0))
            normals.append(SIMD3<Float>(0, 1, 0))
            uvs.append(SIMD2<Float>(0, distance / 4))
            uvs.append(SIMD2<Float>(1, distance / 4))

            if sampleIndex > 0 {
                let base = (sampleIndex - 1) * 2
                indices.append(contentsOf: [base, base + 1, base + 2])
                indices.append(contentsOf: [base + 1, base + 3, base + 2])
            }
            sampleIndex += 1
            distance += sampleSpacing
        }

        var descriptor = MeshDescriptor(name: "ribbon")
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.textureCoordinates = MeshBuffer(uvs)
        descriptor.primitives = .triangles(indices)

        let mesh = (try? MeshResource.generate(from: [descriptor])) ?? MeshResource.generateBox(size: SIMD3<Float>(width, 0.01, max(1, to - from)))
        let material = SimpleMaterial(color: color, isMetallic: false)
        return ModelEntity(mesh: mesh, materials: [material])
    }

    private static func buildCrossMarker(spline: RoadSpline, atDistance distance: Float, color: UIColor) -> ModelEntity {
        let t = spline.transform(atDistance: distance)
        let right = roadRight(forHeading: t.heading)
        let mesh = MeshResource.generatePlane(width: GameConstants.roadWidth, depth: 2.5)
        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: color, isMetallic: false)])
        entity.position = t.position + SIMD3<Float>(0, 0.02, 0)
        entity.transform.rotation = simd_quatf(angle: t.heading, axis: SIMD3<Float>(0, 1, 0))
        _ = right
        return entity
    }
}
