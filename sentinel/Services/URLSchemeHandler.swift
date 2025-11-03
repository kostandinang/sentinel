//
//  URLSchemeHandler.swift
//  Sentinel
//
//  Parses and processes sentinel:// URL scheme hooks
//

import Foundation

struct HookData {
    let type: HookType
    let pid: Int
    let workingDirectory: String?
    let toolName: String?
    let agentType: AgentType?

    init?(from url: URL) {
        guard url.scheme == "sentinel",
              url.host == "hook",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }

        // Extract parameters from query items
        var params: [String: String] = [:]
        for item in queryItems {
            if let value = item.value {
                params[item.name] = value
            }
        }

        // Parse hook type
        guard let typeString = params["type"],
              let hookType = HookType(rawValue: typeString) else {
            return nil
        }
        self.type = hookType

        // Parse PID
        guard let pidString = params["pid"],
              let pidValue = Int(pidString) else {
            return nil
        }
        self.pid = pidValue

        // Parse optional parameters
        self.workingDirectory = params["pwd"]?.removingPercentEncoding
        self.toolName = params["tool"]?.removingPercentEncoding

        // Parse agent type (optional, defaults to Claude Code for backwards compatibility)
        if let agentString = params["agent"]?.removingPercentEncoding {
            self.agentType = AgentType(identifier: agentString)
        } else {
            // Default to Claude Code if not specified
            self.agentType = nil
        }
    }
}

class URLSchemeHandler {
    static let shared = URLSchemeHandler()

    private init() {}

    func handleURL(_ url: URL) -> HookData? {
        return HookData(from: url)
    }

    func validateURL(_ url: URL) -> Bool {
        return HookData(from: url) != nil
    }
}
