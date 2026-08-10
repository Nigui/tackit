// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Tackit",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "tackit", targets: ["TackitApp"]),
        .library(name: "TackitCore", targets: ["TackitCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0"),
    ],
    targets: [
        .target(name: "TackitCore", dependencies: [.product(name: "Yams", package: "Yams")]),
        .executableTarget(
            name: "TackitApp",
            dependencies: ["TackitCore"],
            resources: [.copy("Resources/editor")]
        ),
        .testTarget(name: "TackitCoreTests", dependencies: ["TackitCore"]),
    ],
    swiftLanguageModes: [.v5]
)
