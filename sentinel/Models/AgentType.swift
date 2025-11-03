//
//  AgentType.swift
//  Sentinel
//
//  Defines supported AI agent types for monitoring
//

import Foundation

enum AgentType: String, Codable, CaseIterable {
    case claudeCode = "Claude Code"
    case warp = "Warp"
    case gemini = "Gemini"
    case githubCopilot = "GitHub Copilot"

    var displayName: String {
        self.rawValue
    }

    var iconName: String {
        switch self {
        case .claudeCode:
            return "terminal.fill"
        case .warp:
            return "bolt.fill"
        case .gemini:
            return "sparkles"
        case .githubCopilot:
            return "chevron.left.forwardslash.chevron.right"
        }
    }

    /// Initialize from agent identifier string (case-insensitive)
    init?(identifier: String) {
        let lowercased = identifier.lowercased()
        switch lowercased {
        case "claude", "claude-code", "claudecode":
            self = .claudeCode
        case "warp", "warp.dev", "warpdev":
            self = .warp
        case "gemini", "gemini-cli", "geminicli":
            self = .gemini
        case "copilot", "github-copilot", "githubcopilot", "github copilot":
            self = .githubCopilot
        default:
            return nil
        }
    }
}
