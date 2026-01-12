import Foundation

struct Loop: Identifiable, Codable {
    let id: UUID
    var events: [LoopEvent]
    let bpm: Int
    let createdAt: Date
    
    init(events: [LoopEvent] = [], bpm: Int = 120) {
        self.id = UUID()
        self.events = events
        self.bpm = bpm
        self.createdAt = Date()
    }
}

struct LoopEvent: Codable, Identifiable {
    let id: UUID
    let padId: Int
    let timestamp: TimeInterval // Time in seconds from loop start
    
    init(padId: Int, timestamp: TimeInterval) {
        self.id = UUID()
        self.padId = padId
        self.timestamp = timestamp
    }
}
