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
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Play button
                Button(action: onPlay) {
                    ZStack {
                        Circle()
                            .fill(AppColors.coral)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.egg)
                    }
                }
                
                // Info and pattern preview
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(loop.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                        
                        Text("\(loop.loop.events.count) notes")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    // Mini pattern preview
                    LoopPatternView(loop: loop.loop, height: 24)
                }
                
                // Expand/Delete buttons
                VStack(spacing: 8) {
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(14)
            
            // Expanded detail view
            if isExpanded {
                Divider()
                    .background(AppColors.textSecondary.opacity(0.2))
                
                DetailedLoopPatternView(loop: loop.loop)
                    .padding(14)
            }
        }
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
