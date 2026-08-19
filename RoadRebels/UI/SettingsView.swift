import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsState
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 16) {
                        sliderRow(title: "MUSIC VOLUME", value: $settings.musicVolume)
                        sliderRow(title: "SFX VOLUME", value: $settings.sfxVolume)
                        toggleRow(title: "HAPTICS", isOn: $settings.hapticsEnabled)
                        toggleRow(title: "REDUCED MOTION", isOn: $settings.reducedMotionEnabled)
                    }
                    .padding(20)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
            }
            .accessibilityIdentifier("backButton")
            Spacer()
            Text("SETTINGS")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 38, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func sliderRow(title: String, value: Binding<Float>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
            Slider(value: Binding(get: { Double(value.wrappedValue) }, set: { value.wrappedValue = Float($0) }), in: 0...1)
                .tint(.red)
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
        }
        .tint(.red)
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }
}
