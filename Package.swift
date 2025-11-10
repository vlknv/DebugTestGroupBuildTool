// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DebugTestGroupBuildTool",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "DebugTestGroupBuildTool", targets: ["DebugTestGroupBuildTool"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "602.0.0")
    ],
    targets: [
        .executableTarget(
            name: "DebugTestGroupBuildTool",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ]
        )
    ]
)
