import Foundation

enum TutorialStep: Equatable {
    case steer
    case attack
    case brake
    case nitro
    case finish
    case none

    var message: String {
        switch self {
        case .steer: return "SWIPE THE LEFT SIDE TO STEER — THROTTLE IS AUTOMATIC"
        case .attack: return "TAP TOP-RIGHT TO ATTACK A RIVAL ALONGSIDE YOU"
        case .brake: return "HOLD BOTTOM-RIGHT TO BRAKE THROUGH TRAFFIC"
        case .nitro: return "NITRO'S FULL — HOLD MIDDLE-RIGHT TO BOOST"
        case .finish: return "ALMOST THERE — CROSS THE FINISH LINE"
        case .none: return ""
        }
    }
}

/// Pure selection of which tip to show given live race telemetry, so this is
/// unit-testable without SwiftUI or a running race. Progress thresholds are
/// deliberately wide, non-blocking windows — the player never has to
/// perform the action to advance, the game just keeps surfacing the next
/// relevant tip as the race naturally unfolds.
enum TutorialStepSelector {
    static func step(elapsedTime: TimeInterval, raceProgress: Float, nitroMeter: Float) -> TutorialStep {
        if raceProgress >= 0.92 {
            return .finish
        }
        if nitroMeter >= 1 {
            return .nitro
        }
        if raceProgress >= 0.45 {
            return .brake
        }
        if raceProgress >= 0.18 {
            return .attack
        }
        if elapsedTime <= 4.5 {
            return .steer
        }
        return .none
    }
}
