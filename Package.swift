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
            path: "Sources/MDView",
            // Info.plist is not a SwiftPM resource: it is copied into the
            // .app bundle by scripts/build-app.sh.
            exclude: ["Resources/Info.plist"]
        ),
        .testTarget(
            name: "MDViewTests",
            dependencies: ["MDView"],
            path: "Tests/MDViewTests"
        )
    ]
)
