// swift-tools-version: 6.0
// 6.0 floor: typed throws (`throws(E)`) and Swift 6 strict concurrency
// are 6.0; the project doesn't use 6.1/6.2/6.3-only features, so we
// keep the floor low to match what GitHub's macos-15 runner ships
// (Swift 6.1 as of writing).

import PackageDescription

let package = Package(
    name: "pkim",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.3.0"
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "pkim",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
            ]
        ),
        .testTarget(
            name: "pkimTests",
            dependencies: ["pkim"]
        ),
    ],
    swiftLanguageModes: [.v6],
)
