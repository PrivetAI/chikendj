import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var loopStorage: LoopStorage
    @EnvironmentObject var audioEngine: AudioEngine
    
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("metronomeSound") private var metronomeSound = true
    @AppStorage("quantizeStrength") private var quantizeStrength: Double = 0.5
    
    @State private var showingClearAlert = false
    @State private var showingResetEffectsAlert = false
    
    var body: some View {
        ZStack {
            // Background
            AppGradients.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                Text("Settings")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.text)
                    .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Audio section
                        SettingsSectionHeader(title: "Audio")
                        
                        SettingsRow(
                            icon: "speaker.wave.3",
                            title: "Master Volume",
                            subtitle: "\(Int(audioEngine.masterVolume * 100))%"
                        ) {
                            Slider(value: $audioEngine.masterVolume, in: 0...1)
                                .tint(AppColors.coral)
                                .frame(width: 100)
                        }
                        
                        SettingsRow(
                            icon: "metronome",
                            title: "Metronome Sound",
                            subtitle: "Play click on each beat"
                        ) {
                            Toggle("", isOn: $metronomeSound)
                                .tint(AppColors.coral)
                        }
                        
                        // Feedback section
                        SettingsSectionHeader(title: "Feedback")
                        
                        SettingsRow(
                            icon: "hand.tap",
                            title: "Haptic Feedback",
                            subtitle: "Vibrate when tapping pads"
                        ) {
                            Toggle("", isOn: $hapticEnabled)
                                .tint(AppColors.coral)
                        }
                        
                        // Data section
                        SettingsSectionHeader(title: "Data")
                        
                        SettingsInfoRow(
                            icon: "music.note.list",
                            title: "Saved Loops",
                            value: "\(loopStorage.savedLoops.count)"
                        )
                        
                        // Reset effects button
                        Button(action: {
                            showingResetEffectsAlert = true
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppColors.coral.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "waveform.slash")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppColors.coral)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Reset Sound Settings")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(AppColors.text)
                                    
                                    Text("Reset mixer and effects")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppColors.surface)
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            )
                        }
                        
                        // Clear all loops button
                        Button(action: {
                            showingClearAlert = true
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.red.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "trash")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Clear All Loops")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.red)
                                    
                                    Text("Delete all saved loops")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppColors.surface)
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            )
                        }
                        .disabled(loopStorage.savedLoops.isEmpty)
                        .opacity(loopStorage.savedLoops.isEmpty ? 0.5 : 1.0)
                        
                        // About section
                        SettingsSectionHeader(title: "About")
                        
                        SettingsInfoRow(
                            icon: "info.circle",
                            title: "Version",
                            value: "1.1"
                        )
                        
                        SettingsInfoRow(
                            icon: "music.note",
                            title: "App",
                            value: "Chicken DJ"
                        )
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .preferredColorScheme(.light)
        .alert("Clear All Loops", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                loopStorage.clearAllLoops()
            }
        } message: {
            Text("Are you sure you want to delete all saved loops? This action cannot be undone.")
        }
        .alert("Reset Settings", isPresented: $showingResetEffectsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                audioEngine.currentPreset = .normal
                audioEngine.currentSoundPack = .classic
                audioEngine.masterVolume = 1.0
                for pad in Pad.allPads {
                    audioEngine.padVolumes[pad.id] = 1.0
                }
            }
        } message: {
            Text("Reset all sound settings to default?")
        }
    }
}

// MARK: - Settings Section Header

struct SettingsSectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            Spacer()
        }
        .padding(.top, 8)
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder let control: () -> Content
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.coral.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.coral)
            }
            
            // Labels
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.text)
                
                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Control
            control()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(AppColors.text)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

#Preview {
    SettingsView()
        .environmentObject(LoopStorage())
        .environmentObject(AudioEngine())
}
