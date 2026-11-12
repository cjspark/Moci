import Foundation
import SwiftData

@Model
final class Chapter {
    var id: UUID
    var index: Int
    var title: String
    var deck: Deck?

    init(index: Int, title: String) {
        self.id = UUID()
        self.index = index
        self.title = title
    }
}
