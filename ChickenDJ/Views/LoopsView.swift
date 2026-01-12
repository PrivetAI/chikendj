import SwiftUI

struct LoopsView: View {
    @EnvironmentObject var loopStorage: LoopStorage
    @State private var selectedLoop: SavedLoop?
    
    var body: some View {
        ZStack {
            // Background
            AppGradients.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                Text("My Loops")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.text)
                    .padding(.top, 10)
                
                if loopStorage.savedLoops.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        
                        // Empty illustration
                        ZStack {
                            Circle()
                                .fill(AppColors.egg)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "music.note.list")
                                .font(.system(size: 50))
                                .foregroundColor(AppColors.coral.opacity(0.5))
                        }
                        
                        Text("No saved loops yet")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.text)
                        
                        Text("Record a loop in Play tab\nand save it here")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                } else {
                    // Loops list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(loopStorage.savedLoops) { loop in
                                LoopRowView(loop: loop) {
                                    selectedLoop = loop
                                } onDelete: {
                                    loopStorage.deleteLoop(loop)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

struct LoopRowView: View {
    let loop: SavedLoop
    let onPlay: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Play button
            Button(action: onPlay) {
                ZStack {
                    Circle()
                        .fill(AppColors.coral)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.egg)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(loop.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.text)
                
                Text("\(loop.loop.events.count) notes • \(loop.loop.bpm) BPM")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    LoopsView()
        .environmentObject(LoopStorage())
}
