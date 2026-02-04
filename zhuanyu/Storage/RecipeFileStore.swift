import Foundation
#if canImport(SwiftData) && !ZHUANYU_CLI
import SwiftData
#endif

struct RecipeFileStore {
    static let shared = RecipeFileStore()

    private let fileManager = FileManager.default
    private let recipesDirectoryOverride: URL?

    init(recipesDirectoryOverride: URL? = nil) {
        self.recipesDirectoryOverride = recipesDirectoryOverride
    }

    var recipesDirectory: URL {
        if let override = recipesDirectoryOverride {
            return override
        }
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("Recipes", isDirectory: true)
    }

    func ensureDirectory() {
        if !fileManager.fileExists(atPath: recipesDirectory.path) {
            try? fileManager.createDirectory(at: recipesDirectory, withIntermediateDirectories: true)
        }
    }

    func listRecipeFiles() -> [URL] {
        ensureDirectory()
        let files = (try? fileManager.contentsOfDirectory(at: recipesDirectory, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension.lowercased() == "md" }
    }

    func fileURL(for fileName: String) -> URL {
        recipesDirectory.appendingPathComponent(fileName)
    }

    func readMarkdown(fileName: String) -> String {
        let url = fileURL(for: fileName)
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    func writeMarkdown(fileName: String, contents: String) {
        let url = fileURL(for: fileName)
        try? contents.write(to: url, atomically: true, encoding: .utf8)
    }

    func modificationDate(for url: URL) -> Date? {
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        return attributes?[.modificationDate] as? Date
    }

    func createNewRecipeFile(title: String) -> String {
        ensureDirectory()
        let fileName = "recipe-\(UUID().uuidString).md"
        let document = RecipeDocument(title: title, blocks: [
            .hero(),
            .ingredients(),
            .step()
        ])
        let markdown = RecipeMarkdownCodec.encode(document)
        writeMarkdown(fileName: fileName, contents: markdown)
        return fileName
    }

    func bootstrapSampleIfNeeded() {
        ensureDirectory()
        let existing = listRecipeFiles()
        guard existing.isEmpty else { return }
        let sampleMarkdown = RecipeMarkdownCodec.encode(sampleDocument())
        writeMarkdown(fileName: "sample-stir-fry.md", contents: sampleMarkdown)
    }

    private func sampleDocument() -> RecipeDocument {
        RecipeDocument(
            title: "Weeknight Stir-Fry",
            blocks: [
                RecipeBlock(
                    type: .hero,
                    servings: "2",
                    totalTime: "20m",
                    nutrition: "520 kcal",
                    imageName: "hero"
                ),
                RecipeBlock(
                    type: .ingredients,
                    ingredients: [
                        IngredientItem(name: "Noodles", amount: "200g", icon: "leaf.fill"),
                        IngredientItem(name: "Chili oil", amount: "1 tbsp", icon: "flame.fill"),
                        IngredientItem(name: "Garlic", amount: "2 cloves", icon: "drop.fill")
                    ]
                ),
                RecipeBlock(
                    type: .step,
                    title: "Boil noodles",
                    text: "Boil noodles until al dente.",
                    icon: "timer",
                    durationMinutes: 8,
                    heat: .high
                ),
                RecipeBlock(
                    type: .step,
                    title: "Stir-fry",
                    text: "Toss noodles with chili oil and garlic.",
                    icon: "flame",
                    durationMinutes: 3,
                    heat: .high
                ),
                RecipeBlock(
                    type: .note,
                    text: "Finish with scallions and sesame seeds."
                )
            ]
        )
    }
}

#if canImport(SwiftData) && !ZHUANYU_CLI
struct RecipeSyncer {
    static func sync(context: ModelContext) {
        let store = RecipeFileStore.shared
        store.bootstrapSampleIfNeeded()
        let files = store.listRecipeFiles()

        let existing = (try? context.fetch(FetchDescriptor<RecipeRecord>())) ?? []
        var byFileName: [String: RecipeRecord] = [:]
        for record in existing {
            byFileName[record.fileName] = record
        }

        for file in files {
            let fileName = file.lastPathComponent
            let markdown = store.readMarkdown(fileName: fileName)
            let document = RecipeMarkdownCodec.decode(markdown)
            let updatedAt = store.modificationDate(for: file) ?? Date()

            if let record = byFileName[fileName] {
                if record.title != document.title {
                    record.title = document.title
                }
                record.updatedAt = updatedAt
            } else {
                let record = RecipeRecord(fileName: fileName, title: document.title, updatedAt: updatedAt)
                context.insert(record)
            }
        }
    }
}
#endif
