import Foundation

/// Persisted audio/haptics/accessibility preferences, pushed into
/// AudioService/HapticsService/ChaseCameraController whenever they change so
/// every gameplay system reads from one place rather than UserDefaults
/// directly (mega-spec sections 36 and 43).
@MainActor
final class SettingsState: ObservableObject {
    @Published var musicVolume: Float {
        didSet { AudioService.shared.musicVolume = musicVolume; persist() }
    }
    @Published var sfxVolume: Float {
        didSet { AudioService.shared.sfxVolume = sfxVolume; persist() }
    }
    @Published var hapticsEnabled: Bool {
        didSet { HapticsService.shared.isEnabled = hapticsEnabled; persist() }
    }
    @Published var reducedMotionEnabled: Bool {
        didSet { ChaseCameraController.reducedMotionEnabled = reducedMotionEnabled; persist() }
    }

    private let saveManager: SaveManager

    init(saveManager: SaveManager = .shared) {
        self.saveManager = saveManager
        let data = saveManager.loadSettings()
        musicVolume = data.musicVolume
        sfxVolume = data.sfxVolume
        hapticsEnabled = data.hapticsEnabled
        reducedMotionEnabled = data.reducedMotionOverride

        AudioService.shared.musicVolume = musicVolume
        AudioService.shared.sfxVolume = sfxVolume
        HapticsService.shared.isEnabled = hapticsEnabled
        ChaseCameraController.reducedMotionEnabled = reducedMotionEnabled
    }

    private func persist() {
        saveManager.saveSettings(SettingsSaveData(
            musicVolume: musicVolume,
            sfxVolume: sfxVolume,
            hapticsEnabled: hapticsEnabled,
            reducedMotionOverride: reducedMotionEnabled
        ))
    }
}
