import QuartzCore
import Foundation

/// Fixed-timestep driver on top of CADisplayLink. Accumulates real elapsed
/// time and calls `onStep` a whole number of times per frame so gameplay
/// (physics, AI, combat) is deterministic regardless of display refresh rate.
@MainActor
final class GameLoop {
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private var accumulator: Double = 0
    private let onStep: (Float) -> Void

    init(onStep: @escaping (Float) -> Void) {
        self.onStep = onStep
    }

    func start() {
        stop()
        lastTimestamp = nil
        accumulator = 0
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        let timestamp = link.timestamp
        defer { lastTimestamp = timestamp }
        guard let last = lastTimestamp else { return }

        let delta = min(timestamp - last, 0.25) // clamp to avoid spiral of death on hitches
        accumulator += delta

        let step = GameConstants.fixedTimestep
        var iterations = 0
        while accumulator >= step, iterations < 8 {
            onStep(Float(step))
            accumulator -= step
            iterations += 1
        }
    }
}
