import Foundation

struct RecipeBlock: Identifiable, Codable, Hashable {
    var id: UUID
    var type: BlockType

    var title: String
    var text: String
    var icon: String?

    var durationMinutes: Int?
    var heat: HeatLevel?

    var servings: String
    var totalTime: String
    var nutrition: String
    var imageName: String

    var ingredients: [IngredientItem]

    init(
        id: UUID = UUID(),
        type: BlockType,
        title: String = "",
        text: String = "",
        icon: String? = nil,
        durationMinutes: Int? = nil,
        heat: HeatLevel? = nil,
        servings: String = "",
        totalTime: String = "",
        nutrition: String = "",
        imageName: String = "",
        ingredients: [IngredientItem] = []
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.text = text
        self.icon = icon
        self.durationMinutes = durationMinutes
        self.heat = heat
        self.servings = servings
        self.totalTime = totalTime
        self.nutrition = nutrition
        self.imageName = imageName
        self.ingredients = ingredients
    }

    static func hero() -> RecipeBlock {
        RecipeBlock(type: .hero, title: "")
    }

    static func ingredients() -> RecipeBlock {
        RecipeBlock(type: .ingredients, title: "Ingredients")
    }

    static func step() -> RecipeBlock {
        RecipeBlock(type: .step, title: "Step")
    }

    static func note() -> RecipeBlock {
        RecipeBlock(type: .note, title: "Note")
    }
}

struct IngredientItem: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var amount: String
    var icon: String?

    init(id: UUID = UUID(), name: String = "", amount: String = "", icon: String? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
        self.icon = icon
    }
}

enum BlockType: String, Codable, CaseIterable, Hashable, Identifiable {
    case hero
    case ingredients
    case step
    case note

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hero: return "Hero"
        case .ingredients: return "Ingredients"
        case .step: return "Step"
        case .note: return "Note"
        }
    }

    var marker: String {
        "[\(rawValue)]"
    }

    init?(markerLine: String) {
        let trimmed = markerLine.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.hasPrefix("[") && trimmed.hasSuffix("]") else { return nil }
        let name = String(trimmed.dropFirst().dropLast())
        self.init(rawValue: name)
    }
}

enum HeatLevel: String, Codable, CaseIterable, Hashable {
    case low
    case medium
    case high

    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}
