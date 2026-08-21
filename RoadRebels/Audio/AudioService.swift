import AVFoundation
import Foundation

enum SFXCue: String {
    case uiTap
    case engineRev
    case attackHit
    case collision
    case nitro
    case victory
    case defeat
    case siren
}

/// Abstraction over sound effect/music playback. Looks for an audio asset
/// named after each cue's rawValue in the app bundle and no-ops if it isn't
/// there yet — Phase 2 wires every gameplay call site through this so real
/// audio (mega-spec section 35) drops in later without touching gameplay
/// code. No copyrighted audio is bundled.
@MainActor
final class AudioService {
    static let shared = AudioService()

    var sfxVolume: Float = 1.0
    var musicVolume: Float = 1.0
    var isMuted = false

    private var players: [SFXCue: AVAudioPlayer] = [:]

    private init() {}

    func play(_ cue: SFXCue) {
        guard !isMuted else { return }
        if let existing = players[cue] {
            existing.volume = sfxVolume
            existing.currentTime = 0
            existing.play()
            return
        }
        guard let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "caf")
            ?? Bundle.main.url(forResource: cue.rawValue, withExtension: "mp3")
            ?? Bundle.main.url(forResource: cue.rawValue, withExtension: "wav")
        else {
            return // Placeholder: no asset yet, silently skip.
        }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = sfxVolume
        player.prepareToPlay()
        players[cue] = player
        player.play()
    }
}
