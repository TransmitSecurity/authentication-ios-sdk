// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription

let package = Package(
    name: "TSAuthenticationSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "TSAuthenticationSDK",
            targets: ["TSAuthenticationSDK", "TSAuthenticationSDK-Dependencies"])
    ],
    dependencies: [
        .package(url: "https://github.com/TransmitSecurity/core-ios-sdk.git", from: "1.0.22")
    ],
    targets: [
        .binaryTarget(
            name: "TSAuthenticationSDK",
            path: "Sources/TSAuthenticationSDK.xcframework"
        ),
        .target(name: "TSAuthenticationSDK-Dependencies",
                dependencies: [
                    .product(name: "TSCoreSDK",
                             package: "core-ios-sdk")
                ]),
    ]
)
