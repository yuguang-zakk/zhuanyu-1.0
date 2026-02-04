// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZhuanyuCLI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "zhuanyu-cli", targets: ["ZhuanyuCLI"])
    ],
    targets: [
        .executableTarget(
            name: "ZhuanyuCLI",
            path: ".",
            sources: [
                "cli/main.swift",
                "zhuanyu/Models/RecipeBlock.swift",
                "zhuanyu/Models/RecipeDocument.swift",
                "zhuanyu/Parsing/RecipeMarkdownCodec.swift",
                "zhuanyu/Storage/RecipeFileStore.swift"
            ],
            swiftSettings: [
                .define("ZHUANYU_CLI")
            ]
        )
    ]
)
