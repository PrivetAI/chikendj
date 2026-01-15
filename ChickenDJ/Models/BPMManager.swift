import Foundation
import Combine

class BPMManager: ObservableObject {
    @Published var bpm: Int = 120 {
        didSet {
            if isMetronomeRunning {
                restartMetronome()
            }
        }
    }
    @Published var isMetronomeRunning = false
    @Published var currentBeat: Int = 0
    @Published var beatsPerBar: Int = 4
    
    private var metronomeTimer: Timer?
    private var onTick: (() -> Void)?
    
    var beatInterval: TimeInterval {
        60.0 / Double(bpm)
    }
    
    // Preset BPM values
    static let presets: [Int] = [80, 90, 100, 110, 120, 130, 140, 150, 160]
    
    func startMetronome(onTick: @escaping () -> Void) {
        self.onTick = onTick
        isMetronomeRunning = true
        currentBeat = 0
        
        metronomeTimer = Timer.scheduledTimer(withTimeInterval: beatInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentBeat = (self.currentBeat + 1) % self.beatsPerBar
            self.onTick?()
        }
        
        // Play first beat immediately
        onTick()
    }
    
    func stopMetronome() {
        metronomeTimer?.invalidate()
        metronomeTimer = nil
        isMetronomeRunning = false
        currentBeat = 0
    }
    
    private func restartMetronome() {
        guard let onTick = onTick else { return }
        metronomeTimer?.invalidate()
        
        metronomeTimer = Timer.scheduledTimer(withTimeInterval: beatInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentBeat = (self.currentBeat + 1) % self.beatsPerBar
            self.onTick?()
        }
    }
    
    // Quantize timestamp to nearest beat
    func quantize(_ timestamp: TimeInterval, strength: Double = 0.5) -> TimeInterval {
        let beatDuration = beatInterval
        let nearestBeat = round(timestamp / beatDuration) * beatDuration
        return timestamp + (nearestBeat - timestamp) * strength
    }
    
    func incrementBPM(by amount: Int = 5) {
        bpm = min(200, bpm + amount)
    }
    
    func decrementBPM(by amount: Int = 5) {
        bpm = max(60, bpm - amount)
    }
}
