import Foundation

enum CardState: Int, Codable {
    case new = 0
    case learning = 1
    case review = 2
    case relearning = 3
}

enum CardStatus: String, Codable {
    case active
    case mastered
    case suspended
}

struct Example: Codable, Identifiable, Hashable {
    var id: UUID
    var text: String
    var translation: String

    init(text: String, translation: String) {
        self.id = UUID()
        self.text = text
        self.translation = translation
    }
}

struct FSRSResult {
    let due: Date
    let stability: Double
    let difficulty: Double
    let state: CardState
    let reps: Int
    let lapses: Int
    let elapsedDays: Double
    let scheduledDays: Int
}
