// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShakeReporter",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ShakeReporter",
            targets: ["ShakeReporter"]
        )
    ],
    targets: [
        .target(
            name: "ShakeReporter",
            path: "Sources/ShakeReporter"
        )
    ]
)
