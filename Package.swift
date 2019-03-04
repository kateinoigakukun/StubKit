// swift-tools-version:4.2

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
