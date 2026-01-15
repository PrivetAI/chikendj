import SwiftUI

struct LoopsView: View {
    @EnvironmentObject var loopStorage: LoopStorage
    @EnvironmentObject var audioEngine: AudioEngine
    @StateObject private var loopPlayer = LoopPlayer()
    
    @State private var exportingLoopId: UUID?
    @State private var exportedURL: URL?
    @State private var showingShareSheet = false
    @State private var showingExportError = false
    @State private var exportErrorMessage = ""
    
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
                            ForEach(loopStorage.savedLoops) { savedLoop in
                                LoopRowView(
                                    loop: savedLoop,
                                    isPlaying: loopPlayer.currentLoopId == savedLoop.id,
                                    isExporting: exportingLoopId == savedLoop.id
                                ) {
                                    if loopPlayer.currentLoopId == savedLoop.id {
                                        loopPlayer.stop()
                                    } else {
                                        loopPlayer.play(savedLoop.loop, id: savedLoop.id) { padId in
                                            audioEngine.playSound(forPadId: padId)
                                        }
                                    }
                                } onExport: {
                                    exportLoop(savedLoop)
                                } onDelete: {
                                    loopStorage.deleteLoop(savedLoop)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Export Error", isPresented: $showingExportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportErrorMessage)
        }
    }
    
    private func exportLoop(_ savedLoop: SavedLoop) {
        exportingLoopId = savedLoop.id
        
        let fileName = savedLoop.name.replacingOccurrences(of: " ", with: "_") + ".wav"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        // Remove existing file if any
        try? FileManager.default.removeItem(at: fileURL)
        
        audioEngine.renderLoopToFile(loop: savedLoop.loop, url: fileURL) { result in
            exportingLoopId = nil
            
            switch result {
            case .success(let url):
                exportedURL = url
                showingShareSheet = true
            case .failure(let error):
                exportErrorMessage = error.localizedDescription
                showingExportError = true
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Loop Player
class LoopPlayer: ObservableObject {
    @Published var currentLoopId: UUID?
    @Published var isPlaying = false
    
    private var playbackTimer: Timer?
    private var currentEventIndex = 0
    
    func play(_ loop: Loop, id: UUID, onEvent: @escaping (Int) -> Void) {
        stop()
        
        guard !loop.events.isEmpty else { return }
        
        currentLoopId = id
        isPlaying = true
        currentEventIndex = 0
        
        let startTime = Date()
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            guard let self = self, self.isPlaying else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            
            while self.currentEventIndex < loop.events.count {
                let event = loop.events[self.currentEventIndex]
                if event.timestamp <= elapsed {
                    onEvent(event.padId)
                    self.currentEventIndex += 1
                } else {
                    break
                }
            }
            
            if self.currentEventIndex >= loop.events.count {
                self.stop()
            }
        }
    }
    
    func stop() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        isPlaying = false
        currentLoopId = nil
        currentEventIndex = 0
    }
}

struct LoopRowView: View {
    let loop: SavedLoop
    let isPlaying: Bool
    let isExporting: Bool
    let onPlay: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Play/Stop button
                Button(action: onPlay) {
                    ZStack {
                        Circle()
                            .fill(isPlaying ? Color.red : AppColors.coral)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
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
                
                // Action buttons
                VStack(spacing: 8) {
                    // Export button
                    Button(action: onExport) {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.coral)
                        }
                    }
                    .disabled(isExporting)
                    
                    // Expand button
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
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
                
                VStack(spacing: 12) {
                    DetailedLoopPatternView(loop: loop.loop)
                    
                    // Delete button
                    Button(action: onDelete) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Loop")
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                }
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
        .environmentObject(AudioEngine())
}
