// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyScript",
    products: [
        .executable(
            name: "SwiftyScriptDemo",
            targets: ["SwiftyScriptDemo"]
        ),
        .library(
            name: "SwiftyScript",
            targets: ["SwiftyScript"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "SwiftyScript",
            dependencies: [
                "Rainbow"
            ]
        ),
        .target(
            name: "SwiftyScriptDemo",
            dependencies: [
                "SwiftyScript",
                "Rainbow"
            ]
        ),
    ]
)
