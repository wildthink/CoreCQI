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
        .package(url: "https://github.com/davedelong/Time", from: "0.9.1"),
        .package(url: "https://github.com/wildthink/FeistyDB", .branch("master")),
        .package(url: "https://github.com/wildthink/Runtime", .branch("master")),
        .package(url: "https://github.com/wildthink/MOSchema", .branch("main")),
//        .package(url: "https://github.com/phimage/MomXML", from: "1.2.0"),
//        .package(url: "https://github.com/drmohundro/SWXMLHash.git", from: "5.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CoreCQI",
            dependencies: ["FeistyDB", 
                .product(name: "MOSchema", package: "MOSchema"),
                .product(name: "Time", package: "Time"),
                .product(name: "Runtime", package: "Runtime"),
                .product(name: "FeistyExtensions", package: "FeistyDB"),
             ],
            resources: [.copy("Model.xcdatamodel")]
        ),
        .testTarget(
            name: "CoreCQITests",
            dependencies: ["CoreCQI"]),
    ],
    swiftLanguageVersions: [.v5]
)
