// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DeepSeekMenuBar",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "DeepSeekMenuBar",
            dependencies: [],
            path: "Sources",
            resources: [
                .copy("../Resources")
            ]
        )
    ]
)
