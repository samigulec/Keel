// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KeelCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "KeelCore", targets: ["KeelCore"]),
    ],
    targets: [
        .target(
            name: "KeelSystemShims",
            linkerSettings: [
                .linkedFramework("IOKit", .when(platforms: [.macOS])),
                .linkedFramework("CoreFoundation", .when(platforms: [.macOS])),
            ]
        ),
        .target(name: "KeelCore", dependencies: ["KeelSystemShims"]),
        .testTarget(name: "KeelCoreTests", dependencies: ["KeelCore"]),
    ]
)
