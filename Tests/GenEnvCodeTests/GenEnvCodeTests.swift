import XCTest
@testable import GenEnvCodeExe

final class GenEnvCodeTests: XCTestCase {
  func testEncodeAndDecode() throws {
    let cipher: [UInt8] = (0..<64).map { _ in UInt8.random(in: UInt8.min..<UInt8.max) }
    let input = "Hello"
    let inputData = input.data(using: .utf8)!
    let encodedData = encodeData(Array(inputData), cipher: cipher)
    let decodedData = encodeData(encodedData, cipher: cipher)
    let output = String(decoding: decodedData, as: UTF8.self)
    XCTAssertEqual(input, output)
  }
}
