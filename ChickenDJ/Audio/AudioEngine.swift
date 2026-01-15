import AVFoundation
import Combine

class AudioEngine: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var players: [Int: AVAudioPlayerNode] = [:]
    private var buffers: [String: [Int: AVAudioPCMBuffer]] = [:] // [soundPack: [padId: buffer]]
    
    // Effect nodes (simplified)
    private var reverbNode: AVAudioUnitReverb?
    private var delayNode: AVAudioUnitDelay?
    private var pitchNode: AVAudioUnitTimePitch?
    private var mixerNode: AVAudioMixerNode?
    
    @Published var isReady = false
    
    // Current sound pack
    @Published var currentSoundPack: SoundPack = .classic {
        didSet { /* Buffers already loaded, just switch */ }
    }
    
    // Effect preset
    @Published var currentPreset: EffectPreset = .normal {
        didSet { applyPreset(currentPreset) }
    }
    
    // Per-pad volume (0.0 to 1.0)
    @Published var padVolumes: [Int: Float] = [:]
    
    // Master volume
    @Published var masterVolume: Float = 1.0 {
        didSet { audioEngine?.mainMixerNode.outputVolume = masterVolume }
    }
    
    init() {
        // Initialize pad volumes
        for pad in Pad.allPads {
            padVolumes[pad.id] = 1.0
        }
        
        setupAudioSession()
        setupEngine()
        loadAllSoundPacks()
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
        
        // Configure effects (all bypassed by default)
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 0
        reverb.bypass = true
        
        delay.delayTime = 0.3
        delay.feedback = 50
        delay.wetDryMix = 0
        delay.bypass = true
        
        pitch.pitch = 0
        pitch.bypass = true
        
        // Attach nodes
        engine.attach(mixer)
        engine.attach(reverb)
        engine.attach(delay)
        engine.attach(pitch)
        
        // Connect effect chain
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
        engine.connect(metronomePlayer, to: engine.mainMixerNode, format: nil)
        players[100] = metronomePlayer
        
        do {
            try engine.start()
            isReady = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Effect Presets (Simplified)
    
    private func applyPreset(_ preset: EffectPreset) {
        guard let reverb = reverbNode,
              let delay = delayNode,
              let pitch = pitchNode else { return }
        
        switch preset {
        case .normal:
            reverb.bypass = true
            delay.bypass = true
            pitch.bypass = true
            
        case .echo:
            reverb.bypass = true
            delay.bypass = false
            delay.delayTime = 0.25
            delay.feedback = 40
            delay.wetDryMix = 35
            pitch.bypass = true
            
        case .space:
            reverb.bypass = false
            reverb.wetDryMix = 60
            delay.bypass = true
            pitch.bypass = true
            
        case .turbo:
            reverb.bypass = true
            delay.bypass = true
            pitch.bypass = false
            pitch.pitch = 400
            
        case .slow:
            reverb.bypass = false
            reverb.wetDryMix = 30
            delay.bypass = true
            pitch.bypass = false
            pitch.pitch = -300
        }
    }
    
    // MARK: - Sound Packs
    
    private func loadAllSoundPacks() {
        for pack in SoundPack.allCases {
            buffers[pack.rawValue] = [:]
            for pad in Pad.allPads {
                generateSound(forPad: pad, pack: pack)
            }
        }
        
        // Generate cluck and metronome
        generateCluckSound()
        generateMetronomeSound()
    }
    
    private func generateSound(forPad pad: Pad, pack: SoundPack) {
        let sampleRate: Double = 44100
        let duration: Double = pack == .electronic ? 0.2 : 0.3
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        guard let floatData = buffer.floatChannelData else { return }
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let envelope = max(0, 1.0 - time / duration)
            
            let sample: Float
            
            switch pack {
            case .classic:
                sample = generateClassicSound(pad: pad, time: time, envelope: envelope)
            case .electronic:
                sample = generateElectronicSound(pad: pad, time: time, envelope: envelope)
            case .chicken:
                sample = generateChickenSound(pad: pad, time: time, envelope: envelope)
            case .retro:
                sample = generateRetroSound(pad: pad, time: time, envelope: envelope)
            }
            
            floatData[0][frame] = sample * 0.8
            floatData[1][frame] = sample * 0.8
        }
        
        buffers[pack.rawValue]?[pad.id] = buffer
    }
    
    private func generateClassicSound(pad: Pad, time: Double, envelope: Double) -> Float {
        switch pad.id {
        case 0: // Kick
            let freq = 60.0 * (1.0 + 2.0 * max(0, 0.1 - time) * 10)
            return Float(sin(2.0 * .pi * freq * time) * envelope * envelope)
        case 1: // Snare
            let noise = Float.random(in: -1...1)
            let sine = Float(sin(2.0 * .pi * 200 * time))
            return (noise * 0.7 + sine * 0.3) * Float(envelope)
        case 2: // HiHat
            let noise = Float.random(in: -1...1)
            return noise * Float(envelope * envelope * envelope)
        case 3: // Clap
            let noise = Float.random(in: -1...1)
            let burst = (time < 0.015 ? 1.0 : 0.0) + ((time > 0.02 && time < 0.035) ? 0.8 : 0.0)
            return noise * Float(envelope * burst) * 0.8
        case 4: // Tom
            let freq = 120.0 * (1.0 + max(0, 0.05 - time) * 10)
            return Float(sin(2.0 * .pi * freq * time) * envelope)
        case 5: // Cymbal
            let noise = Float.random(in: -1...1) * 0.4
            let metallic = Float(sin(2.0 * .pi * 3000 * time) + sin(2.0 * .pi * 5500 * time) * 0.6) * 0.2
            return (noise + metallic) * Float(envelope)
        case 6: // Cowbell
            let s1 = sin(2.0 * .pi * 560 * time)
            let s2 = sin(2.0 * .pi * 845 * time)
            return Float((s1 + s2 * 0.6) * envelope * 0.5)
        case 7: // Shaker
            let noise = Float.random(in: -1...1)
            let pattern = sin(2.0 * .pi * 20 * time) > 0 ? 1.0 : 0.5
            return noise * Float(envelope * pattern) * 0.6
        default:
            return 0
        }
    }
    
    private func generateElectronicSound(pad: Pad, time: Double, envelope: Double) -> Float {
        switch pad.id {
        case 0: // Deep bass
            let freq = 45.0 * (1.0 + max(0, 0.05 - time) * 15)
            return Float(sin(2.0 * .pi * freq * time) * envelope * envelope) * 1.2
        case 1: // Snappy snare
            let noise = Float.random(in: -1...1)
            let click = time < 0.01 ? Float(sin(2.0 * .pi * 1000 * time)) : 0
            return (noise * 0.6 + click * 0.4) * Float(envelope * envelope)
        case 2: // Closed hat
            let noise = Float.random(in: -1...1)
            return noise * Float(pow(envelope, 4))
        case 3: // Clap synth
            let noise = Float.random(in: -1...1)
            let filter = Float(sin(2.0 * .pi * 2000 * time) * 0.3)
            return (noise * 0.5 + filter) * Float(envelope * envelope)
        case 4: // Low tom synth
            let freq = 80.0 * (1.0 + max(0, 0.03 - time) * 20)
            return Float(sin(2.0 * .pi * freq * time) * envelope * envelope)
        case 5: // Crash
            let noise = Float.random(in: -1...1)
            return noise * Float(envelope) * 0.7
        case 6: // Blip
            let freq = 800.0
            return Float(sin(2.0 * .pi * freq * time) * envelope * envelope) * 0.6
        case 7: // Noise sweep
            let noise = Float.random(in: -1...1)
            return noise * Float(envelope * (1 - envelope)) * 1.5
        default:
            return 0
        }
    }
    
    private func generateChickenSound(pad: Pad, time: Double, envelope: Double) -> Float {
        // Fun chicken-themed sounds
        let freqMod = 1.0 + 0.3 * sin(2.0 * .pi * (30 + Double(pad.id) * 5) * time)
        let baseFreq = Double(200 + pad.id * 80) * freqMod
        let tone = Float(sin(2.0 * .pi * baseFreq * time))
        let harmonic = Float(sin(2.0 * .pi * baseFreq * 2.1 * time) * 0.3)
        return (tone + harmonic) * Float(envelope * envelope) * 0.7
    }
    
    private func generateRetroSound(pad: Pad, time: Double, envelope: Double) -> Float {
        // 8-bit style sounds
        let freq = Double(100 + pad.id * 50)
        // Square wave approximation
        let square = sin(2.0 * .pi * freq * time) > 0 ? 1.0 : -1.0
        // Add some noise for texture
        let noise = Float.random(in: -0.1...0.1)
        return (Float(square) * 0.5 + noise) * Float(envelope * envelope)
    }
    
    func playSound(forPadId padId: Int) {
        guard let player = players[padId],
              let packBuffers = buffers[currentSoundPack.rawValue],
              let buffer = packBuffers[padId] else { return }
        
        player.stop()
        player.volume = padVolumes[padId] ?? 1.0
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
    }
    
    func stop() {
        for player in players.values {
            player.stop()
        }
    }
    
    func playCluck() {
        guard let player = players[99],
              let packBuffers = buffers[SoundPack.classic.rawValue],
              let buffer = packBuffers[-1] else { return }
        
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
    }
    
    func playMetronome() {
        guard let player = players[100],
              let packBuffers = buffers[SoundPack.classic.rawValue],
              let buffer = packBuffers[-2] else { return }
        
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
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
            let freqMod = 1.0 + 0.35 * sin(2.0 * .pi * 40 * time)
            let baseFreq = 380.0 * freqMod
            let tone = Float(sin(2.0 * .pi * baseFreq * time))
            let harmonic1 = Float(sin(2.0 * .pi * baseFreq * 2.2 * time) * 0.25)
            let attackEnv = min(1.0, time / 0.008)
            let sample = (tone + harmonic1) * Float(envelope * envelope * attackEnv) * 0.6
            
            floatData[0][frame] = sample
            floatData[1][frame] = sample
        }
        
        buffers[SoundPack.classic.rawValue]?[-1] = buffer
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
            let sample = Float(sin(2.0 * .pi * 1000 * time) * envelope * envelope) * 0.4
            
            floatData[0][frame] = sample
            floatData[1][frame] = sample
        }
        
        buffers[SoundPack.classic.rawValue]?[-2] = buffer
    }
    
    // MARK: - Loop Rendering for Export
    
    func renderLoopToFile(loop: Loop, url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard !loop.events.isEmpty else {
            completion(.failure(NSError(domain: "AudioEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Loop is empty"])))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let packBuffers = self.buffers[self.currentSoundPack.rawValue] else { return }
            
            let sampleRate: Double = 44100
            let channels: AVAudioChannelCount = 2
            let lastEventTime = loop.events.map { $0.timestamp }.max() ?? 0
            let totalDuration = lastEventTime + 0.5
            let totalFrames = AVAudioFrameCount(sampleRate * totalDuration)
            
            guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channels),
                  let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else {
                completion(.failure(NSError(domain: "AudioEngine", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create buffer"])))
                return
            }
            
            outputBuffer.frameLength = totalFrames
            guard let outputData = outputBuffer.floatChannelData else { return }
            
            for channel in 0..<Int(channels) {
                for frame in 0..<Int(totalFrames) {
                    outputData[channel][frame] = 0
                }
            }
            
            for event in loop.events {
                guard let soundBuffer = packBuffers[event.padId],
                      let soundData = soundBuffer.floatChannelData else { continue }
                
                let startFrame = Int(event.timestamp * sampleRate)
                let soundFrames = Int(soundBuffer.frameLength)
                let volume = self.padVolumes[event.padId] ?? 1.0
                
                for frame in 0..<soundFrames {
                    let outputFrame = startFrame + frame
                    if outputFrame < Int(totalFrames) {
                        for channel in 0..<Int(min(channels, soundBuffer.format.channelCount)) {
                            outputData[channel][outputFrame] += soundData[channel][frame] * volume
                        }
                    }
                }
            }
            
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
            
            do {
                let audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
                try audioFile.write(from: outputBuffer)
                DispatchQueue.main.async { completion(.success(url)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
}

// MARK: - Sound Packs

enum SoundPack: String, CaseIterable {
    case classic = "Classic"
    case electronic = "Electronic"
    case chicken = "Chicken"
    case retro = "8-Bit"
    
    var icon: String {
        switch self {
        case .classic: return "music.note"
        case .electronic: return "waveform"
        case .chicken: return "hare"
        case .retro: return "gamecontroller"
        }
    }
    
    var description: String {
        switch self {
        case .classic: return "Standard drums"
        case .electronic: return "Synth beats"
        case .chicken: return "Clucky sounds"
        case .retro: return "Game sounds"
        }
    }
}

// MARK: - Effect Presets (Simplified)

enum EffectPreset: String, CaseIterable {
    case normal = "Normal"
    case echo = "Echo"
    case space = "Space"
    case turbo = "Turbo"
    case slow = "Slow"
    
    var icon: String {
        switch self {
        case .normal: return "waveform"
        case .echo: return "wave.3.right"
        case .space: return "sparkles"
        case .turbo: return "hare"
        case .slow: return "tortoise"
        }
    }
}
