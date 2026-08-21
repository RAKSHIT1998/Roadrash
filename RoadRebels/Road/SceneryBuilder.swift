import RealityKit
import UIKit
import simd

/// Scatters roadside scenery so the route reads as a real place rather than
/// a bare strip of gray — same "no real art needed" approach as the rest of
/// the scene, built purely from primitives. Rural regions get trees/rocks/
/// signs; urban regions (Neon Coast, Nightfall City) get a GTA-style city
/// street instead: buildings, sidewalks with walking pedestrians, parked
/// cars, and street lamps.
enum SceneryBuilder {
    static func buildProps(spline: RoadSpline, from: Float, to: Float, theme: RegionTheme) -> Entity {
        let root = Entity()
        var distance = max(0, from)
        let spacing: Float = 30

        while distance < to {
            for side: Float in [-1, 1] {
                guard Float.random(in: 0...1) < 0.6 else { continue }
                let prop = theme.isUrban ? buildRandomUrbanProp() : buildRandomRuralProp(theme: theme)
                let lateralOffset = offset(for: prop.bias, side: side)
                let t = spline.transform(atDistance: distance, lateralOffset: lateralOffset)
                let facing = t.heading + .pi / 2 * side

                prop.entity.position = t.position
                prop.entity.transform.rotation = simd_quatf(
                    angle: prop.isFacingSensitive ? facing : Float.random(in: 0...(.pi * 2)),
                    axis: SIMD3<Float>(0, 1, 0)
                )
                root.addChild(prop.entity)
            }
            distance += spacing
        }
        return root
    }

    // MARK: - Placement

    private enum LateralBias {
        case near      // rural scenery, just past the sidewalk
        case sidewalk  // pedestrians, walking the sidewalk band
        case curb      // parked cars / lamp posts, right at the road edge
        case far       // buildings, set back behind the sidewalk
    }

    private struct Prop {
        let entity: Entity
        var isFacingSensitive = false
        var bias: LateralBias = .near
    }

    private static func offset(for bias: LateralBias, side: Float) -> Float {
        let halfRoad = GameConstants.roadWidth / 2
        switch bias {
        case .near:
            return side * (halfRoad + Float.random(in: 4...16))
        case .sidewalk:
            let sidewalkCenter = halfRoad + RoadBuilder.sidewalkGap + RoadBuilder.sidewalkWidth / 2
            return side * (sidewalkCenter + Float.random(in: -0.8...0.8))
        case .curb:
            return side * (halfRoad + Float.random(in: 0.8...1.6))
        case .far:
            return side * (RoadBuilder.sidewalkOuterEdge + Float.random(in: 2...18))
        }
    }

    // MARK: - Rural props

    private static func buildRandomRuralProp(theme: RegionTheme) -> Prop {
        switch Float.random(in: 0...1) {
        case ..<0.40: return Prop(entity: buildTree(theme: theme), bias: .near)
        case ..<0.58: return Prop(entity: buildRock(), bias: .near)
        case ..<0.82: return Prop(entity: buildStreetSign(), isFacingSensitive: true, bias: .curb)
        default: return Prop(entity: buildLampPost(), bias: .curb)
        }
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

    private struct StreetSignSpec {
        let text: String
        let background: UIColor
        let textColor: UIColor
        let size: SIMD3<Float>
    }

    private static let streetSignSpecs: [StreetSignSpec] = [
        .init(text: "STOP", background: UIColor(red: 0.72, green: 0.05, blue: 0.06, alpha: 1), textColor: .white, size: SIMD3(0.55, 0.55, 0.06)),
        .init(text: "YIELD", background: .white, textColor: UIColor(red: 0.72, green: 0.05, blue: 0.06, alpha: 1), size: SIMD3(0.55, 0.5, 0.06)),
        .init(text: "SPEED\nLIMIT 45", background: .white, textColor: .black, size: SIMD3(0.5, 0.62, 0.06)),
        .init(text: "ONE WAY", background: UIColor(white: 0.1, alpha: 1), textColor: .white, size: SIMD3(0.7, 0.32, 0.06)),
        .init(text: "NO\nPARKING", background: .white, textColor: UIColor(red: 0.72, green: 0.05, blue: 0.06, alpha: 1), size: SIMD3(0.5, 0.55, 0.06)),
        .init(text: "MAIN ST", background: UIColor(red: 0.05, green: 0.32, blue: 0.18, alpha: 1), textColor: .white, size: SIMD3(0.75, 0.32, 0.06)),
        .init(text: "SCHOOL\nZONE", background: UIColor(red: 0.95, green: 0.85, blue: 0.1, alpha: 1), textColor: .black, size: SIMD3(0.55, 0.55, 0.06)),
    ]

    private static func buildStreetSign() -> Entity {
        let root = Entity()
        let post = ModelEntity(
            mesh: .generateCylinder(height: 2.1, radius: 0.05),
            materials: [SimpleMaterial(color: UIColor(white: 0.55, alpha: 1), isMetallic: true)]
        )
        post.position.y = 1.05
        root.addChild(post)

        let spec = streetSignSpecs.randomElement() ?? streetSignSpecs[0]
        let sign = ModelEntity(
            mesh: .generateBox(size: spec.size, cornerRadius: 0.05),
            materials: [SignTextureFactory.material(text: spec.text, background: spec.background, textColor: spec.textColor)]
        )
        sign.position.y = 1.95
        root.addChild(sign)
        return root
    }

    private static func foliageColor(theme: RegionTheme) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        theme.skyColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let baseGreen = UIColor(red: 0.16, green: 0.42, blue: 0.20, alpha: 1)
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        baseGreen.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let mix: CGFloat = 0.15
        return UIColor(red: br * (1 - mix) + r * mix, green: bg * (1 - mix) + g * mix, blue: bb * (1 - mix) + b * mix, alpha: 1)
    }

    // MARK: - Urban props

    private static func buildRandomUrbanProp() -> Prop {
        switch Float.random(in: 0...1) {
        case ..<0.34: return Prop(entity: buildBuilding(), isFacingSensitive: true, bias: .far)
        case ..<0.64: return Prop(entity: buildPedestrian(), isFacingSensitive: true, bias: .sidewalk)
        case ..<0.86: return Prop(entity: buildParkedCar(), isFacingSensitive: true, bias: .curb)
        default: return Prop(entity: buildLampPost(), bias: .curb)
        }
    }

    private static let shopNames = [
        "DINER", "CITY MART", "GARAGE", "PIZZA CO", "CAFE 24", "LAUNDRY",
        "BARBER SHOP", "MOTEL", "PAWN SHOP", "AUTO PARTS", "DONUT HOUSE", "ARCADE",
    ]

    private static func buildBuilding() -> Entity {
        let container = Entity()
        let palette: [UIColor] = [
            UIColor(white: 0.55, alpha: 1),
            UIColor(red: 0.45, green: 0.28, blue: 0.22, alpha: 1),
            UIColor(red: 0.32, green: 0.42, blue: 0.52, alpha: 1),
            UIColor(white: 0.32, alpha: 1),
            UIColor(red: 0.5, green: 0.42, blue: 0.38, alpha: 1),
        ]
        let width = Float.random(in: 5...10)
        let depth = Float.random(in: 5...10)
        let height = Float.random(in: 6...28)

        let body = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(width, height, depth)),
            materials: [SimpleMaterial(color: palette.randomElement() ?? .gray, isMetallic: false)]
        )
        body.position.y = height / 2
        container.addChild(body)

        let windowColor = UIColor(red: 1.0, green: 0.88, blue: 0.55, alpha: 1)
        let floors = max(1, Int(height / 3))
        for floor in 0..<floors {
            guard Bool.random() else { continue }
            let band = ModelEntity(
                mesh: .generateBox(size: SIMD3<Float>(width * 0.92, 0.35, depth + 0.04)),
                materials: [SimpleMaterial(color: windowColor, isMetallic: false)]
            )
            band.position.y = Float(floor) * 3 + 2.0
            container.addChild(band)
        }

        if Bool.random() {
            let name = shopNames.randomElement() ?? "SHOP"
            let signWidth = min(width * 0.85, 4.0)
            let material = SignTextureFactory.material(text: name, background: UIColor(white: 0.04, alpha: 1), textColor: signAccentColor())
            for zSide: Float in [1, -1] {
                let storefront = ModelEntity(
                    mesh: .generateBox(size: SIMD3<Float>(signWidth, 0.65, 0.06), cornerRadius: 0.02),
                    materials: [material]
                )
                storefront.position = SIMD3<Float>(0, 1.6, zSide * (depth / 2 + 0.05))
                container.addChild(storefront)
            }
        }
        return container
    }

    private static func signAccentColor() -> UIColor {
        [UIColor.white, UIColor.systemYellow, UIColor(red: 0.4, green: 0.9, blue: 1.0, alpha: 1), UIColor.systemOrange].randomElement() ?? .white
    }

    /// A simple jointed figure — same idea as the rider on the bike, just
    /// lighter-weight since these are purely decorative background extras.
    private static func buildPedestrian() -> Entity {
        let container = Entity()
        let clothing: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple, .darkGray, .systemTeal]
        let shirtColor = clothing.randomElement() ?? .darkGray
        let pantsColor = UIColor(white: CGFloat.random(in: 0.15...0.35), alpha: 1)
        let skinColor = UIColor(red: 0.75, green: 0.55, blue: 0.42, alpha: 1)

        let torso = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.36, 0.5, 0.22), cornerRadius: 0.08),
            materials: [SimpleMaterial(color: shirtColor, isMetallic: false)]
        )
        torso.position.y = 1.05
        container.addChild(torso)

        let head = ModelEntity(mesh: .generateSphere(radius: 0.14), materials: [SimpleMaterial(color: skinColor, isMetallic: false)])
        head.position.y = 1.46
        container.addChild(head)

        for legX: Float in [-0.09, 0.09] {
            let leg = ModelEntity(
                mesh: .generateBox(size: SIMD3<Float>(0.14, 0.85, 0.16), cornerRadius: 0.05),
                materials: [SimpleMaterial(color: pantsColor, isMetallic: false)]
            )
            leg.position = SIMD3<Float>(legX, 0.42, Float.random(in: -0.15...0.15))
            container.addChild(leg)
        }
        for armX: Float in [-0.25, 0.25] {
            let arm = ModelEntity(
                mesh: .generateBox(size: SIMD3<Float>(0.11, 0.48, 0.11), cornerRadius: 0.04),
                materials: [SimpleMaterial(color: shirtColor, isMetallic: false)]
            )
            arm.position = SIMD3<Float>(armX, 1.06, 0)
            container.addChild(arm)
        }
        return container
    }

    private static func buildParkedCar() -> Entity {
        let palette: [UIColor] = [.systemGray, .white, .black, .systemBlue, .systemRed, .systemGreen]
        let body = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(1.7, 1.15, 3.4), cornerRadius: 0.15),
            materials: [SimpleMaterial(color: palette.randomElement() ?? .systemGray, isMetallic: false)]
        )
        body.position.y = 0.58
        let container = Entity()
        container.addChild(body)
        return container
    }

    private static func buildLampPost() -> Entity {
        let root = Entity()
        let pole = ModelEntity(
            mesh: .generateCylinder(height: 3.4, radius: 0.06),
            materials: [SimpleMaterial(color: UIColor(white: 0.25, alpha: 1), isMetallic: true)]
        )
        pole.position.y = 1.7
        root.addChild(pole)

        let lamp = ModelEntity(
            mesh: .generateSphere(radius: 0.16),
            materials: [SimpleMaterial(color: UIColor(red: 1.0, green: 0.92, blue: 0.7, alpha: 1), isMetallic: false)]
        )
        lamp.position.y = 3.45
        root.addChild(lamp)
        return root
    }
}
