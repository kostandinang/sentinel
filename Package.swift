// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Sentinel",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Sentinel",
            targets: ["Sentinel"]
        )
    ],
    dependencies: [
        // No external dependencies for now - keeping it simple
    ],
    targets: [
        .executableTarget(
            name: "Sentinel",
            dependencies: [],
            path: "Sentinel",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
