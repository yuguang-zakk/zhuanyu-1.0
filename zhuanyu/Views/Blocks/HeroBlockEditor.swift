import SwiftUI

struct HeroBlockEditor: View {
    @Binding var block: RecipeBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Image name (for now)", text: $block.imageName)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                TextField("Servings", text: $block.servings)
                    .textFieldStyle(.roundedBorder)
                TextField("Total time", text: $block.totalTime)
                    .textFieldStyle(.roundedBorder)
            }

            TextField("Nutrition summary", text: $block.nutrition)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                Image(systemName: "photo")
                Text(block.imageName.isEmpty ? "Add a hero image later" : block.imageName)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
