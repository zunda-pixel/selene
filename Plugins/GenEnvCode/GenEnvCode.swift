//
//  GenEnvCode.swift
//

import PackagePlugin
import Foundation

@main
struct GenEnvCode: CommandPlugin {
  func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
    let tool = try context.tool(named: "GenEnvCodeExe")
    let toolPath = URL(fileURLWithPath: tool.path.string)
    
    guard let namespace = arguments[safe: 0] else {
      throw ArgumentError.noNameSpaceArgument
    }

    guard let envFilePath = arguments[safe: 1] else {
      throw ArgumentError.noEnvironmentFilePathArgument
    }
    
    guard let outputFilePath = arguments[safe: 2] else {
      throw ArgumentError.noOutputFilePathArgument
    }
    
    let process = try Process.run(
      toolPath,
      arguments: [
        namespace,
        envFilePath,
        outputFilePath,
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

enum ArgumentError: Error, LocalizedError {
  case noNameSpaceArgument
  case noEnvironmentFilePathArgument
  case noOutputFilePathArgument
  
  var helpAnchor: String {
    switch self {
    case .noNameSpaceArgument: "Generating Namespace(ex: SecureEnv)."
    case .noEnvironmentFilePathArgument: "Env file path."
    case .noOutputFilePathArgument: "Output file path."
    }
  }
}
