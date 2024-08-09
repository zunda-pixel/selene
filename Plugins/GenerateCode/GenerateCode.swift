//
//  GenEnvCode.swift
//

import PackagePlugin
import Foundation

@main
struct GenerateCode: CommandPlugin {
  func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
    let tool = try context.tool(named: "Selene")

    let process = try Process.run(
      tool.url,
      arguments: arguments
    )
    process.waitUntilExit()
  }
}
