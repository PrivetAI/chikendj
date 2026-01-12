import SwiftUI

struct PlayView: View {
    @StateObject private var audioEngine = AudioEngine()
    @StateObject private var loopManager = LoopManager()
    @EnvironmentObject var loopStorage: LoopStorage
    
    @State private var showingSaveAlert = false
    @State private var loopName = ""
    
    @State private var isPecking = false
    @State private var recordingPulse = false
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            // Background
            AppGradients.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Chicken DJ")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.text)
                        .padding(.top, 20)
                    
                    // Mascot - tap to cluck!
                    MascotView(isPecking: $isPecking) {
                        audioEngine.playCluck()
                    }
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
                    
                    Spacer(minLength: 20)
                    
                    // Controls
                    VStack(spacing: 16) {
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
                                        .scaleEffect(recordingPulse ? 1.3 : 1.0)
                                        .opacity(recordingPulse ? 0.7 : 1.0)
                                    
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
                            .onChange(of: loopManager.isRecording) { isRecording in
                                if isRecording {
                                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                        recordingPulse = true
                                    }
                                } else {
                                    recordingPulse = false
                                }
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
                            
                            // Save button
                            Button(action: {
                                showingSaveAlert = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 14))
                                    
                                    Text("Save")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(AppColors.egg)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(AppColors.text)
                                )
                            }
                            .disabled(!loopManager.hasRecording)
                            .opacity(loopManager.hasRecording ? 1.0 : 0.5)
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
        }
        .preferredColorScheme(.light)
        .environmentObject(audioEngine)
        .alert("Save Loop", isPresented: $showingSaveAlert) {
            TextField("Loop name", text: $loopName)
            Button("Cancel", role: .cancel) {
                loopName = ""
            }
            Button("Save") {
                if let loop = loopManager.getCurrentLoop(), !loopName.isEmpty {
                    loopStorage.saveLoop(loop, name: loopName)
                }
                loopName = ""
            }
        } message: {
            Text("Enter a name for your loop")
        }
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
            loopManager.startRecording()
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
    
    func startRecording() {
        currentLoop = Loop()
        recordingStartTime = Date()
        isRecording = true
        hasRecording = false
    }
    
    func stopRecording() {
        isRecording = false
        hasRecording = (currentLoop?.events.count ?? 0) > 0
    }
    
    func getCurrentLoop() -> Loop? {
        return currentLoop
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
