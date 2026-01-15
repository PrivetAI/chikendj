import SwiftUI

struct EffectsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    var body: some View {
        ZStack {
            // Background
            AppGradients.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Sound Studio")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.text)
                        .padding(.top, 10)
                    
                    // Sound Packs Section
                    SectionView(title: "Sound Pack", icon: "music.note.list") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(SoundPack.allCases, id: \.self) { pack in
                                SoundPackButton(
                                    pack: pack,
                                    isSelected: audioEngine.currentSoundPack == pack
                                ) {
                                    audioEngine.currentSoundPack = pack
                                }
                            }
                        }
                    }
                    
                    // Effect Presets Section
                    SectionView(title: "Effect", icon: "waveform.badge.plus") {
                        HStack(spacing: 10) {
                            ForEach(EffectPreset.allCases, id: \.self) { preset in
                                PresetButton(
                                    preset: preset,
                                    isSelected: audioEngine.currentPreset == preset
                                ) {
                                    audioEngine.currentPreset = preset
                                }
                            }
                        }
                    }
                    
                    // Mixer Section
                    SectionView(title: "Mixer", icon: "slider.horizontal.3") {
                        VStack(spacing: 16) {
                            ForEach(Pad.allPads) { pad in
                                MixerRow(
                                    pad: pad,
                                    volume: Binding(
                                        get: { audioEngine.padVolumes[pad.id] ?? 1.0 },
                                        set: { audioEngine.padVolumes[pad.id] = $0 }
                                    ),
                                    onPlay: {
                                        audioEngine.playSound(forPadId: pad.id)
                                    }
                                )
                            }
                        }
                    }
                    
                    // Master Volume
                    SectionView(title: "Master", icon: "speaker.wave.3") {
                        HStack(spacing: 12) {
                            Image(systemName: "speaker.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                            
                            Slider(value: $audioEngine.masterVolume, in: 0...1)
                                .tint(AppColors.coral)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text("\(Int(audioEngine.masterVolume * 100))%")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.text)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - Section View

struct SectionView<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.coral)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.text)
            }
            
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Sound Pack Button

struct SoundPackButton: View {
    let pack: SoundPack
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? AppColors.coral : AppColors.egg)
                        .frame(height: 60)
                    
                    Image(systemName: pack.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? AppColors.egg : AppColors.coral)
                }
                
                Text(pack.rawValue)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? AppColors.coral : AppColors.text)
                
                Text(pack.description)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let preset: EffectPreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.coral : AppColors.egg)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: preset.icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? AppColors.egg : AppColors.coral)
                }
                
                Text(preset.rawValue)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? AppColors.coral : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Mixer Row

struct MixerRow: View {
    let pad: Pad
    @Binding var volume: Float
    let onPlay: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Play button
            Button(action: onPlay) {
                ZStack {
                    Circle()
                        .fill(AppColors.padColors[pad.color % AppColors.padColors.count])
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
            
            // Pad name
            Text(pad.name)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.text)
                .frame(width: 60, alignment: .leading)
            
            // Volume slider
            Slider(value: $volume, in: 0...1)
                .tint(AppColors.padColors[pad.color % AppColors.padColors.count])
            
            // Volume percentage
            Text("\(Int(volume * 100))%")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 35, alignment: .trailing)
        }
    }
}

#Preview {
    EffectsView()
        .environmentObject(AudioEngine())
}
