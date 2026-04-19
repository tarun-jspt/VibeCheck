import Foundation
import SwiftData

@Model
final class VibeEntry {
    var id: UUID
    var timestamp: Date
    var moodEmoji: String
    var moodID: String
    var note: String
    var intensity: Double // Range: 1.0 – 5.0

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        moodID: String,
        note: String = "",
        intensity: Double,
        moodEmoji: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.moodID = moodID
        self.note = note
        self.intensity = min(max(intensity, 1.0), 5.0) // Clamp to 1–5
        self.moodEmoji = moodEmoji
    }
}
