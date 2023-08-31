//
//  GenEnvCode.swift
//

import PackagePlugin
import Foundation

@main
struct GenerateCode: CommandPlugin {
  func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
    let tool = try context.tool(named: "Selene")
    let toolPath = URL(fileURLWithPath: tool.path.string)
    
    let process = try Process.run(
      toolPath,
      arguments: arguments
    )
    process.waitUntilExit()
  }
}

extension Array {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
