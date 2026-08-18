import RealityKit
import UIKit

/// Procedural particle bursts/trails built directly from ParticleEmitterComponent
/// rather than external VFX assets, so hit sparks and the nitro exhaust trail
/// work without any bundled art.
enum ImpactEffects {
    static func spawnHitSpark(at position: SIMD3<Float>, in parent: Entity) {
        let entity = Entity()
        entity.position = position
        parent.addChild(entity)

        var emitter = ParticleEmitterComponent()
        emitter.emitterShape = .sphere
        emitter.burstCount = 26
        emitter.burstCountVariation = 6
        emitter.speed = 2.2
        emitter.speedVariation = 1.2
        emitter.mainEmitter.birthRate = 0
        emitter.mainEmitter.lifeSpan = 0.28
        emitter.mainEmitter.lifeSpanVariation = 0.08
        emitter.mainEmitter.size = 0.035
        emitter.mainEmitter.color = .evolving(
            start: .single(.orange),
            end: .single(UIColor.orange.withAlphaComponent(0))
        )
        emitter.mainEmitter.acceleration = SIMD3<Float>(0, -3, 0)
        emitter.burst()
        entity.components.set(emitter)

        removeAfterDelay(entity, delay: 0.6)
    }

    static func attachNitroTrail(to entity: Entity) -> Entity {
        let trail = Entity()
        trail.position = SIMD3<Float>(0, 0.4, 0.9)
        entity.addChild(trail)

        var emitter = ParticleEmitterComponent()
        emitter.emitterShape = .point
        emitter.speed = 1.2
        emitter.speedVariation = 0.4
        emitter.mainEmitter.birthRate = 0 // toggled on/off via setNitroTrail(active:)
        emitter.mainEmitter.lifeSpan = 0.4
        emitter.mainEmitter.size = 0.06
        emitter.mainEmitter.color = .evolving(
            start: .single(.cyan),
            end: .single(UIColor.cyan.withAlphaComponent(0))
        )
        trail.components.set(emitter)
        return trail
    }

    static func setNitroTrail(_ trailEntity: Entity, active: Bool) {
        guard var emitter = trailEntity.components[ParticleEmitterComponent.self] else { return }
        emitter.mainEmitter.birthRate = active ? 400 : 0
        trailEntity.components.set(emitter)
    }

    private static func removeAfterDelay(_ entity: Entity, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            entity.removeFromParent()
        }
    }
}
