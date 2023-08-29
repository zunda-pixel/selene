//
//  GenEnvCode.swift
//

import PackagePlugin
import Foundation
import os

@main
struct GenEnvCode: CommandPlugin {
  func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
    let tool = try context.tool(named: "GenEnvCodeExe")
    let toolPath = URL(fileURLWithPath: tool.path.string)
    
    guard let namespace = arguments[safe: 0] else {
      throw GenerateEnvironmentCodeError.noNameSpaceArgument
    }

    guard let envFilePath = arguments[safe: 1] else {
      throw GenerateEnvironmentCodeError.noEnvironmentFilePathArgument
    }
    
    guard let exportFilePath = arguments[safe: 2] else {
      throw GenerateEnvironmentCodeError.noExportFilePathArgument
    }
    
    let process = try Process.run(
      toolPath,
      arguments: [
        namespace,
        envFilePath,
        exportFilePath,
      ]
    )
    process.waitUntilExit()
  }
}

extension Array {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

enum GenerateEnvironmentCodeError: Error {
  case noNameSpaceArgument
  case noEnvironmentFilePathArgument
  case noExportFilePathArgument
}
