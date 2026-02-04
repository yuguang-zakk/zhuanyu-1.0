import SwiftUI

struct IngredientsBlockEditor: View {
    @Binding var block: RecipeBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Block title", text: $block.title)
                .textFieldStyle(.roundedBorder)

            ForEach($block.ingredients) { $item in
                HStack(spacing: 8) {
                    IconPicker(icon: $item.icon)
                    TextField("Amount", text: $item.amount)
                        .textFieldStyle(.roundedBorder)
                    TextField("Ingredient", text: $item.name)
                        .textFieldStyle(.roundedBorder)

                    Button(role: .destructive) {
                        block.ingredients.removeAll { $0.id == item.id }
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                }
            }

            Button {
                block.ingredients.append(IngredientItem())
            } label: {
                Label("Add ingredient", systemImage: "plus")
            }
            .buttonStyle(.bordered)
        }
    }
}
