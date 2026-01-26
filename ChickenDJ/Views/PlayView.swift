import SwiftUI

struct PlayView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var loopStorage: LoopStorage
    @StateObject private var loopManager = LoopManager()
    @StateObject private var bpmManager = BPMManager()
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State private var showingSaveAlert = false
    @State private var loopName = ""
    
    @State private var isPecking = false
    @State private var recordingPulse = false
    @State private var beatPulse = false
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    private var columns: [GridItem] {
        if isIPad {
            // 4 columns for iPad - all pads in one row
            return [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        } else {
            // 2 columns for iPhone
            return [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                AppGradients.background
                    .ignoresSafeArea()
                
                VStack(spacing: isIPad ? 16 : 12) {
                    // Header with BPM
                    HStack {
                        Text("Chicken DJ")
                            .font(.system(size: isIPad ? 36 : 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                        
                        // BPM Control
                        BPMControlView(bpmManager: bpmManager, audioEngine: audioEngine)
                    }
                    .padding(.horizontal, isIPad ? 40 : 20)
                    .padding(.top, 10)
                    
                    // Metronome indicator
                    if bpmManager.isMetronomeRunning {
                        MetronomeIndicator(
                            currentBeat: bpmManager.currentBeat,
                            beatsPerBar: bpmManager.beatsPerBar,
                            beatPulse: beatPulse
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Mascot - tap to cluck!
                    MascotView(isPecking: $isPecking) {
                        audioEngine.playCluck()
                    }
                    .frame(height: isIPad ? 350 : 180)
                    .padding(.top, bpmManager.isMetronomeRunning ? 0 : 10)
                    
                    // Pads grid
                    LazyVGrid(columns: columns, spacing: isIPad ? 16 : 12) {
                        ForEach(Pad.allPads) { pad in
                            PadView(pad: pad) {
                                playPad(pad)
                            }
                        }
                    }
                    .padding(.horizontal, isIPad ? 40 : 20)
                    
                    Spacer()
                        
                    // Controls
                    VStack(spacing: 16) {
                        // Record/Play buttons
                        HStack(spacing: isIPad ? 24 : 16) {
                            // Record button
                            Button(action: {
                                toggleRecording()
                            }) {
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .stroke(AppColors.egg, lineWidth: 2)
                                            .frame(width: 18, height: 18)
                                        Circle()
                                            .fill(loopManager.isRecording ? Color.white : AppColors.egg)
                                            .frame(width: 12, height: 12)
                                            .scaleEffect(recordingPulse ? 1.3 : 1.0)
                                            .opacity(recordingPulse ? 0.7 : 1.0)
                                    }
                                    
                                    Text(loopManager.isRecording ? "Stop" : "Record")
                                        .font(.system(size: isIPad ? 18 : 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(AppColors.egg)
                                .padding(.horizontal, isIPad ? 28 : 20)
                                .padding(.vertical, isIPad ? 16 : 12)
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
                                        .font(.system(size: isIPad ? 16 : 14))
                                    
                                    Text(loopManager.isPlaying ? "Stop" : "Play")
                                        .font(.system(size: isIPad ? 18 : 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(AppColors.coral)
                                .padding(.horizontal, isIPad ? 28 : 20)
                                .padding(.vertical, isIPad ? 16 : 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(AppColors.coral, lineWidth: 2)
                                )
                            }
                            .disabled(!loopManager.hasRecording)
                            .opacity(loopManager.hasRecording ? 1.0 : 0.5)
                            
                            // Save button
                            Button(action: {
                                bpmManager.stopMetronome()
                                showingSaveAlert = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: isIPad ? 16 : 14))
                                    
                                    Text("Save")
                                        .font(.system(size: isIPad ? 18 : 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(AppColors.egg)
                                .padding(.horizontal, isIPad ? 28 : 20)
                                .padding(.vertical, isIPad ? 16 : 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(AppColors.text)
                                )
                            }
                            .disabled(!loopManager.hasRecording)
                            .opacity(loopManager.hasRecording ? 1.0 : 0.5)
                        }
                    }
                    .padding(.bottom, isIPad ? 80 : 30)
                }
            }
        }
        .preferredColorScheme(.light)
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
            bpmManager.stopMetronome()
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

// MARK: - BPM Control View

struct BPMControlView: View {
    @ObservedObject var bpmManager: BPMManager
    @ObservedObject var audioEngine: AudioEngine
    
    var body: some View {
        HStack(spacing: 8) {
            // Metronome toggle
            Button(action: {
                if bpmManager.isMetronomeRunning {
                    bpmManager.stopMetronome()
                } else {
                    bpmManager.startMetronome {
                        audioEngine.playMetronome()
                    }
                }
            }) {
                Image(systemName: bpmManager.isMetronomeRunning ? "metronome.fill" : "metronome")
                    .font(.system(size: 16))
                    .foregroundColor(bpmManager.isMetronomeRunning ? AppColors.coral : AppColors.textSecondary)
            }
            
            // BPM display and controls
            HStack(spacing: 4) {
                Button(action: { bpmManager.decrementBPM() }) {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 24, height: 24)
                }
                
                Text("\(bpmManager.bpm)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.text)
                    .frame(width: 36)
                
                Button(action: { bpmManager.incrementBPM() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(AppColors.surface)
            )
        }
    }
}

// MARK: - Metronome Indicator

struct MetronomeIndicator: View {
    let currentBeat: Int
    let beatsPerBar: Int
    let beatPulse: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<beatsPerBar, id: \.self) { beat in
                Circle()
                    .fill(beat == currentBeat ? AppColors.coral : AppColors.surface)
                    .frame(width: 12, height: 12)
                    .scaleEffect(beat == currentBeat ? 1.2 : 1.0)
                    .animation(.spring(response: 0.15, dampingFraction: 0.5), value: currentBeat)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(AppColors.egg)
        )
    }
}

// MARK: - Loop Manager

class LoopManager: ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var hasRecording = false
    @Published var isLoopMode = false
    
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
        let loopDuration = loop.events.map { $0.timestamp }.max() ?? 0
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            guard let self = self, self.isPlaying else {
                timer.invalidate()
                return
            }
            
            var elapsed = Date().timeIntervalSince(startTime)
            
            // Handle loop mode
            if self.isLoopMode && loopDuration > 0 {
                elapsed = elapsed.truncatingRemainder(dividingBy: loopDuration + 0.1)
                if elapsed < 0.02 {
                    self.currentEventIndex = 0
                }
            }
            
            while self.currentEventIndex < loop.events.count {
                let event = loop.events[self.currentEventIndex]
                if event.timestamp <= elapsed {
                    onEvent(event.padId)
                    self.currentEventIndex += 1
                } else {
                    break
                }
            }
            
            // Stop when all events played (if not loop mode)
            if !self.isLoopMode && self.currentEventIndex >= loop.events.count {
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
        .environmentObject(AudioEngine())
        .environmentObject(LoopStorage())
}
