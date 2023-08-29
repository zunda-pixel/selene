// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GenEnvCode",
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
    .package(url: "https://github.com/apple/swift-algorithms", branch: "main"),
    .package(url: "https://github.com/apple/swift-syntax", exact: "508.0.1"),
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
