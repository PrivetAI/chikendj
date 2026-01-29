import SwiftUI

struct PadView: View {
    let pad: Pad
    let onTap: () -> Void
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State private var isPressed = false
    @State private var glowIntensity: CGFloat = 0
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    private var padColor: Color {
        AppColors.padColors[pad.color % AppColors.padColors.count]
    }
    
    var body: some View {
        Button(action: {
            triggerTap()
        }) {
            ZStack {
                // Egg shape background
                EggShape()
                    .fill(
                        LinearGradient(
                            colors: [padColor.opacity(0.7), padColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .glow(color: padColor, radius: isIPad ? 20 : 15, isActive: glowIntensity > 0)
                
                // Highlight
                EggShape()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.egg.opacity(0.4), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .padding(isIPad ? 8 : 5)
                
                // Label
                VStack(spacing: 4) {
                    Text(pad.name)
                        .font(.system(size: isIPad ? 22 : 14, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.egg)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            .frame(width: isIPad ? 85 : 70, height: isIPad ? 100 : 85)
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func triggerTap() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Visual feedback
        withAnimation(.easeOut(duration: 0.1)) {
            isPressed = true
            glowIntensity = 1.0
        }
        
        // Callback
        onTap()
        
        // Reset after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                isPressed = false
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.2)) {
                glowIntensity = 0
            }
        }
    }
}

#Preview {
    HStack {
        PadView(pad: Pad.allPads[0]) {}
        PadView(pad: Pad.allPads[1]) {}
    }
    .padding()
    .background(AppColors.background)
}
