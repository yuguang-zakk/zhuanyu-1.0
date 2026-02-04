import Foundation

struct RecipeMarkdownCodec {
    static func decode(_ markdown: String) -> RecipeDocument {
        let lines = markdown.split(whereSeparator: \.isNewline).map(String.init)
        var title = "Untitled Recipe"
        var blocks: [RecipeBlock] = []

        var currentType: BlockType?
        var currentLines: [String] = []

        func flushBlock() {
            guard let type = currentType else { return }
            let block = parseBlock(type: type, lines: currentLines)
            blocks.append(block)
            currentLines = []
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") && title == "Untitled Recipe" {
                title = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                continue
            }

            if let markerType = BlockType(markerLine: trimmed) {
                flushBlock()
                currentType = markerType
                continue
            }

            if currentType != nil {
                currentLines.append(line)
            }
        }

        flushBlock()

        return RecipeDocument(title: title, blocks: blocks)
    }

    static func encode(_ document: RecipeDocument) -> String {
        var output: [String] = []
        output.append("# \(document.title)")
        output.append("")

        for block in document.blocks {
            output.append(block.type.marker)
            switch block.type {
            case .hero:
                output.append(contentsOf: encodeHero(block))
            case .ingredients:
                output.append(contentsOf: encodeIngredients(block))
            case .step:
                output.append(contentsOf: encodeStep(block))
            case .note:
                output.append(contentsOf: encodeNote(block))
            }
            output.append("")
        }

        return output.joined(separator: "\n")
    }

    private static func parseBlock(type: BlockType, lines: [String]) -> RecipeBlock {
        switch type {
        case .hero:
            return parseHero(lines)
        case .ingredients:
            return parseIngredients(lines)
        case .step:
            return parseStep(lines)
        case .note:
            return parseNote(lines)
        }
    }

    private static func parseHero(_ lines: [String]) -> RecipeBlock {
        var block = RecipeBlock.hero()
        for line in lines {
            guard let pair = parseKeyValue(line) else { continue }
            switch pair.key {
            case "image": block.imageName = pair.value
            case "servings": block.servings = pair.value
            case "time": block.totalTime = pair.value
            case "nutrition": block.nutrition = pair.value
            default: break
            }
        }
        return block
    }

    private static func parseIngredients(_ lines: [String]) -> RecipeBlock {
        var block = RecipeBlock.ingredients()
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("-") else { continue }
            let raw = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
            let parts = raw.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }

            var name: String = ""
            var amount: String = ""
            var icon: String?

            for part in parts {
                if let pair = parseKeyValue(String(part)) {
                    switch pair.key {
                    case "name": name = pair.value
                    case "amount": amount = pair.value
                    case "icon": icon = pair.value
                    default: break
                    }
                } else if name.isEmpty {
                    name = String(part)
                } else if amount.isEmpty {
                    amount = String(part)
                }
            }

            if !name.isEmpty {
                block.ingredients.append(IngredientItem(name: name, amount: amount, icon: icon))
            }
        }
        return block
    }

    private static func parseStep(_ lines: [String]) -> RecipeBlock {
        var block = RecipeBlock.step()
        var textLines: [String] = []

        for line in lines {
            if let pair = parseKeyValue(line) {
                switch pair.key {
                case "title": block.title = pair.value
                case "time": block.durationMinutes = parseMinutes(pair.value)
                case "heat": block.heat = HeatLevel(rawValue: pair.value.lowercased())
                case "icon": block.icon = pair.value
                case "text": textLines.append(pair.value.replacingOccurrences(of: "\\n", with: "\n"))
                default: break
                }
            } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                textLines.append(line)
            }
        }

        block.text = textLines.joined(separator: "\n")
        return block
    }

    private static func parseNote(_ lines: [String]) -> RecipeBlock {
        var block = RecipeBlock.note()
        var textLines: [String] = []
        for line in lines {
            if let pair = parseKeyValue(line), pair.key == "text" {
                textLines.append(pair.value.replacingOccurrences(of: "\\n", with: "\n"))
            } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                textLines.append(line)
            }
        }
        block.text = textLines.joined(separator: "\n")
        return block
    }

    private static func encodeHero(_ block: RecipeBlock) -> [String] {
        var lines: [String] = []
        if !block.imageName.isEmpty { lines.append("image: \(block.imageName)") }
        if !block.servings.isEmpty { lines.append("servings: \(block.servings)") }
        if !block.totalTime.isEmpty { lines.append("time: \(block.totalTime)") }
        if !block.nutrition.isEmpty { lines.append("nutrition: \(block.nutrition)") }
        return lines
    }

    private static func encodeIngredients(_ block: RecipeBlock) -> [String] {
        var lines: [String] = []
        for item in block.ingredients {
            var parts: [String] = []
            if !item.name.isEmpty { parts.append("name=\(item.name)") }
            if !item.amount.isEmpty { parts.append("amount=\(item.amount)") }
            if let icon = item.icon, !icon.isEmpty { parts.append("icon=\(icon)") }
            if parts.isEmpty { continue }
            lines.append("- \(parts.joined(separator: " | "))")
        }
        return lines
    }

    private static func encodeStep(_ block: RecipeBlock) -> [String] {
        var lines: [String] = []
        if !block.title.isEmpty { lines.append("title: \(block.title)") }
        if let minutes = block.durationMinutes, minutes > 0 { lines.append("time: \(minutes)m") }
        if let heat = block.heat { lines.append("heat: \(heat.rawValue)") }
        if let icon = block.icon, !icon.isEmpty { lines.append("icon: \(icon)") }
        if !block.text.isEmpty {
            let encodedText = block.text.replacingOccurrences(of: "\n", with: "\\n")
            lines.append("text: \(encodedText)")
        }
        return lines
    }

    private static func encodeNote(_ block: RecipeBlock) -> [String] {
        guard !block.text.isEmpty else { return [] }
        let encodedText = block.text.replacingOccurrences(of: "\n", with: "\\n")
        return ["text: \(encodedText)"]
    }

    private static func parseKeyValue(_ line: String) -> (key: String, value: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        if let range = trimmed.range(of: ":") {
            let key = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces).lowercased()
            let value = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if !key.isEmpty { return (key, value) }
        }

        if let range = trimmed.range(of: "=") {
            let key = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces).lowercased()
            let value = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if !key.isEmpty { return (key, value) }
        }

        return nil
    }

    private static func parseMinutes(_ value: String) -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.contains("h") {
            let parts = trimmed.split(separator: "h", maxSplits: 1, omittingEmptySubsequences: false)
            let hours = Int(parts.first?.filter(\.isNumber) ?? "") ?? 0
            let minutes = Int(parts.last?.filter(\.isNumber) ?? "") ?? 0
            return hours * 60 + minutes
        }

        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":")
            if parts.count == 2 {
                let minutes = Int(parts[0]) ?? 0
                let seconds = Int(parts[1]) ?? 0
                return minutes + Int(round(Double(seconds) / 60.0))
            }
        }

        let digits = trimmed.filter(\.isNumber)
        return Int(digits)
    }
}
