import SwiftUI

// MARK: - App Colors (Coral/Farm Theme)
struct AppColors {
    // Primary colors
    static let coral = Color(red: 1.0, green: 0.4, blue: 0.3)
    static let coralLight = Color(red: 1.0, green: 0.55, blue: 0.45)
    static let coralDark = Color(red: 0.85, green: 0.3, blue: 0.2)
    
    // Accent colors
    static let egg = Color(red: 1.0, green: 0.95, blue: 0.85)
    static let eggYolk = Color(red: 1.0, green: 0.8, blue: 0.3)
    static let feather = Color(red: 0.95, green: 0.6, blue: 0.2) // Orange feather
    static let beak = Color(red: 1.0, green: 0.7, blue: 0.1)
    
    // Background
    static let background = Color(red: 1.0, green: 0.97, blue: 0.94) // Warm cream
    static let surface = Color(red: 1.0, green: 0.98, blue: 0.95) // Warm white (not pure white)
    
    // Text
    static let text = Color(red: 0.2, green: 0.15, blue: 0.1)
    static let textSecondary = Color(red: 0.5, green: 0.4, blue: 0.35)
    
    // Pad colors (8 unique colors for pads)
    static let padColors: [Color] = [
        Color(red: 1.0, green: 0.4, blue: 0.3),   // Coral (Kick)
        Color(red: 1.0, green: 0.6, blue: 0.2),   // Orange (Snare)
        Color(red: 1.0, green: 0.8, blue: 0.3),   // Yellow (HiHat)
        Color(red: 0.6, green: 0.8, blue: 0.4),   // Green (Clap)
        Color(red: 0.4, green: 0.7, blue: 0.9),   // Blue (Tom)
        Color(red: 0.7, green: 0.5, blue: 0.9),   // Purple (Cymbal)
        Color(red: 0.9, green: 0.5, blue: 0.7),   // Pink (Cowbell)
        Color(red: 0.5, green: 0.8, blue: 0.7)    // Teal (Shaker)
    ]
}

// MARK: - Gradients
struct AppGradients {
    static let coral = LinearGradient(
        colors: [AppColors.coral, AppColors.coralLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let background = LinearGradient(
        colors: [AppColors.background, AppColors.egg],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static func pad(index: Int) -> LinearGradient {
        let color = AppColors.padColors[index % AppColors.padColors.count]
        return LinearGradient(
            colors: [color.opacity(0.8), color],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Custom Button Style
struct CoralButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(AppColors.text)
            .font(.headline)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppGradients.coral)
                    .shadow(color: AppColors.coral.opacity(0.4), radius: configuration.isPressed ? 2 : 6, x: 0, y: configuration.isPressed ? 1 : 3)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Egg Shape
struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Egg shape using bezier curves
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        
        // Right side (top to bottom)
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.55),
            control1: CGPoint(x: width * 0.85, y: 0),
            control2: CGPoint(x: width, y: height * 0.25)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: width, y: height * 0.85),
            control2: CGPoint(x: width * 0.75, y: height)
        )
        
        // Left side (bottom to top)
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.55),
            control1: CGPoint(x: width * 0.25, y: height),
            control2: CGPoint(x: 0, y: height * 0.85)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: 0, y: height * 0.25),
            control2: CGPoint(x: width * 0.15, y: 0)
        )
        
        return path
    }
}

// MARK: - Glow Effect Modifier
struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .shadow(color: isActive ? color.opacity(0.6) : .clear, radius: radius, x: 0, y: 0)
            .shadow(color: isActive ? color.opacity(0.4) : .clear, radius: radius * 1.5, x: 0, y: 0)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 10, isActive: Bool = true) -> some View {
        self.modifier(GlowEffect(color: color, radius: radius, isActive: isActive))
    }
}
