// swift-tools-version: 5.9
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
            swiftSettings: [
                .define("SWIFT_PACKAGE")
            ],
            linkerSettings: [
                .linkedFramework("UIKit")
            ]
        ),
        .testTarget(
            name: "SNKitTests",
            dependencies: ["SNKit"],
            path: "Tests/SNKitTests")
    ]
)