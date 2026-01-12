import Foundation

struct Pad: Identifiable {
    let id: Int
    let name: String
    let soundFileName: String
    let color: Int // Index into AppColors.padColors
    
    static let allPads: [Pad] = [
        Pad(id: 0, name: "Kick", soundFileName: "kick", color: 0),
        Pad(id: 1, name: "Snare", soundFileName: "snare", color: 1),
        Pad(id: 2, name: "HiHat", soundFileName: "hihat", color: 2),
        Pad(id: 3, name: "Clap", soundFileName: "clap", color: 3),
        Pad(id: 4, name: "Tom", soundFileName: "tom", color: 4),
        Pad(id: 5, name: "Cymbal", soundFileName: "cymbal", color: 5),
        Pad(id: 6, name: "Cowbell", soundFileName: "cowbell", color: 6),
        Pad(id: 7, name: "Shaker", soundFileName: "shaker", color: 7)
    ]
}
