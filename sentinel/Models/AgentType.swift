//
//  AgentType.swift
//  Sentinel
//
//  Defines supported AI agent types for monitoring
//

import Foundation

enum AgentType: String, Codable, CaseIterable {
    case claudeCode = "Claude Code"

    var displayName: String {
        self.rawValue
    }

    var iconName: String {
        switch self {
        case .claudeCode:
            return "terminal.fill"
        }
    }
}
