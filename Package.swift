// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Selene",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15)
  ],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .plugin(
      name: "GenerateCode",
      targets: ["GenerateCode"]
    ),
    .executable(
      name: "Selene",
      targets: ["Selene"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-algorithms", .upToNextMajor(from: "1.0.0")),
    .package(url: "https://github.com/apple/swift-syntax", branch: "package-release/509"),
    .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.2.3")),
  ],
  targets: [
    .plugin(
      name: "GenerateCode",
      capability: .command(
        intent: .custom(verb: "generate-env-code", description: "Generate Source Code from Env File")
      ),
      dependencies: [
        .target(name: "Selene"),
      ]
    ),
    .executableTarget(
      name: "Selene",
      dependencies: [
        .product(name: "Algorithms", package: "swift-algorithms"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .testTarget(
      name: "SeleneTests",
      dependencies: [
        .target(name: "Selene"),
      ]
    )
  ]
)
