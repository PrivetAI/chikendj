import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var loopStorage = LoopStorage()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PlayView()
                .tabItem {
                    Image(systemName: "music.note.house")
                    Text("Play")
                }
                .tag(0)
            
            LoopsView()
                .tabItem {
                    Image(systemName: "repeat")
                    Text("Loops")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(AppColors.coral)
        .environmentObject(loopStorage)
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

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TabBarButton(
                    icon: AnyView(PlayTabIcon()),
                    title: "Play",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                Spacer()
                
                TabBarButton(
                    icon: AnyView(LoopsTabIcon()),
                    title: "Loops",
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
                
                Spacer()
                
                TabBarButton(
                    icon: AnyView(SettingsTabIcon()),
                    title: "Settings",
                    isSelected: selectedTab == 2,
                    action: { selectedTab = 2 }
                )
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
        }
        .background(
            AppColors.surface
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: -4)
        )
    }
}

struct TabBarButton: View {
    let icon: AnyView
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                icon
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? AppColors.coral : AppColors.textSecondary)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? AppColors.coral : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Tab Icons

struct PlayTabIcon: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                
                // House shape with music note inside
                // Roof
                path.move(to: CGPoint(x: w * 0.5, y: 0))
                path.addLine(to: CGPoint(x: w, y: h * 0.4))
                path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.4))
                path.addLine(to: CGPoint(x: w * 0.85, y: h))
                path.addLine(to: CGPoint(x: w * 0.15, y: h))
                path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.4))
                path.addLine(to: CGPoint(x: 0, y: h * 0.4))
                path.closeSubpath()
                
                // Music note (subtractive)
                path.move(to: CGPoint(x: w * 0.55, y: h * 0.35))
                path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.75))
                path.addEllipse(in: CGRect(x: w * 0.35, y: h * 0.65, width: w * 0.22, height: h * 0.2))
            }
            .fill(style: FillStyle(eoFill: true))
        }
    }
}

struct LoopsTabIcon: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let lineWidth: CGFloat = 2
            
            ZStack {
                // Outer loop circle
                Circle()
                    .stroke(lineWidth: lineWidth)
                    .frame(width: w * 0.9, height: h * 0.9)
                
                // Arrow on the loop
                Path { path in
                    // Arrow head pointing right-down
                    path.move(to: CGPoint(x: w * 0.75, y: h * 0.15))
                    path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.25))
                    path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.35))
                }
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                
                // Inner bars (like a playlist)
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 1)
                        .frame(width: w * 0.35, height: 3)
                    RoundedRectangle(cornerRadius: 1)
                        .frame(width: w * 0.25, height: 3)
                    RoundedRectangle(cornerRadius: 1)
                        .frame(width: w * 0.3, height: 3)
                }
            }
            .frame(width: w, height: h)
        }
    }
}

struct SettingsTabIcon: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Gear teeth
                ForEach(0..<6, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .frame(width: w * 0.22, height: h * 0.12)
                        .offset(y: -h * 0.42)
                        .rotationEffect(.degrees(Double(i) * 60))
                }
                
                // Outer circle
                Circle()
                    .stroke(lineWidth: 2.5)
                    .frame(width: w * 0.6, height: h * 0.6)
                
                // Inner circle (hole)
                Circle()
                    .frame(width: w * 0.25, height: h * 0.25)
            }
            .frame(width: w, height: h)
        }
    }
}

#Preview {
    MainTabView()
}

