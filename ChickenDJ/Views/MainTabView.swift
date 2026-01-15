import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var loopStorage = LoopStorage()
    @StateObject private var audioEngine = AudioEngine()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PlayView()
                .tabItem {
                    Image(systemName: "music.note.house")
                    Text("Play")
                }
                .tag(0)
            
            EffectsView()
                .tabItem {
                    Image(systemName: "waveform.badge.plus")
                    Text("Effects")
                }
                .tag(1)
            
            LoopsView()
                .tabItem {
                    Image(systemName: "repeat")
                    Text("Loops")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(AppColors.coral)
        .environmentObject(loopStorage)
        .environmentObject(audioEngine)
        .preferredColorScheme(.light)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.surface)
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.textSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.textSecondary)
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.coral)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.coral)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
}
