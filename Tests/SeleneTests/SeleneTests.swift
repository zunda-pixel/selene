import XCTest
@testable import Selene
import SwiftParser
import SwiftSyntax

final class SeleneTests: XCTestCase {
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
#comment
key2=value2
key3=value3=value3
"""
    
    let values: [String: String] = environmentValues(content: content)
  
    XCTAssertEqual(
      values,
      [
        "key1": "value1",
        "key2": "value2",
        "key3": "value3=value3",
      ]
    )
  }
  
  func assertSyntax(syntax: some SyntaxProtocol, source: String) {
    XCTAssertEqual(
      Parser.parse(source: syntax.formatted().description).formatted().description,
      Parser.parse(source: source).formatted().description
    )
  }
  
  func testArrayExpr() {
    let arrayExprSyntax = arrayExpr(elements: [0x1, 0x2, 0x3, 0x4])
    
    assertSyntax(
      syntax: arrayExprSyntax,
      source: "[0x1, 0x2, 0x3, 0x4]"
    )
  }
  
  func testPrivateKeyVariableKey() {
    let variable = privateKeyVariableKey(key: "key", value: "value", cipher: [0x01, 0x02])
    
    assertSyntax(
      syntax: variable,
      source: "static private let _key: [UInt8] = [0x77, 0x63, 0x6d, 0x77, 0x64]"
    )
  }
  
  func testPublicKeyVariableKey() {
    let variable = publicKeyVariableKey(key: "testKey")
    
    assertSyntax(
      syntax: variable,
      source: """
static public var testKey: String {
    string(data: _testKey, cipher: cipher)
}
"""
    )
  }
  
  func testCipherVariable() {
    let variable = cipherVariable(cipher: [0x1, 0x2, 0x3, 0x4])
    assertSyntax(
      syntax: variable,
      source: "static private let cipher: [UInt8] = [0x1, 0x2, 0x3, 0x4]"
    )
  }
  
  func testEncodeDataFunction() {
    assertSyntax(
      syntax: encodeDataFunction(),
      source: """
static private func encodeData(data: [UInt8], cipher: [UInt8]) -> [UInt8] {
    data.indexed().map { offset, element in
        return element ^ cipher[offset % cipher.count]
    }
}
"""
    )
  }
  
  func testSourceFunction() {
    let source = source(
      namespace: "SecretEnv",
      cipher: [],
      envValues: [:]
    )
    
    assertSyntax(
      syntax: source,
      source: """
import Algorithms
import Foundation
public enum SecretEnv {
    static private let cipher: [UInt8] = []
    static private func string(data: [UInt8], cipher: [UInt8]) -> String {
        String.init(decoding: encodeData(data: data, cipher: cipher), as: UTF8.self)
    }
    static private func encodeData(data: [UInt8], cipher: [UInt8]) -> [UInt8] {
        data.indexed().map { offset, element in
            return element ^ cipher[offset % cipher.count]
        }
    }
}
"""
    )
  }
}
