// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChatSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "ChatSDK",
            targets: ["ChatSDK"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-log.git",
            from: "1.4.0"
        )
    ],
    targets: [
        .target(
            name: "ChatSDK",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Sources/ChatSDK"
        ),
        .testTarget(
            name: "ChatSDKTests",
            dependencies: ["ChatSDK"]),
    ]
)
    
