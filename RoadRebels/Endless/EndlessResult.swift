import Foundation

enum EndlessEndReason: Equatable {
    case wrecked
    case busted
}

struct EndlessResult: Equatable {
    let distance: Float
    let nearMisses: Int
    let score: Int
    let reason: EndlessEndReason

    init(distance: Float, nearMisses: Int, score: Int, reason: EndlessEndReason = .wrecked) {
        self.distance = distance
        self.nearMisses = nearMisses
        self.score = score
        self.reason = reason
    }
}
