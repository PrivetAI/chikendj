import AVFoundation
import Combine

class AudioEngine: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var players: [Int: AVAudioPlayerNode] = [:]
    private var buffers: [Int: AVAudioPCMBuffer] = [:]
    
    @Published var isReady = false
    
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
        
        // Create player nodes for each pad
        for pad in Pad.allPads {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)
            players[pad.id] = player
        }
        
        // Add chicken cluck player (id 99)
        let cluckPlayer = AVAudioPlayerNode()
        engine.attach(cluckPlayer)
        engine.connect(cluckPlayer, to: engine.mainMixerNode, format: nil)
        players[99] = cluckPlayer
        
        do {
            try engine.start()
            isReady = true
            
            // Generate cluck sound
            generateCluckSound()
        } catch {
            print("Failed to start audio engine: \(error)")
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
                // Multiple short bursts to simulate hand clap
                let burst1 = time < 0.015 ? 1.0 : 0.0
                let burst2 = (time > 0.02 && time < 0.035) ? 0.8 : 0.0
                let burst3 = (time > 0.04 && time < 0.06) ? 0.6 : 0.0
                let burst = burst1 + burst2 + burst3
                // Add some mid-frequency content
                let midFreq = Float(sin(2.0 * .pi * 1200 * time) * 0.3)
                sample = (noise * 0.7 + midFreq) * Float(envelope * burst)
                
            case 4: // Tom - mid frequency sine
                let freq = 120.0 * (1.0 + max(0, 0.05 - time) * 10)
                sample = Float(sin(2.0 * .pi * freq * time) * envelope)
                
            case 5: // Cymbal - metallic high frequency
                let noise = Float.random(in: -1...1) * 0.4
                // Multiple high-frequency sine waves for metallic sound
                let freq1 = sin(2.0 * .pi * 3000 * time)
                let freq2 = sin(2.0 * .pi * 5500 * time) * 0.6
                let freq3 = sin(2.0 * .pi * 8000 * time) * 0.3
                let metallic = Float(freq1 + freq2 + freq3) * 0.2
                // Longer decay for cymbal
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
}
