// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Tackit",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "tackit", targets: ["TackitApp"]),
        .library(name: "TackitCore", targets: ["TackitCore"]),
    ],
    targets: [
        .target(name: "TackitCore"),
        .executableTarget(
            name: "TackitApp",
            dependencies: ["TackitCore"],
            resources: [.copy("Resources/editor")]
        ),
        .testTarget(name: "TackitCoreTests", dependencies: ["TackitCore"]),
    ],
    swiftLanguageModes: [.v5]
)
