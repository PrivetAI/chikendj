import SwiftUI

struct PlayView: View {
    @StateObject private var audioEngine = AudioEngine()
    @StateObject private var loopManager = LoopManager()
    
    @State private var isPecking = false
    @State private var bpm: Double = 120
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            // Background
            AppGradients.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                Text("Chicken DJ")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.text)
                    .padding(.top, 10)
                
                // Mascot
                MascotView(isPecking: $isPecking)
                    .frame(height: 150)
                
                // Pads grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Pad.allPads) { pad in
                        PadView(pad: pad) {
                            playPad(pad)
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Controls
                VStack(spacing: 16) {
                    // BPM Control
                    HStack {
                        Text("BPM")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                        
                        Slider(value: $bpm, in: 60...180, step: 1)
                            .accentColor(AppColors.coral)
                        
                        Text("\(Int(bpm))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.coral)
                            .frame(width: 40)
                    }
                    .padding(.horizontal, 30)
                    
                    // Record/Play buttons
                    HStack(spacing: 20) {
                        // Record button
                        Button(action: {
                            toggleRecording()
                        }) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(loopManager.isRecording ? Color.red : AppColors.coral)
                                    .frame(width: 16, height: 16)
                                
                                Text(loopManager.isRecording ? "Stop" : "Record")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(AppColors.egg)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(loopManager.isRecording ? Color.red : AppColors.coral)
                            )
                        }
                        
                        // Play button
                        Button(action: {
                            togglePlayback()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: loopManager.isPlaying ? "stop.fill" : "play.fill")
                                    .font(.system(size: 14))
                                
                                Text(loopManager.isPlaying ? "Stop" : "Play")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(AppColors.coral)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(AppColors.coral, lineWidth: 2)
                            )
                        }
                        .disabled(!loopManager.hasRecording)
                        .opacity(loopManager.hasRecording ? 1.0 : 0.5)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.light)
        .environmentObject(audioEngine)
    }
    
    private func playPad(_ pad: Pad) {
        // Play sound
        audioEngine.playSound(forPadId: pad.id)
        
        // Record event if recording
        loopManager.recordEvent(padId: pad.id)
        
        // Animate mascot
        isPecking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isPecking = false
        }
    }
    
    private func toggleRecording() {
        if loopManager.isRecording {
            loopManager.stopRecording()
        } else {
            loopManager.startRecording(bpm: Int(bpm))
        }
    }
    
    private func togglePlayback() {
        if loopManager.isPlaying {
            loopManager.stopPlayback()
        } else {
            loopManager.startPlayback { padId in
                audioEngine.playSound(forPadId: padId)
                isPecking = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPecking = false
                }
            }
        }
    }
}

// MARK: - Loop Manager

class LoopManager: ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var hasRecording = false
    
    private var currentLoop: Loop?
    private var recordingStartTime: Date?
    private var playbackTimer: Timer?
    private var currentEventIndex = 0
    
    func startRecording(bpm: Int) {
        currentLoop = Loop(bpm: bpm)
        recordingStartTime = Date()
        isRecording = true
        hasRecording = false
    }
    
    func stopRecording() {
        isRecording = false
        hasRecording = (currentLoop?.events.count ?? 0) > 0
    }
    
    func recordEvent(padId: Int) {
        guard isRecording, let startTime = recordingStartTime else { return }
        
        let timestamp = Date().timeIntervalSince(startTime)
        let event = LoopEvent(padId: padId, timestamp: timestamp)
        currentLoop?.events.append(event)
    }
    
    func startPlayback(onEvent: @escaping (Int) -> Void) {
        guard let loop = currentLoop, !loop.events.isEmpty else { return }
        
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
            
            // Stop when all events played
            if self.currentEventIndex >= loop.events.count {
                self.stopPlayback()
            }
        }
    }
    
    func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        isPlaying = false
        currentEventIndex = 0
    }
}

#Preview {
    PlayView()
}
