// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "StubKit",
    products: [
        .library(
            name: "StubKit",
            targets: ["StubKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "StubKit",
            dependencies: []),
        .testTarget(
            name: "StubKitTests",
            dependencies: ["StubKit"]),
    ]
)
