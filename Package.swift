// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MDView",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "MDView",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui")
            ],
            path: "Sources/MDView"
        )
    ]
)
