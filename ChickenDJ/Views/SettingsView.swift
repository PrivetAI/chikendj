import SwiftUI

struct SettingsView: View {
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    
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
                        // Haptic feedback toggle
                        SettingsRow(
                            icon: "hand.tap",
                            title: "Haptic Feedback",
                            subtitle: "Vibrate when tapping pads"
                        ) {
                            Toggle("", isOn: $hapticEnabled)
                                .tint(AppColors.coral)
                        }
                        
                        // About section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            SettingsInfoRow(
                                icon: "info.circle",
                                title: "Version",
                                value: "1.0"
                            )
                            
                            SettingsInfoRow(
                                icon: "music.note",
                                title: "App",
                                value: "Chicken DJ"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.light)
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
}
