import SwiftUI

struct EffectsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var selectedPreset: EffectPreset? = nil
    
    var body: some View {
        ZStack {
            // Background
            AppGradients.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Effects")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.text)
                        .padding(.top, 10)
                    
                    // Presets Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Presets")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 4)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(EffectPreset.allCases, id: \.self) { preset in
                                PresetButton(
                                    preset: preset,
                                    isSelected: selectedPreset == preset
                                ) {
                                    selectedPreset = preset
                                    audioEngine.applyPreset(preset)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Reverb Section
                    EffectSection(
                        title: "Reverb",
                        icon: "waveform.badge.plus",
                        isEnabled: $audioEngine.reverbEnabled,
                        color: AppColors.coral
                    ) {
                        VStack(spacing: 16) {
                            EffectSlider(
                                label: "Mix",
                                value: $audioEngine.reverbWetDryMix,
                                range: 0...100,
                                unit: "%"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Delay Section
                    EffectSection(
                        title: "Delay",
                        icon: "wave.3.right",
                        isEnabled: $audioEngine.delayEnabled,
                        color: AppColors.padColors[1]
                    ) {
                        VStack(spacing: 16) {
                            EffectSlider(
                                label: "Time",
                                value: Binding(
                                    get: { Float(audioEngine.delayTime * 1000) },
                                    set: { audioEngine.delayTime = TimeInterval($0 / 1000) }
                                ),
                                range: 50...1000,
                                unit: "ms"
                            )
                            
                            EffectSlider(
                                label: "Feedback",
                                value: $audioEngine.delayFeedback,
                                range: 0...90,
                                unit: "%"
                            )
                            
                            EffectSlider(
                                label: "Mix",
                                value: $audioEngine.delayWetDryMix,
                                range: 0...100,
                                unit: "%"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Pitch Section
                    EffectSection(
                        title: "Pitch Shift",
                        icon: "arrow.up.arrow.down",
                        isEnabled: $audioEngine.pitchEnabled,
                        color: AppColors.padColors[4]
                    ) {
                        VStack(spacing: 16) {
                            EffectSlider(
                                label: "Pitch",
                                value: $audioEngine.pitchShift,
                                range: -1200...1200,
                                unit: "cents",
                                showZero: true
                            )
                            
                            // Quick pitch buttons
                            HStack(spacing: 12) {
                                PitchPresetButton(label: "-12", pitch: -1200) { audioEngine.pitchShift = $0 }
                                PitchPresetButton(label: "-5", pitch: -500) { audioEngine.pitchShift = $0 }
                                PitchPresetButton(label: "0", pitch: 0) { audioEngine.pitchShift = $0 }
                                PitchPresetButton(label: "+5", pitch: 500) { audioEngine.pitchShift = $0 }
                                PitchPresetButton(label: "+12", pitch: 1200) { audioEngine.pitchShift = $0 }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Master Volume
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "speaker.wave.3")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.text)
                            
                            Text("Master Volume")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.text)
                        }
                        
                        HStack {
                            Image(systemName: "speaker.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                            
                            Slider(value: $audioEngine.masterVolume, in: 0...1)
                                .tint(AppColors.coral)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text("\(Int(audioEngine.masterVolume * 100))%")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.text)
                                .frame(width: 45, alignment: .trailing)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.surface)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
                .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let preset: EffectPreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.coral : AppColors.surface)
                        .frame(width: 50, height: 50)
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                    
                    Image(systemName: preset.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? AppColors.egg : AppColors.text)
                }
                
                Text(preset.rawValue)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? AppColors.coral : AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Effect Section

struct EffectSection<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isEnabled: Bool
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .tint(color)
                    .labelsHidden()
            }
            
            if isEnabled {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Effect Slider

struct EffectSlider: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let unit: String
    var showZero: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Text(formatValue())
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.text)
            }
            
            Slider(value: $value, in: range)
                .tint(AppColors.coral)
        }
    }
    
    private func formatValue() -> String {
        if showZero && value == 0 {
            return "0 \(unit)"
        }
        if unit == "cents" {
            let prefix = value > 0 ? "+" : ""
            return "\(prefix)\(Int(value)) \(unit)"
        }
        return "\(Int(value)) \(unit)"
    }
}

// MARK: - Pitch Preset Button

struct PitchPresetButton: View {
    let label: String
    let pitch: Float
    let action: (Float) -> Void
    
    var body: some View {
        Button(action: { action(pitch) }) {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.coral)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.coral.opacity(0.1))
                )
        }
    }
}

#Preview {
    EffectsView()
        .environmentObject(AudioEngine())
}
