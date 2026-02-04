import SwiftUI

extension HeatLevel {
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }

    var symbol: String {
        switch self {
        case .low: return "flame"
        case .medium: return "flame.fill"
        case .high: return "flame.circle.fill"
        }
    }
}
