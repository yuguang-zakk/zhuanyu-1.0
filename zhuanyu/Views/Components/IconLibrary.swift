import SwiftUI

struct IconChoice: Identifiable, Hashable {
    let symbol: String
    let label: String

    var id: String { symbol }
}

struct IconLibrary {
    static let choices: [IconChoice] = [
        IconChoice(symbol: "flame.fill", label: "Flame"),
        IconChoice(symbol: "timer", label: "Timer"),
        IconChoice(symbol: "leaf.fill", label: "Leaf"),
        IconChoice(symbol: "drop.fill", label: "Drop"),
        IconChoice(symbol: "fork.knife", label: "Fork"),
        IconChoice(symbol: "circle.grid.2x2.fill", label: "Grid"),
        IconChoice(symbol: "sparkles", label: "Spark"),
        IconChoice(symbol: "takeoutbag.and.cup.and.straw.fill", label: "To Go"),
        IconChoice(symbol: "bag.fill", label: "Bag"),
        IconChoice(symbol: "cart.fill", label: "Cart")
    ]

    static func label(for symbol: String?) -> String {
        guard let symbol else { return "Pick Icon" }
        return choices.first(where: { $0.symbol == symbol })?.label ?? symbol
    }
}

struct IconPicker: View {
    @Binding var icon: String?

    var body: some View {
        Menu {
            Button(role: .destructive) {
                icon = nil
            } label: {
                Label("Clear", systemImage: "xmark")
            }

            ForEach(IconLibrary.choices) { choice in
                Button {
                    icon = choice.symbol
                } label: {
                    Label(choice.label, systemImage: choice.symbol)
                }
            }
        } label: {
            Label(IconLibrary.label(for: icon), systemImage: icon ?? "photo")
        }
    }
}
