import CoreHaptics
import Foundation

enum HapticCue {
    case uiTap
    case nearMiss
    case collision
    case attackImpact
    case nitroActivate
    case victory
}

/// Thin Core Haptics wrapper. Simulators and unsupported hardware report
/// `supportsHaptics == false`, in which case every call below is a silent
/// no-op rather than a crash — this is the standard pattern for CH engines.
@MainActor
final class HapticsService {
    static let shared = HapticsService()

    private var engine: CHHapticEngine?
    private let supportsHaptics: Bool
    var isEnabled = true

    private init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        guard supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.resetHandler = { [weak self] in
            try? self?.engine?.start()
        }
        engine?.stoppedHandler = { _ in }
        try? engine?.start()
    }

    func play(_ cue: HapticCue) {
        guard isEnabled, supportsHaptics, let engine else { return }
        guard let pattern = try? CHHapticPattern(events: [event(for: cue)], parameters: []) else { return }
        guard let player = try? engine.makePlayer(with: pattern) else { return }
        try? engine.start()
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    private func event(for cue: HapticCue) -> CHHapticEvent {
        let (intensity, sharpness, eventType): (Float, Float, CHHapticEvent.EventType)
        switch cue {
        case .uiTap: (intensity, sharpness, eventType) = (0.35, 0.4, .hapticTransient)
        case .nearMiss: (intensity, sharpness, eventType) = (0.55, 0.6, .hapticTransient)
        case .collision: (intensity, sharpness, eventType) = (1.0, 0.3, .hapticTransient)
        case .attackImpact: (intensity, sharpness, eventType) = (0.9, 0.8, .hapticTransient)
        case .nitroActivate: (intensity, sharpness, eventType) = (0.7, 0.2, .hapticTransient)
        case .victory: (intensity, sharpness, eventType) = (0.8, 0.5, .hapticTransient)
        }
        return CHHapticEvent(
            eventType: eventType,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: 0
        )
    }
}
