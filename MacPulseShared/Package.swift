// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacPulseShared",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "MacPulseShared", targets: ["MacPulseShared"]),
    ],
    targets: [
        .target(name: "MacPulseShared"),
    ]
)
