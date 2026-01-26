import SwiftUI

struct MascotView: View {
    @Binding var isPecking: Bool
    var onTap: (() -> Void)? = nil
    
    @State private var idleOffset: CGFloat = 0
    @State private var bounceScale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    var body: some View {
        Image("chicken")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(bounceScale * 1.2)
            .offset(y: idleOffset)
            .rotationEffect(.degrees(isPecking ? -8 : rotation), anchor: .bottom)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPecking)
            .animation(.spring(response: 0.15, dampingFraction: 0.4), value: bounceScale)
            .onTapGesture {
                triggerBounce()
                onTap?()
            }
            .onAppear {
                startIdleAnimation()
            }
    }
    
    private func startIdleAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            idleOffset = 5
            rotation = 2
        }
    }
    
    private func triggerBounce() {
        bounceScale = 1.15
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            bounceScale = 0.95
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                bounceScale = 1.0
            }
        }
    }
}

#Preview {
    MascotView(isPecking: .constant(false))
        .frame(height: 150)
        .background(AppColors.background)
}
