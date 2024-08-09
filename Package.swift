// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Selene",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13),
  ],
  products: [
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
    .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"601.0.0-prerelease"),
    .package(url: "https://github.com/swiftlang/swift-testing", from: "0.11.0"),
  ],
  targets: [
    .plugin(
      name: "GenerateCode",
      capability: .command(
        intent: .custom(
          verb: "generate-env-code",
          description: "Generate Source Code from Env File"
        )
      ),
      dependencies: [
        .target(name: "Selene")
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
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "Testing", package: "swift-testing"),
      ]
    ),
  ]
)
