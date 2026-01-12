import Foundation
import AVFoundation

/// Generates and exports WAV sound files for the app
class SoundGenerator {
    
    static let shared = SoundGenerator()
    
    private let sampleRate: Double = 44100
    
    /// Generate all drum sounds and save to Documents directory
    func generateAllSounds() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let sounds: [(name: String, generator: (Double) -> Float)] = [
            ("kick", generateKick),
            ("snare", generateSnare),
            ("hihat", generateHiHat),
            ("clap", generateClap),
            ("tom", generateTom),
            ("cymbal", generateCymbal),
            ("cowbell", generateCowbell),
            ("shaker", generateShaker),
            ("cluck", generateCluck)
        ]
        
        for sound in sounds {
            let buffer = generateBuffer(duration: sound.name == "cymbal" ? 0.8 : 0.4, generator: sound.generator)
            let url = documentsPath.appendingPathComponent("\(sound.name).wav")
            saveWAV(buffer: buffer, to: url)
        }
    }
    
    private func generateBuffer(duration: Double, generator: (Double) -> Float) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        guard let floatData = buffer.floatChannelData else { return buffer }
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let sample = generator(time)
            floatData[0][frame] = sample
            floatData[1][frame] = sample
        }
        
        return buffer
    }
    
    // MARK: - Sound Generators
    
    private func generateKick(time: Double) -> Float {
        let duration = 0.3
        let envelope = max(0, 1.0 - time / duration)
        let pitchDecay = 60.0 * (1.0 + 3.0 * max(0, 0.08 - time) * 12)
        let sample = sin(2.0 * .pi * pitchDecay * time) * envelope * envelope
        return Float(sample * 0.9)
    }
    
    private func generateSnare(time: Double) -> Float {
        let duration = 0.25
        let envelope = max(0, 1.0 - time / duration)
        let noise = Float.random(in: -1...1)
        let tone = Float(sin(2.0 * .pi * 180 * time))
        let snappy = Float(sin(2.0 * .pi * 330 * time) * 0.3)
        let sample = (noise * 0.6 + tone * 0.25 + snappy) * Float(envelope)
        return sample * 0.8
    }
    
    private func generateHiHat(time: Double) -> Float {
        let duration = 0.15
        let envelope = max(0, 1.0 - time / duration)
        let noise = Float.random(in: -1...1)
        // High-pass filter simulation
        let highFreq = Float(sin(2.0 * .pi * 8000 * time) * 0.2)
        let sample = (noise * 0.7 + highFreq) * Float(pow(envelope, 3))
        return sample * 0.6
    }
    
    private func generateClap(time: Double) -> Float {
        let duration = 0.3
        let envelope = max(0, 1.0 - time / duration)
        let noise = Float.random(in: -1...1)
        
        // Multiple micro-bursts for realistic clap
        let burst1 = time < 0.012 ? 1.0 : 0.0
        let burst2 = (time > 0.018 && time < 0.030) ? 0.85 : 0.0
        let burst3 = (time > 0.036 && time < 0.055) ? 0.7 : 0.0
        let burst4 = time > 0.055 ? 0.4 : 0.0
        let burstEnv = burst1 + burst2 + burst3 + burst4
        
        // Band-pass filter simulation
        let midFreq = Float(sin(2.0 * .pi * 1100 * time) * 0.25)
        let sample = (noise * 0.75 + midFreq) * Float(envelope * burstEnv)
        return sample * 0.7
    }
    
    private func generateTom(time: Double) -> Float {
        let duration = 0.35
        let envelope = max(0, 1.0 - time / duration)
        let pitchDecay = 100.0 * (1.0 + max(0, 0.04 - time) * 15)
        let sample = sin(2.0 * .pi * pitchDecay * time) * envelope
        return Float(sample * 0.85)
    }
    
    private func generateCymbal(time: Double) -> Float {
        let duration = 0.8
        let envelope = max(0, 1.0 - time / duration)
        
        // Layered high frequencies for metallic shimmer
        let noise = Float.random(in: -1...1) * 0.35
        let freq1 = Float(sin(2.0 * .pi * 3200 * time))
        let freq2 = Float(sin(2.0 * .pi * 5800 * time) * 0.5)
        let freq3 = Float(sin(2.0 * .pi * 8500 * time) * 0.3)
        let freq4 = Float(sin(2.0 * .pi * 12000 * time) * 0.15)
        
        let metallic = (freq1 + freq2 + freq3 + freq4) * 0.18
        let sample = (noise + metallic) * Float(pow(envelope, 0.7))
        return sample * 0.5
    }
    
    private func generateCowbell(time: Double) -> Float {
        let duration = 0.4
        let envelope = max(0, 1.0 - time / duration)
        
        // Two inharmonic frequencies for cowbell
        let freq1 = sin(2.0 * .pi * 545 * time)
        let freq2 = sin(2.0 * .pi * 815 * time) * 0.7
        let sample = (freq1 + freq2) * envelope * 0.5
        return Float(sample * 0.7)
    }
    
    private func generateShaker(time: Double) -> Float {
        let duration = 0.25
        let envelope = max(0, 1.0 - time / duration)
        let noise = Float.random(in: -1...1)
        
        // Rhythmic pattern
        let pattern = (sin(2.0 * .pi * 25 * time) + 1) / 2
        let sample = noise * Float(envelope * pattern)
        return sample * 0.5
    }
    
    private func generateCluck(time: Double) -> Float {
        let duration = 0.2
        let envelope = max(0, 1.0 - time / duration)
        
        // Chicken cluck - frequency modulated tone with quick attack
        let freqMod = 1.0 + 0.3 * sin(2.0 * .pi * 35 * time)
        let baseFreq = 350.0 * freqMod
        let tone = Float(sin(2.0 * .pi * baseFreq * time))
        
        // Add some harmonics
        let harmonic = Float(sin(2.0 * .pi * baseFreq * 2.5 * time) * 0.3)
        
        // Quick attack, moderate decay
        let attackEnv = min(1.0, time / 0.01)
        let sample = (tone + harmonic) * Float(envelope * envelope * attackEnv)
        return sample * 0.7
    }
    
    // MARK: - WAV Export
    
    private func saveWAV(buffer: AVAudioPCMBuffer, to url: URL) {
        do {
            let file = try AVAudioFile(forWriting: url, settings: buffer.format.settings)
            try file.write(from: buffer)
            print("Saved: \(url.lastPathComponent)")
        } catch {
            print("Failed to save \(url.lastPathComponent): \(error)")
        }
    }
}
