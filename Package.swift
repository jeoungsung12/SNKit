// swift-tools-version: 5.9
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
            path: "Sources",
            publicHeaderPath: "Sources",
            swiftSettings: [
                .define("SWIFT_PACKAGE")
            ]
        ),
        .testTarget(
            name: "SNKitTests",
            dependencies: ["SNKit"],
            path: "Tests/SNKitTests")
    ]
)