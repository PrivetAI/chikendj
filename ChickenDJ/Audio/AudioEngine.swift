import AVFoundation
import Combine

class AudioEngine: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var players: [Int: AVAudioPlayerNode] = [:]
    private var buffers: [Int: AVAudioPCMBuffer] = [:]
    
    // Effects nodes
    private var reverbNode: AVAudioUnitReverb?
    private var delayNode: AVAudioUnitDelay?
    private var pitchNode: AVAudioUnitTimePitch?
    private var mixerNode: AVAudioMixerNode?
    
    @Published var isReady = false
    
    // Effect settings
    @Published var reverbEnabled = false { didSet { updateReverbBypass() } }
    @Published var reverbWetDryMix: Float = 30 { didSet { reverbNode?.wetDryMix = reverbWetDryMix } }
    
    @Published var delayEnabled = false { didSet { updateDelayBypass() } }
    @Published var delayTime: TimeInterval = 0.3 { didSet { delayNode?.delayTime = delayTime } }
    @Published var delayFeedback: Float = 50 { didSet { delayNode?.feedback = delayFeedback } }
    @Published var delayWetDryMix: Float = 30 { didSet { delayNode?.wetDryMix = delayWetDryMix } }
    
    @Published var pitchEnabled = false { didSet { updatePitchBypass() } }
    @Published var pitchShift: Float = 0 { didSet { pitchNode?.pitch = pitchShift } } // in cents (-1200 to 1200)
    
    @Published var masterVolume: Float = 1.0 { didSet { audioEngine?.mainMixerNode.outputVolume = masterVolume } }
    
    init() {
        setupAudioSession()
        setupEngine()
        loadSounds()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupEngine() {
        audioEngine = AVAudioEngine()
        
        guard let engine = audioEngine else { return }
        
        // Create effect nodes
        reverbNode = AVAudioUnitReverb()
        delayNode = AVAudioUnitDelay()
        pitchNode = AVAudioUnitTimePitch()
        mixerNode = AVAudioMixerNode()
        
        guard let reverb = reverbNode,
              let delay = delayNode,
              let pitch = pitchNode,
              let mixer = mixerNode else { return }
        
        // Configure effects
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = reverbWetDryMix
        reverb.bypass = true
        
        delay.delayTime = delayTime
        delay.feedback = delayFeedback
        delay.wetDryMix = delayWetDryMix
        delay.bypass = true
        
        pitch.pitch = pitchShift
        pitch.bypass = true
        
        // Attach nodes
        engine.attach(mixer)
        engine.attach(reverb)
        engine.attach(delay)
        engine.attach(pitch)
        
        // Connect effect chain: mixer -> pitch -> delay -> reverb -> main output
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(mixer, to: pitch, format: format)
        engine.connect(pitch, to: delay, format: format)
        engine.connect(delay, to: reverb, format: format)
        engine.connect(reverb, to: engine.mainMixerNode, format: format)
        
        // Create player nodes for each pad
        for pad in Pad.allPads {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: mixer, format: nil)
            players[pad.id] = player
        }
        
        // Add chicken cluck player (id 99)
        let cluckPlayer = AVAudioPlayerNode()
        engine.attach(cluckPlayer)
        engine.connect(cluckPlayer, to: mixer, format: nil)
        players[99] = cluckPlayer
        
        // Add metronome player (id 100)
        let metronomePlayer = AVAudioPlayerNode()
        engine.attach(metronomePlayer)
        engine.connect(metronomePlayer, to: engine.mainMixerNode, format: nil) // Bypass effects for metronome
        players[100] = metronomePlayer
        
        do {
            try engine.start()
            isReady = true
            
            // Generate cluck sound
            generateCluckSound()
            generateMetronomeSound()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func updateReverbBypass() {
        reverbNode?.bypass = !reverbEnabled
    }
    
    private func updateDelayBypass() {
        delayNode?.bypass = !delayEnabled
    }
    
    private func updatePitchBypass() {
        pitchNode?.bypass = !pitchEnabled
    }
    
    // MARK: - Effect Presets
    
    func applyPreset(_ preset: EffectPreset) {
        switch preset {
        case .clean:
            reverbEnabled = false
            delayEnabled = false
            pitchEnabled = false
            
        case .studio:
            reverbEnabled = true
            reverbWetDryMix = 20
            delayEnabled = false
            pitchEnabled = false
            
        case .hall:
            reverbEnabled = true
            reverbWetDryMix = 50
            delayEnabled = true
            delayTime = 0.1
            delayFeedback = 20
            delayWetDryMix = 15
            pitchEnabled = false
            
        case .echo:
            reverbEnabled = false
            delayEnabled = true
            delayTime = 0.4
            delayFeedback = 60
            delayWetDryMix = 40
            pitchEnabled = false
            
        case .chipmunk:
            reverbEnabled = false
            delayEnabled = false
            pitchEnabled = true
            pitchShift = 600
            
        case .deep:
            reverbEnabled = true
            reverbWetDryMix = 30
            delayEnabled = false
            pitchEnabled = true
            pitchShift = -400
        }
    }
    
    private func loadSounds() {
        for pad in Pad.allPads {
            // Try to load from bundle first
            if let url = Bundle.main.url(forResource: pad.soundFileName, withExtension: "wav") {
                loadSound(from: url, forPadId: pad.id)
            } else {
                // Generate placeholder sound if file not found
                generatePlaceholderSound(forPad: pad)
            }
        }
    }
    
    private func loadSound(from url: URL, forPadId padId: Int) {
        do {
            let file = try AVAudioFile(forReading: url)
            guard let format = AVAudioFormat(standardFormatWithSampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount) else { return }
            
            let frameCount = AVAudioFrameCount(file.length)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
            
            try file.read(into: buffer)
            buffers[padId] = buffer
        } catch {
            print("Failed to load sound for pad \(padId): \(error)")
            // Generate placeholder if loading fails
            if let pad = Pad.allPads.first(where: { $0.id == padId }) {
                generatePlaceholderSound(forPad: pad)
            }
        }
    }
    
    private func generatePlaceholderSound(forPad pad: Pad) {
        let sampleRate: Double = 44100
        let duration: Double = 0.3
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        guard let floatData = buffer.floatChannelData else { return }
        
        // Generate different sounds based on pad type
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let envelope = max(0, 1.0 - time / duration) // Decay envelope
            
            let sample: Float
            switch pad.id {
            case 0: // Kick - low frequency sine with quick decay
                let freq = 60.0 * (1.0 + 2.0 * max(0, 0.1 - time) * 10)
                sample = Float(sin(2.0 * .pi * freq * time) * envelope * envelope)
                
            case 1: // Snare - noise with sine
                let noise = Float.random(in: -1...1)
                let sine = Float(sin(2.0 * .pi * 200 * time))
                sample = (noise * 0.7 + sine * 0.3) * Float(envelope)
                
            case 2: // HiHat - filtered noise
                let noise = Float.random(in: -1...1)
                sample = noise * Float(envelope * envelope * envelope)
                
            case 3: // Clap - layered noise bursts with filtering
                let noise = Float.random(in: -1...1)
                let burst1 = time < 0.015 ? 1.0 : 0.0
                let burst2 = (time > 0.02 && time < 0.035) ? 0.8 : 0.0
                let burst3 = (time > 0.04 && time < 0.06) ? 0.6 : 0.0
                let burst = burst1 + burst2 + burst3
                let midFreq = Float(sin(2.0 * .pi * 1200 * time) * 0.3)
                sample = (noise * 0.7 + midFreq) * Float(envelope * burst)
                
            case 4: // Tom - mid frequency sine
                let freq = 120.0 * (1.0 + max(0, 0.05 - time) * 10)
                sample = Float(sin(2.0 * .pi * freq * time) * envelope)
                
            case 5: // Cymbal - metallic high frequency
                let noise = Float.random(in: -1...1) * 0.4
                let freq1 = sin(2.0 * .pi * 3000 * time)
                let freq2 = sin(2.0 * .pi * 5500 * time) * 0.6
                let freq3 = sin(2.0 * .pi * 8000 * time) * 0.3
                let metallic = Float(freq1 + freq2 + freq3) * 0.2
                let longEnvelope = max(0, 1.0 - time / (duration * 3))
                sample = (noise + metallic) * Float(longEnvelope)
                
            case 6: // Cowbell - two sine waves
                let s1 = sin(2.0 * .pi * 560 * time)
                let s2 = sin(2.0 * .pi * 845 * time)
                sample = Float((s1 + s2 * 0.6) * envelope * 0.5)
                
            case 7: // Shaker - noise bursts
                let noise = Float.random(in: -1...1)
                let pattern = sin(2.0 * .pi * 20 * time) > 0 ? 1.0 : 0.5
                sample = noise * Float(envelope * pattern) * 0.6
                
            default:
                sample = 0
            }
            
            // Write to both stereo channels
            floatData[0][frame] = sample * 0.8 // Left channel
            floatData[1][frame] = sample * 0.8 // Right channel
        }
        
        buffers[pad.id] = buffer
    }
    
    func playSound(forPadId padId: Int) {
        guard let player = players[padId],
              let buffer = buffers[padId] else { return }
        
        // Stop any currently playing sound on this player
        player.stop()
        
        // Schedule and play the buffer
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
    }
    
    func stop() {
        for player in players.values {
            player.stop()
        }
    }
    
    func playCluck() {
        playSound(forPadId: 99)
    }
    
    func playMetronome() {
        playSound(forPadId: 100)
    }
    
    private func generateCluckSound() {
        let sampleRate: Double = 44100
        let duration: Double = 0.25
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        guard let floatData = buffer.floatChannelData else { return }
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let envelope = max(0, 1.0 - time / duration)
            
            // Chicken cluck - frequency modulated tone
            let freqMod = 1.0 + 0.35 * sin(2.0 * .pi * 40 * time)
            let baseFreq = 380.0 * freqMod
            let tone = Float(sin(2.0 * .pi * baseFreq * time))
            
            // Add harmonics for richer sound
            let harmonic1 = Float(sin(2.0 * .pi * baseFreq * 2.2 * time) * 0.25)
            let harmonic2 = Float(sin(2.0 * .pi * baseFreq * 3.1 * time) * 0.1)
            
            // Quick attack
            let attackEnv = min(1.0, time / 0.008)
            let sample = (tone + harmonic1 + harmonic2) * Float(envelope * envelope * attackEnv) * 0.6
            
            floatData[0][frame] = sample
            floatData[1][frame] = sample
        }
        
        buffers[99] = buffer
    }
    
    private func generateMetronomeSound() {
        let sampleRate: Double = 44100
        let duration: Double = 0.08
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        guard let floatData = buffer.floatChannelData else { return }
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let envelope = max(0, 1.0 - time / duration)
            
            // Short click sound
            let freq = 1000.0
            let sample = Float(sin(2.0 * .pi * freq * time) * envelope * envelope) * 0.4
            
            floatData[0][frame] = sample
            floatData[1][frame] = sample
        }
        
        buffers[100] = buffer
    }
    
    // MARK: - Loop Rendering for Export
    
    func renderLoopToFile(loop: Loop, url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard !loop.events.isEmpty else {
            completion(.failure(NSError(domain: "AudioEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Loop is empty"])))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let sampleRate: Double = 44100
            let channels: AVAudioChannelCount = 2
            
            // Calculate total duration (last event + buffer time)
            let lastEventTime = loop.events.map { $0.timestamp }.max() ?? 0
            let totalDuration = lastEventTime + 0.5 // Add 0.5s tail
            let totalFrames = AVAudioFrameCount(sampleRate * totalDuration)
            
            guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channels),
                  let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else {
                completion(.failure(NSError(domain: "AudioEngine", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create buffer"])))
                return
            }
            
            outputBuffer.frameLength = totalFrames
            
            guard let outputData = outputBuffer.floatChannelData else {
                completion(.failure(NSError(domain: "AudioEngine", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to access buffer data"])))
                return
            }
            
            // Initialize buffer to silence
            for channel in 0..<Int(channels) {
                for frame in 0..<Int(totalFrames) {
                    outputData[channel][frame] = 0
                }
            }
            
            // Mix in each event
            for event in loop.events {
                guard let soundBuffer = self.buffers[event.padId],
                      let soundData = soundBuffer.floatChannelData else { continue }
                
                let startFrame = Int(event.timestamp * sampleRate)
                let soundFrames = Int(soundBuffer.frameLength)
                
                for frame in 0..<soundFrames {
                    let outputFrame = startFrame + frame
                    if outputFrame < Int(totalFrames) {
                        for channel in 0..<Int(min(channels, soundBuffer.format.channelCount)) {
                            outputData[channel][outputFrame] += soundData[channel][frame]
                        }
                    }
                }
            }
            
            // Normalize to prevent clipping
            var maxSample: Float = 0
            for channel in 0..<Int(channels) {
                for frame in 0..<Int(totalFrames) {
                    maxSample = max(maxSample, abs(outputData[channel][frame]))
                }
            }
            
            if maxSample > 1.0 {
                let normalizeRatio = 0.95 / maxSample
                for channel in 0..<Int(channels) {
                    for frame in 0..<Int(totalFrames) {
                        outputData[channel][frame] *= normalizeRatio
                    }
                }
            }
            
            // Write to file
            do {
                let audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
                try audioFile.write(from: outputBuffer)
                
                DispatchQueue.main.async {
                    completion(.success(url))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Effect Presets

enum EffectPreset: String, CaseIterable {
    case clean = "Clean"
    case studio = "Studio"
    case hall = "Hall"
    case echo = "Echo"
    case chipmunk = "Chipmunk"
    case deep = "Deep"
    
    var icon: String {
        switch self {
        case .clean: return "waveform"
        case .studio: return "music.mic"
        case .hall: return "building.columns"
        case .echo: return "wave.3.right"
        case .chipmunk: return "hare"
        case .deep: return "tortoise"
        }
    }
}
