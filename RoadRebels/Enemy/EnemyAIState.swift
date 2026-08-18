import Foundation

/// A trimmed-down version of the mega-spec's 11-state list (section 16):
/// IDLE/RECOVERING/AVOIDING_TRAFFIC/FALLING are folded into the states below
/// since Phase 3's rivals don't idle, dodge traffic, or get physically
/// unseated yet — the states here are exactly the ones that currently drive
/// visibly different behavior.
enum EnemyAIState: Equatable {
    case racing
    case chasing
    case overtaking
    case attacking
    case defending
    case stunned
    case defeated
}

struct EnemyAIContext {
    let gapToPlayer: Float // player.distance - enemy.distance; positive = player ahead
    let isDefeated: Bool
    let justGotHit: Bool
    let justBlocked: Bool
    let attackRangeReached: Bool
}

/// Pure transition table so it's unit-testable without any RealityKit or
/// timing dependency. `stateTimer` is how long the current state has been
/// held; the caller resets it to 0 whenever the returned state differs from
/// `current`.
enum EnemyAI {
    private static let closeGap: Float = 12
    private static let stunDuration: Float = 0.5
    private static let attackDuration: Float = 0.35
    private static let defendDuration: Float = 0.4

    static func nextState(current: EnemyAIState, stateTimer: Float, context: EnemyAIContext) -> EnemyAIState {
        if context.isDefeated { return .defeated }
        if current == .defeated { return .defeated }

        if context.justBlocked { return .defending }
        if context.justGotHit { return .stunned }

        switch current {
        case .stunned:
            return stateTimer >= stunDuration ? .racing : .stunned
        case .defending:
            return stateTimer >= defendDuration ? .racing : .defending
        case .attacking:
            return stateTimer >= attackDuration ? .racing : .attacking
        default:
            break
        }

        if context.attackRangeReached {
            return .attacking
        }
        if abs(context.gapToPlayer) < closeGap {
            return .overtaking
        }
        return context.gapToPlayer > 0 ? .chasing : .racing
    }
}
