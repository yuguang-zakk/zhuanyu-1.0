import SwiftUI
import SwiftData

struct RecipeEditorView: View {
    @Environment(\.modelContext) private var modelContext

    let record: RecipeRecord

    @State private var title: String = ""
    @State private var blocks: [RecipeBlock] = []
    @State private var isLoaded = false
    @State private var showSavedToast = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Recipe title", text: $title)
                    .font(.system(size: 28, weight: .bold))
                    .padding(.vertical, 8)

                ForEach($blocks) { $block in
                    BlockCard(title: block.type.displayName, onDelete: {
                        blocks.removeAll { $0.id == block.id }
                    }) {
                        switch block.type {
                        case .hero:
                            HeroBlockEditor(block: $block)
                        case .ingredients:
                            IngredientsBlockEditor(block: $block)
                        case .step:
                            StepBlockEditor(block: $block)
                        case .note:
                            NoteBlockEditor(block: $block)
                        }
                    }
                }

                Button {
                    blocks.append(.step())
                } label: {
                    Label("Add quick step", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
            .padding(16)
        }
        .navigationTitle("Editor")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Hero block") { blocks.append(.hero()) }
                    Button("Ingredients block") { blocks.append(.ingredients()) }
                    Button("Step block") { blocks.append(.step()) }
                    Button("Note block") { blocks.append(.note()) }
                } label: {
                    Label("Add block", systemImage: "plus")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                }
            }
        }
        .task {
            loadIfNeeded()
        }
        .overlay(alignment: .top) {
            if showSavedToast {
                Text("Saved")
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSavedToast)
    }

    private func loadIfNeeded() {
        guard !isLoaded else { return }
        let markdown = RecipeFileStore.shared.readMarkdown(fileName: record.fileName)
        let document = RecipeMarkdownCodec.decode(markdown)
        title = document.title
        blocks = document.blocks.isEmpty ? [
            .hero(),
            .ingredients(),
            .step()
        ] : document.blocks
        isLoaded = true
    }

    private func save() {
        let document = RecipeDocument(title: title.isEmpty ? "Untitled Recipe" : title, blocks: blocks)
        let markdown = RecipeMarkdownCodec.encode(document)
        RecipeFileStore.shared.writeMarkdown(fileName: record.fileName, contents: markdown)
        record.title = document.title
        record.updatedAt = Date()
        try? modelContext.save()

        showSavedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showSavedToast = false
        }
    }
}
