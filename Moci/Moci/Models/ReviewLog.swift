import Foundation
import SwiftData

@Model
final class ReviewLog {
    var id: UUID
    var rating: Int
    var reviewedAt: Date
    var elapsedDays: Double
    var scheduledDays: Int
    var card: Card?

    init(rating: Int, elapsedDays: Double, scheduledDays: Int) {
        self.id = UUID()
        self.rating = rating
        self.reviewedAt = Date()
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
    }
}
