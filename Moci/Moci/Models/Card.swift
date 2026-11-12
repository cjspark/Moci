import Foundation
import SwiftData

@Model
final class Card {
    var id: UUID
    var lemma: String
    var surfaceForm: String
    var reading: String
    var pos: String
    var meaning: String
    var aiGenerated: Bool
    var status: CardStatus
    var deckID: UUID?          // redundant but reliable for @Query predicates
    var deck: Deck?
    var sourceChapter: Chapter?

    // JSON-encoded to stay compatible with SwiftData
    var examplesJSON: String
    var extraJSON: String

    // FSRS fields
    var due: Date
    var stability: Double
    var difficulty: Double
    var reps: Int
    var lapses: Int
    var fsrsState: CardState
    var lastReview: Date?

    @Relationship(deleteRule: .cascade, inverse: \ReviewLog.card)
    var reviewLogs: [ReviewLog] = []

    init(
        lemma: String,
        surfaceForm: String,
        reading: String,
        pos: String,
        meaning: String,
        examples: [Example] = [],
        extra: [String: String] = [:],
        aiGenerated: Bool = false
    ) {
        self.id = UUID()
        self.lemma = lemma
        self.surfaceForm = surfaceForm
        self.reading = reading
        self.pos = pos
        self.meaning = meaning
        self.aiGenerated = aiGenerated
        self.status = .active
        self.deckID = nil
        self.examplesJSON = (try? String(data: JSONEncoder().encode(examples), encoding: .utf8)) ?? "[]"
        self.extraJSON = (try? String(data: JSONEncoder().encode(extra), encoding: .utf8)) ?? "{}"
        self.due = Date()
        self.stability = 0
        self.difficulty = 0
        self.reps = 0
        self.lapses = 0
        self.fsrsState = .new
    }

    var examples: [Example] {
        get {
            guard let data = examplesJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([Example].self, from: data) else { return [] }
            return decoded
        }
        set {
            examplesJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    var extra: [String: String] {
        get {
            guard let data = extraJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
            return decoded
        }
        set {
            extraJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "{}"
        }
    }

    func apply(_ result: FSRSResult) {
        due = result.due
        stability = result.stability
        difficulty = result.difficulty
        fsrsState = result.state
        reps = result.reps
        lapses = result.lapses
        lastReview = Date()
    }
}
