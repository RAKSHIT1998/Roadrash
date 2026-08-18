import RealityKit
import UIKit
import simd

/// Builds a procedural road mesh by sampling the RoadSpline into a ribbon of
/// quads. Phase 1 has one fixed spline; Phase 6 swaps this for chunked,
/// streaming procedural generation without touching the sampling math here.
enum RoadBuilder {
    static func buildRoadEntity(spline: RoadSpline) -> Entity {
        let root = Entity()
        root.addChild(buildRibbon(spline: spline, width: GameConstants.roadWidth, yOffset: 0,
                                   color: UIColor(white: 0.16, alpha: 1.0)))
        root.addChild(buildRibbon(spline: spline, width: 0.18, yOffset: 0.01,
                                   color: UIColor.systemYellow))
        root.addChild(buildCrossMarker(spline: spline, atDistance: 2, color: .white))
        root.addChild(buildCrossMarker(spline: spline, atDistance: GameConstants.raceDistance, color: .systemRed))
        return root
    }

    private static func buildRibbon(spline: RoadSpline, width: Float, yOffset: Float, color: UIColor) -> ModelEntity {
        let sampleSpacing: Float = 5.0
        let halfWidth = width / 2
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []

        var distance: Float = 0
        var sampleIndex: UInt32 = 0
        while distance <= spline.totalLength {
            let t = spline.transform(atDistance: distance)
            let right = roadRight(forHeading: t.heading)
            let up = SIMD3<Float>(0, yOffset, 0)
            positions.append(t.position - right * halfWidth + up)
            positions.append(t.position + right * halfWidth + up)
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

        let mesh = (try? MeshResource.generate(from: [descriptor])) ?? MeshResource.generateBox(size: SIMD3<Float>(width, 0.01, spline.totalLength))
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
