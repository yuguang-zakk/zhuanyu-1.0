import Foundation
import SwiftData

@Model
final class RecipeRecord {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var title: String
    var updatedAt: Date

    init(id: UUID = UUID(), fileName: String, title: String, updatedAt: Date = Date()) {
        self.id = id
        self.fileName = fileName
        self.title = title
        self.updatedAt = updatedAt
    }
}
