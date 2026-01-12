import Foundation

struct SavedLoop: Identifiable, Codable {
    let id: UUID
    let name: String
    let loop: Loop
    let savedAt: Date
    
    init(name: String, loop: Loop) {
        self.id = UUID()
        self.name = name
        self.loop = loop
        self.savedAt = Date()
    }
}

class LoopStorage: ObservableObject {
    @Published var savedLoops: [SavedLoop] = []
    
    private let storageKey = "savedLoops"
    
    init() {
        loadLoops()
    }
    
    func saveLoop(_ loop: Loop, name: String) {
        let savedLoop = SavedLoop(name: name, loop: loop)
        savedLoops.insert(savedLoop, at: 0)
        persistLoops()
    }
    
    func deleteLoop(_ loop: SavedLoop) {
        savedLoops.removeAll { $0.id == loop.id }
        persistLoops()
    }
    
    private func loadLoops() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let loops = try? JSONDecoder().decode([SavedLoop].self, from: data) else {
            return
        }
        savedLoops = loops
    }
    
    private func persistLoops() {
        guard let data = try? JSONEncoder().encode(savedLoops) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
