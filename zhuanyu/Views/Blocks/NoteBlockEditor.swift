import SwiftUI

struct NoteBlockEditor: View {
    @Binding var block: RecipeBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $block.text)
                .frame(minHeight: 80)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        }
    }
}
