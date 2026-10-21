// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KeelCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "KeelCore", targets: ["KeelCore"]),
    ],
    targets: [
        .target(name: "KeelCore"),
        .testTarget(name: "KeelCoreTests", dependencies: ["KeelCore"]),
    ]
)
