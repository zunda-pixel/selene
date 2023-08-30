// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GenEnvCode",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15)
  ],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .plugin(
      name: "GenEnvCode",
      targets: ["GenEnvCode"]
    ),
    .executable(
      name: "GenEnvCodeExe",
      targets: ["GenEnvCodeExe"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-algorithms", .upToNextMajor(from: "1.0.0")),
    .package(url: "https://github.com/apple/swift-syntax", branch: "package-release/509"),
    .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.2.3")),
  ],
  targets: [
    .plugin(
      name: "GenEnvCode",
      capability: .command(
        intent: .custom(verb: "generate-env", description: "Generate Source Code from Env File")
      ),
      dependencies: [
        .target(name: "GenEnvCodeExe"),
      ]
    ),
    .executableTarget(
      name: "GenEnvCodeExe",
      dependencies: [
        .product(name: "Algorithms", package: "swift-algorithms"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .testTarget(
      name: "GenEnvCodeTests",
      dependencies: [
        .target(name: "GenEnvCodeExe"),
      ]
    )
  ]
)
