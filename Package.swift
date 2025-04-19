// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SNKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SNKit",
            targets: ["SNKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SNKit",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "SNKitTests",
            dependencies: ["SNKit"],
            path: "Tests/SNKitTests")
    ]
)
