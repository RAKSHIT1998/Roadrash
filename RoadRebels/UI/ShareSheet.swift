import SwiftUI
import UIKit

/// Native iOS share sheet (mega-spec section 49) — text-only share cards,
/// no backend involved. Wraps UIActivityViewController since SwiftUI has no
/// first-class equivalent.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum ShareText {
    static func raceResult(_ result: RaceResult) -> String {
        var lines = ["ROAD REBELS"]
        if let raceID = result.careerRaceID, let race = CareerContent.race(withID: raceID), race.isBossRace, result.didWin {
            lines.append("\(race.name.uppercased()) — BOSS DEFEATED")
        }
        lines.append(placeLabel(result.position) + " PLACE")
        lines.append(String(format: "TIME %.1fs", result.elapsedTime))
        lines.append("\(result.nearMisses) NEAR MISSES")
        lines.append("RIDE WITH ME.")
        return lines.joined(separator: "\n")
    }

    static func endlessResult(_ result: EndlessResult) -> String {
        [
            "ROAD REBELS — HIGHWAY RUSH",
            "SCORE \(result.score)",
            String(format: "%.0fm TRAVELED", result.distance),
            "\(result.nearMisses) NEAR MISSES",
            "BEAT MY SCORE.",
        ].joined(separator: "\n")
    }

    private static func placeLabel(_ position: Int) -> String {
        switch position {
        case 1: return "1ST"
        case 2: return "2ND"
        case 3: return "3RD"
        default: return "\(position)TH"
        }
    }
}
