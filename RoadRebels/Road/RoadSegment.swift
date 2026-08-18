import simd

/// A single piece of the road centerline: either straight (curvature 0) or a
/// constant-curvature arc. Distance is measured along the centerline in meters.
struct RoadPathElement {
    let startDistance: Float
    let length: Float
    let startPosition: SIMD3<Float>
    let startHeading: Float   // radians, 0 = forward along -Z, positive turns right (+X)
    let curvature: Float      // 0 = straight, else 1/radius (signed)

    var endDistance: Float { startDistance + length }
    var endHeading: Float { startHeading + curvature * length }
}

func roadForward(forHeading heading: Float) -> SIMD3<Float> {
    SIMD3<Float>(sin(heading), 0, -cos(heading))
}

func roadRight(forHeading heading: Float) -> SIMD3<Float> {
    SIMD3<Float>(cos(heading), 0, sin(heading))
}

/// Analytic centerline built from straight + arc segments. Phase 1 uses a single
/// fixed spline (one curve); the infinite procedural version arrives in Phase 6.
struct RoadSpline {
    let elements: [RoadPathElement]
    let totalLength: Float

    init(elements: [RoadPathElement]) {
        self.elements = elements
        self.totalLength = elements.last?.endDistance ?? 0
    }

    /// World-space position, forward direction, and heading at a given distance
    /// along the centerline, offset laterally (positive = right of center).
    func transform(atDistance distance: Float, lateralOffset: Float = 0) -> (position: SIMD3<Float>, forward: SIMD3<Float>, heading: Float) {
        let clamped = max(0, min(distance, totalLength))
        guard let element = elements.last(where: { clamped >= $0.startDistance }) ?? elements.first else {
            return (.zero, roadForward(forHeading: 0), 0)
        }
        let s = clamped - element.startDistance
        let heading = element.startHeading + element.curvature * s
        let forward = roadForward(forHeading: heading)
        let right = roadRight(forHeading: heading)

        let centerPosition: SIMD3<Float>
        if abs(element.curvature) < 1e-6 {
            centerPosition = element.startPosition + roadForward(forHeading: element.startHeading) * s
        } else {
            let radius = 1 / element.curvature
            let startRight = roadRight(forHeading: element.startHeading)
            let arcCenter = element.startPosition + startRight * radius
            centerPosition = arcCenter - right * radius
        }

        let worldPosition = centerPosition + right * lateralOffset
        return (worldPosition, forward, heading)
    }

    /// Builds a straight/curve/straight spline scaled to fit `totalLength`,
    /// used both for the fixed Phase 1 road and for Career races of varying
    /// distance. A proper chunked/streaming procedural generator (mega-spec
    /// section 39) is a larger, later change; this analytic version is
    /// enough for single, bounded-length races.
    static func generate(totalLength: Float) -> RoadSpline {
        let straightALength = min(400, totalLength * 0.35)
        let straightA = RoadPathElement(
            startDistance: 0,
            length: straightALength,
            startPosition: .zero,
            startHeading: 0,
            curvature: 0
        )
        let curveRadius: Float = 150
        let curveAngle: Float = .pi / 3 // 60 degree sweep to the right
        let curve = RoadPathElement(
            startDistance: straightA.endDistance,
            length: curveRadius * curveAngle,
            startPosition: RoadSpline(elements: [straightA]).transform(atDistance: straightA.endDistance).position,
            startHeading: straightA.endHeading,
            curvature: 1 / curveRadius
        )
        let curveEndTransform = RoadSpline(elements: [straightA, curve]).transform(atDistance: curve.endDistance)
        let straightB = RoadPathElement(
            startDistance: curve.endDistance,
            length: max(50, totalLength - curve.endDistance),
            startPosition: curveEndTransform.position,
            startHeading: curve.endHeading,
            curvature: 0
        )
        return RoadSpline(elements: [straightA, curve, straightB])
    }

    static func standardPhase1() -> RoadSpline {
        generate(totalLength: GameConstants.roadLength)
    }
}
