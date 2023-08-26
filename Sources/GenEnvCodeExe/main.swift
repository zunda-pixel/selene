import Foundation
import os
import Algorithms

let envFilePathString = CommandLine.arguments[1]
let exportFilePathString = CommandLine.arguments[2]

let envFilePath = URL(fileURLWithPath: envFilePathString, isDirectory: false)
let exportFilePath = URL(fileURLWithPath: exportFilePathString, isDirectory: false)

let envFileContent = try String(contentsOf: envFilePath)

let lines = envFileContent.split(whereSeparator: \.isNewline)

var envValues: [String: String] = [:]

for line in lines {
  let values = line.split(separator: "=")
  let key = String(values[0])
  let value = String(values[1])
  envValues[key] = value
}

let cipher: [UInt8] = (0..<64).map { _ in
  UInt8.random(in: UInt8.min...UInt8.max)
}

let uint8Properties = envValues.map {
  let data = $0.value.data(using: .utf8)!
  let encodedData = encodeData(Array(data), cipher: cipher)
  let value = string(data: encodedData)
  return """
  static private let _\($0.key): [UInt8] = [
  \(value)
  ]
"""
}

let properties = envValues.map {
  return """
  static public var \($0.key): String {
    string(data: _\($0.key), cipher: cipher)
  }
"""
}

let file = """
import Foundation
import Algorithms

public enum Env {
  static private let cipher: [UInt8] = [
\(string(data: cipher))
  ]

\(uint8Properties.joined(separator: "\n\n"))

\(properties.joined(separator: "\n\n"))

  static private func string(data: [UInt8], cipher: [UInt8]) -> String {
    String(
      decoding: encodeData(data: data, cipher: cipher),
      as: UTF8.self
    )
  }

  static private func encodeData(data: [UInt8], cipher: [UInt8]) -> [UInt8] {
    data.indexed().map { offset, element in
      element ^ cipher[offset % cipher.count]
    }
  }
}
"""

let fileData = file.data(using: .utf8)!

try fileData.write(to: exportFilePath)

func encodeData(_ data: [UInt8], cipher: [UInt8]) -> [UInt8] {
  data.enumerated().map { offset, element in
    element ^ cipher[offset % cipher.count]
  }
}

func string(data: [UInt8]) -> String {
  let chunkCipher = data.chunks(ofCount: 8)
  
  let lines = chunkCipher.map { chunk in
    let values = chunk.map { String(format: "0x%x", $0) }
    return values.joined(separator: ", ")
  }
  
  return lines.joined(separator: ",\n")
}
