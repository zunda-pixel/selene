import XCTest
@testable import GenEnvCodeExe

final class GenEnvCodeTests: XCTestCase {
  func testEncodeAndDecode() {
    let cipher: [UInt8] = generateCipher(count: 64)
    let input = "Hello"
    let inputData = Data(input.utf8)
    let encodedData = encodeData(Array(inputData), cipher: cipher)
    let decodedData = encodeData(encodedData, cipher: cipher)
    let output = String(decoding: decodedData, as: UTF8.self)
    XCTAssertEqual(input, output)
  }
  
  func testSpecifyCipher() {
    let cipher: [UInt8] = [
      0xce, 0xc, 0xbc, 0xf3, 0x31, 0x69, 0xf5, 0x6c, 0x92,
      0x73, 0x47, 0x41, 0x55, 0xf9, 0xb6, 0x86, 0x79, 0xaa,
      0xe3, 0x9e, 0xc6, 0, 0x4c, 0x29, 0x6, 0x38, 0xdc, 0x68,
      0x85, 0, 0xeb, 0x39, 0xfa, 0xad, 0x67, 0x66, 0x42, 0xb7,
      0xab, 0x71, 0x45, 0x20, 0xa7, 0x98, 0x7d, 0xd6, 0x36, 0x9b,
      0xd2, 0x73, 0x3a, 0xac, 0xd8, 0xc5, 0xf4, 0xe1, 0x58, 0xb2,
      0x64, 0x46, 0x20, 0x2b, 0xa8, 0xeb
    ]

    let encoded: [UInt8] = [
      0x85, 0x38, 0x8f, 0xc1, 0x55, 0x1f, 0xb3, 0x19, 0xf3,
      0x1a, 0x1f, 0x5, 0x37, 0xcc, 0xd4, 0xff, 0x13, 0xd2, 0x89, 0xfa
    ]
    
    let decodedData = encodeData(encoded, cipher: cipher)
    let output = String(decoding: decodedData, as: UTF8.self)
    XCTAssertEqual("K432dvFuaiXDb5byjxjd", output)
  }
  
  func testEnvironmentValues() {
    let content = """
key1=value1
key2=value2
"""
    
    let values: [String: String] = environmentValues(content: content)
  
    XCTAssertEqual(values, ["key1": "value1", "key2": "value2"])
  }
  
  func testArrayExpr() {
    let exprSyntax = arrayExpr(elements: [0x01, 0x02, 0x03, 0x04])
    
    XCTAssertEqual(exprSyntax.formatted().description, "[0x1, 0x2, 0x3, 0x4]")
  }
  
  func testPublicKeyVariableKey() {
    let variable = publicKeyVariableKey(key: "testKey")
    
    XCTAssertEqual(
      variable.formatted().description,
"""
static public var testKey: String {
    string(data: _testKey, cipher: cipher)
}
"""
    )
  }
  
  func testCipherVariable() {
    let variable = cipherVariable(cipher: [0x01, 0x02, 0x03, 0x04])
    XCTAssertEqual(
      variable.formatted().description,
      "static private let cipher: [UInt8] = [0x1, 0x2, 0x3, 0x4]"
    )
  }
}
