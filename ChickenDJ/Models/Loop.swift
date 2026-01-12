import Foundation

struct Loop: Identifiable, Codable {
    let id: UUID
    var events: [LoopEvent]
    let createdAt: Date
    
    var duration: TimeInterval {
        events.last?.timestamp ?? 0
    }
    
    init(events: [LoopEvent] = []) {
        self.id = UUID()
        self.events = events
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
