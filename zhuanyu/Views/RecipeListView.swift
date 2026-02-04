import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecipeRecord.updatedAt, order: .reverse) private var recipes: [RecipeRecord]

    @State private var presentedRecord: RecipeRecord?

    var body: some View {
        NavigationStack {
            List {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "No recipes yet",
                        systemImage: "book",
                        description: Text("Create your first visual recipe block.")
                    )
                } else {
                    ForEach(recipes) { record in
                        NavigationLink {
                            RecipeEditorView(record: record)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.title)
                                    .font(.headline)
                                Text(record.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        createRecipe()
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                }
            }
            .task {
                RecipeSyncer.sync(context: modelContext)
            }
            .sheet(item: $presentedRecord) { record in
                NavigationStack {
                    RecipeEditorView(record: record)
                }
            }
        }
    }

    private func createRecipe() {
        let fileName = RecipeFileStore.shared.createNewRecipeFile(title: "Untitled Recipe")
        let record = RecipeRecord(fileName: fileName, title: "Untitled Recipe", updatedAt: Date())
        modelContext.insert(record)
        presentedRecord = record
    }
}
