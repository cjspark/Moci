import Foundation
import SwiftData

@Model
final class Deck {
    var id: UUID
    var title: String
    var language: String
    var glossLanguage: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card] = []

    @Relationship(deleteRule: .cascade, inverse: \Chapter.deck)
    var chapters: [Chapter] = []

    init(title: String, language: String, glossLanguage: String) {
        self.id = UUID()
        self.title = title
        self.language = language
        self.glossLanguage = glossLanguage
        self.createdAt = Date()
    }

    var activeCards: [Card] {
        cards.filter { $0.status == .active }
    }

    var newCardsCount: Int {
        activeCards.filter { $0.fsrsState == .new }.count
    }

    var dueCardsCount: Int {
        let now = Date()
        return activeCards.filter { $0.fsrsState != .new && $0.due <= now }.count
    }
}
