import SwiftUI

/// Visual representation of a loop pattern showing events on a timeline
struct LoopPatternView: View {
    let loop: Loop
    let height: CGFloat
    
    init(loop: Loop, height: CGFloat = 50) {
        self.loop = loop
        self.height = height
    }
    
    private var duration: TimeInterval {
        max(loop.duration, 1.0) // Minimum 1 second
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.surface)
                
                // Timeline grid
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { i in
                        Rectangle()
                            .fill(AppColors.textSecondary.opacity(0.2))
                            .frame(width: 1)
                        Spacer()
                    }
                }
                .padding(.horizontal, 4)
                
                // Event markers
                ForEach(loop.events) { event in
                    eventMarker(for: event, in: geo.size)
                }
            }
        }
        .frame(height: height)
    }
    
    private func eventMarker(for event: LoopEvent, in size: CGSize) -> some View {
        let xPosition = (event.timestamp / duration) * Double(size.width - 16) + 8
        let padColor = getPadColor(for: event.padId)
        
        return Circle()
            .fill(padColor)
            .frame(width: 12, height: 12)
            .shadow(color: padColor.opacity(0.5), radius: 3)
            .position(x: xPosition, y: size.height / 2)
    }
    
    private func getPadColor(for padId: Int) -> Color {
        let colors: [Color] = [
            AppColors.coral,      // 0: Kick
            Color.orange,         // 1: Snare
            Color.yellow,         // 2: HiHat
            Color.pink,           // 3: Clap
            Color.purple,         // 4: Tom
            Color.cyan,           // 5: Cymbal
            Color.green,          // 6: Cowbell
            Color.mint            // 7: Shaker
        ]
        return padId < colors.count ? colors[padId] : AppColors.coral
    }
}

/// Detailed loop pattern view with instrument labels
struct DetailedLoopPatternView: View {
    let loop: Loop
    
    private var groupedEvents: [Int: [LoopEvent]] {
        Dictionary(grouping: loop.events) { $0.padId }
    }
    
    private var duration: TimeInterval {
        max(loop.duration, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Timeline header
            HStack {
                Text("0s")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(String(format: "%.1fs", duration))
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 4)
            
            // Tracks for each used pad
            ForEach(Array(groupedEvents.keys.sorted()), id: \.self) { padId in
                HStack(spacing: 8) {
                    // Pad name
                    Text(getPadName(for: padId))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 50, alignment: .leading)
                    
                    // Track
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Track background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.background.opacity(0.5))
                            
                            // Events
                            ForEach(groupedEvents[padId] ?? []) { event in
                                Circle()
                                    .fill(getPadColor(for: padId))
                                    .frame(width: 10, height: 10)
                                    .position(
                                        x: (event.timestamp / duration) * Double(geo.size.width - 10) + 5,
                                        y: geo.size.height / 2
                                    )
                            }
                        }
                    }
                    .frame(height: 20)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.surface)
        )
    }
    
    private func getPadName(for padId: Int) -> String {
        let names = ["Kick", "Snare", "HiHat", "Clap", "Tom", "Cymbal", "Bell", "Shake"]
        return padId < names.count ? names[padId] : "Pad"
    }
    
    private func getPadColor(for padId: Int) -> Color {
        let colors: [Color] = [
            AppColors.coral, Color.orange, Color.yellow, Color.pink,
            Color.purple, Color.cyan, Color.green, Color.mint
        ]
        return padId < colors.count ? colors[padId] : AppColors.coral
    }
}

#Preview {
    VStack(spacing: 20) {
        LoopPatternView(loop: Loop(events: [
            LoopEvent(padId: 0, timestamp: 0.0),
            LoopEvent(padId: 1, timestamp: 0.5),
            LoopEvent(padId: 2, timestamp: 1.0),
            LoopEvent(padId: 0, timestamp: 1.5),
            LoopEvent(padId: 3, timestamp: 2.0)
        ]))
        
        DetailedLoopPatternView(loop: Loop(events: [
            LoopEvent(padId: 0, timestamp: 0.0),
            LoopEvent(padId: 1, timestamp: 0.5),
            LoopEvent(padId: 2, timestamp: 1.0),
            LoopEvent(padId: 0, timestamp: 1.5),
            LoopEvent(padId: 3, timestamp: 2.0)
        ]))
    }
    .padding()
    .background(AppColors.background)
}
