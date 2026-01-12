import SwiftUI

struct MascotView: View {
    @Binding var isPecking: Bool
    var onTap: (() -> Void)? = nil
    
    @State private var idleOffset: CGFloat = 0
    @State private var peckRotation: Double = 0
    @State private var bounceScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Body (oval)
            Ellipse()
                .fill(AppColors.feather)
                .frame(width: 100, height: 80)
                .shadow(color: AppColors.feather.opacity(0.3), radius: 5)
            
            // Wing left
            Ellipse()
                .fill(AppColors.feather.opacity(0.8))
                .frame(width: 35, height: 25)
                .rotationEffect(.degrees(-30))
                .offset(x: -45, y: 5)
            
            // Wing right
            Ellipse()
                .fill(AppColors.feather.opacity(0.8))
                .frame(width: 35, height: 25)
                .rotationEffect(.degrees(30))
                .offset(x: 45, y: 5)
            
            // Head
            Circle()
                .fill(AppColors.feather)
                .frame(width: 60, height: 60)
                .offset(y: -50)
                .shadow(color: AppColors.feather.opacity(0.3), radius: 3)
            
            // Comb (on top of head)
            CombShape()
                .fill(AppColors.coral)
                .frame(width: 30, height: 25)
                .offset(y: -85)
            
            // Eyes
            HStack(spacing: 20) {
                // Left eye
                ZStack {
                    Circle()
                        .fill(AppColors.egg)
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 10, height: 10)
                        .offset(x: isPecking ? 0 : 2)
                }
                
                // Right eye
                ZStack {
                    Circle()
                        .fill(AppColors.egg)
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 10, height: 10)
                        .offset(x: isPecking ? 0 : 2)
                }
            }
            .offset(y: -52)
            
            // Beak
            BeakShape()
                .fill(AppColors.beak)
                .frame(width: 20, height: 15)
                .offset(y: -35)
                .rotationEffect(.degrees(peckRotation), anchor: .top)
            
            // Feet
            HStack(spacing: 30) {
                FootShape()
                    .stroke(AppColors.beak, lineWidth: 3)
                    .frame(width: 25, height: 20)
                
                FootShape()
                    .stroke(AppColors.beak, lineWidth: 3)
                    .frame(width: 25, height: 20)
            }
            .offset(y: 50)
        }
        .scaleEffect(bounceScale)
        .offset(y: idleOffset)
        .rotationEffect(.degrees(isPecking ? -10 : 0), anchor: .bottom)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPecking)
        .animation(.spring(response: 0.15, dampingFraction: 0.4), value: bounceScale)
        .onTapGesture {
            triggerBounce()
            onTap?()
        }
        .onAppear {
            startIdleAnimation()
        }
        .onChange(of: isPecking) { newValue in
            if newValue {
                peckAnimation()
            }
        }
    }
    
    private func startIdleAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            idleOffset = 5
        }
    }
    
    private func peckAnimation() {
        withAnimation(.easeInOut(duration: 0.1)) {
            peckRotation = 20
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                peckRotation = 0
            }
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

// MARK: - Custom Shapes

struct CombShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.3))
        path.addLine(to: CGPoint(x: w * 0.3, y: h * 0.6))
        path.addLine(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.6))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.3))
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        
        return path
    }
}

struct BeakShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w * 0.5, y: h))
        path.closeSubpath()
        
        return path
    }
}

struct FootShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Three toes with line width
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: 0, y: h))
        
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w * 0.5, y: h))
        
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w, y: h))
        
        return path
    }
}

#Preview {
    MascotView(isPecking: .constant(false))
        .background(AppColors.background)
}
