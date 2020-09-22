// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreCQI",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13), .tvOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "CoreCQI", targets: ["CoreCQI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/wildthink/FeistyDB", .branch("master")),
//        .package(url: "https://github.com/wickwirew/Runtime", .branch("master"))
         .package(url: "https://github.com/wildthink/Runtime", .branch("master"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CoreCQI",
            dependencies: ["FeistyDB", 
                .product(name: "Runtime", package: "Runtime"),
//                 .product(name: "Runtime", package: "CRuntime"),
                .product(name: "FeistyExtensions", package: "FeistyDB"),
             ]
        ),
        .testTarget(
            name: "CoreCQITests",
            dependencies: ["CoreCQI"]),
    ]
)
