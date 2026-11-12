import Foundation
import SwiftData

@Model
final class DailyStats {
    var id: UUID
    var dateString: String  // "yyyy-MM-dd"
    var newCount: Int
    var reviewCount: Int
    var correctCount: Int
    var goalMet: Bool

    init(dateString: String) {
        self.id = UUID()
        self.dateString = dateString
        self.newCount = 0
        self.reviewCount = 0
        self.correctCount = 0
        self.goalMet = false
    }

    static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
