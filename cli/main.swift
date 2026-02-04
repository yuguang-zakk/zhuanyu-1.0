import Foundation

private struct CLIError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}

private func usage(defaultDir: URL) {
    let text = """
Zhuanyu CLI

Usage:
  zhuanyu-cli list [--dir <path>]
  zhuanyu-cli show <file> [--dir <path>]
  zhuanyu-cli cat <file> [--dir <path>]
  zhuanyu-cli new <title> [--dir <path>]
  zhuanyu-cli sample [--dir <path>]
  zhuanyu-cli validate <file> [--dir <path>]

Notes:
  - Default recipe directory: \(defaultDir.path)
  - Use --dir to point at a different Recipes folder

Examples:
  zhuanyu-cli list
  zhuanyu-cli new "Weeknight Stir-Fry"
  zhuanyu-cli show sample-stir-fry.md
  zhuanyu-cli validate ~/Documents/Recipes/sample-stir-fry.md
"""
    print(text)
}

private func parseDir(from args: [String]) throws -> (dir: String?, remaining: [String]) {
    var remaining: [String] = []
    var dir: String?

    var index = 0
    while index < args.count {
        let arg = args[index]
        if arg == "--dir" || arg == "-d" {
            guard index + 1 < args.count else {
                throw CLIError(message: "Missing value for --dir")
            }
            dir = args[index + 1]
            index += 2
            continue
        }
        if arg.hasPrefix("--dir=") {
            dir = String(arg.dropFirst("--dir=".count))
            index += 1
            continue
        }
        remaining.append(arg)
        index += 1
    }

    return (dir, remaining)
}

private func resolveDirectory(_ dirPath: String?) -> URL? {
    guard let dirPath else { return nil }
    let expanded = (dirPath as NSString).expandingTildeInPath
    return URL(fileURLWithPath: expanded, isDirectory: true)
}

private func loadMarkdown(for input: String, store: RecipeFileStore) -> (markdown: String, url: URL) {
    let expanded = (input as NSString).expandingTildeInPath
    if expanded.contains("/") {
        let url = URL(fileURLWithPath: expanded)
        let markdown = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        return (markdown, url)
    }

    let url = store.fileURL(for: input)
    let markdown = store.readMarkdown(fileName: input)
    return (markdown, url)
}

private func isoString(for date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
}

private func listRecipes(store: RecipeFileStore) {
    store.ensureDirectory()
    let files = store.listRecipeFiles().sorted { $0.lastPathComponent < $1.lastPathComponent }

    if files.isEmpty {
        print("No recipes found in \(store.recipesDirectory.path)")
        return
    }

    print("Recipes in \(store.recipesDirectory.path):")
    for file in files {
        let name = file.lastPathComponent
        let markdown = store.readMarkdown(fileName: name)
        let document = RecipeMarkdownCodec.decode(markdown)
        let updated = store.modificationDate(for: file).map(isoString) ?? "unknown"
        print("- \(name) | \(document.title) | updated \(updated)")
    }
}

private func showRecipe(store: RecipeFileStore, input: String) throws {
    let loaded = loadMarkdown(for: input, store: store)
    guard !loaded.markdown.isEmpty else {
        throw CLIError(message: "No markdown found at \(loaded.url.path)")
    }

    let document = RecipeMarkdownCodec.decode(loaded.markdown)
    print("Title: \(document.title)")
    print("Blocks: \(document.blocks.count)")

    var counts: [BlockType: Int] = [:]
    for block in document.blocks {
        counts[block.type, default: 0] += 1
    }

    let summary = BlockType.allCases.map { type in
        let count = counts[type, default: 0]
        return "\(type.displayName)=\(count)"
    }.joined(separator: ", ")
    print("Block types: \(summary)")

    for (index, block) in document.blocks.enumerated() {
        print("Block \(index + 1): \(block.type.displayName)")
        switch block.type {
        case .hero:
            if !block.servings.isEmpty { print("  servings: \(block.servings)") }
            if !block.totalTime.isEmpty { print("  time: \(block.totalTime)") }
            if !block.nutrition.isEmpty { print("  nutrition: \(block.nutrition)") }
            if !block.imageName.isEmpty { print("  image: \(block.imageName)") }
        case .ingredients:
            print("  ingredients: \(block.ingredients.count)")
        case .step:
            if !block.title.isEmpty { print("  title: \(block.title)") }
            if let minutes = block.durationMinutes { print("  time: \(minutes)m") }
            if let heat = block.heat { print("  heat: \(heat.rawValue)") }
            if let icon = block.icon, !icon.isEmpty { print("  icon: \(icon)") }
            if !block.text.isEmpty { print("  text: \(block.text)") }
        case .note:
            if !block.text.isEmpty { print("  text: \(block.text)") }
        }
    }
}

private func catRecipe(store: RecipeFileStore, input: String) throws {
    let loaded = loadMarkdown(for: input, store: store)
    guard !loaded.markdown.isEmpty else {
        throw CLIError(message: "No markdown found at \(loaded.url.path)")
    }
    print(loaded.markdown)
}

private func createRecipe(store: RecipeFileStore, title: String) throws {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
        throw CLIError(message: "Title cannot be empty")
    }
    let fileName = store.createNewRecipeFile(title: trimmed)
    print("Created \(fileName) in \(store.recipesDirectory.path)")
}

private func createSample(store: RecipeFileStore) {
    store.bootstrapSampleIfNeeded()
    print("Sample ensured in \(store.recipesDirectory.path)")
}

private func validateRecipe(store: RecipeFileStore, input: String) throws {
    let loaded = loadMarkdown(for: input, store: store)
    guard !loaded.markdown.isEmpty else {
        throw CLIError(message: "No markdown found at \(loaded.url.path)")
    }

    let document = RecipeMarkdownCodec.decode(loaded.markdown)
    let reencoded = RecipeMarkdownCodec.encode(document)

    let normalizedOriginal = loaded.markdown.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalizedReencoded = reencoded.trimmingCharacters(in: .whitespacesAndNewlines)

    if normalizedOriginal == normalizedReencoded {
        print("Round-trip OK for \(loaded.url.lastPathComponent)")
    } else {
        print("Round-trip differs for \(loaded.url.lastPathComponent)")
        print("Use 'cat' to compare the encoded output if needed.")
    }
}

private func run() -> Int {
    let rawArgs = Array(CommandLine.arguments.dropFirst())
    let defaultDir = RecipeFileStore().recipesDirectory

    if rawArgs.isEmpty || rawArgs.contains("-h") || rawArgs.contains("--help") || rawArgs.first == "help" {
        usage(defaultDir: defaultDir)
        return 0
    }

    do {
        let parsed = try parseDir(from: rawArgs)
        let store = RecipeFileStore(recipesDirectoryOverride: resolveDirectory(parsed.dir))
        let args = parsed.remaining

        guard let command = args.first else {
            usage(defaultDir: defaultDir)
            return 0
        }

        switch command {
        case "list":
            listRecipes(store: store)
        case "show":
            guard args.count >= 2 else { throw CLIError(message: "Missing file argument") }
            try showRecipe(store: store, input: args[1])
        case "cat":
            guard args.count >= 2 else { throw CLIError(message: "Missing file argument") }
            try catRecipe(store: store, input: args[1])
        case "new":
            let title = args.dropFirst().joined(separator: " ")
            try createRecipe(store: store, title: title)
        case "sample":
            createSample(store: store)
        case "validate":
            guard args.count >= 2 else { throw CLIError(message: "Missing file argument") }
            try validateRecipe(store: store, input: args[1])
        default:
            throw CLIError(message: "Unknown command: \(command)")
        }

        return 0
    } catch {
        let defaultDir = RecipeFileStore().recipesDirectory
        print("Error: \(error)")
        usage(defaultDir: defaultDir)
        return 1
    }
}

exit(run())
