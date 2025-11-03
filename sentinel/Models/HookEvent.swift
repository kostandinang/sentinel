//
//  HookEvent.swift
//  Sentinel
//
//  Represents individual hook events from agent sessions
//

import Foundation

enum HookType: String, Codable {
    case promptSubmit = "prompt-submit"
    case toolStart = "tool-start"
    case toolComplete = "tool-complete"
    case sessionStop = "session-stop"

    var displayName: String {
        switch self {
        case .promptSubmit:
            return "Prompt Submitted"
        case .toolStart:
            return "Tool Started"
        case .toolComplete:
            return "Tool Completed"
        case .sessionStop:
            return "Session Stopped"
        }
    }

    var iconName: String {
        switch self {
        case .promptSubmit:
            return "text.bubble.fill"
        case .toolStart:
            return "gearshape.fill"
        case .toolComplete:
            return "checkmark.circle.fill"
        case .sessionStop:
            return "stop.circle.fill"
        }
    }
}

struct HookEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let type: HookType
    let details: String
    let toolName: String?

    init(id: UUID = UUID(), timestamp: Date = Date(), type: HookType, details: String, toolName: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.details = details
        self.toolName = toolName
    }

    var displayText: String {
        switch type {
        case .promptSubmit:
            return "Prompt submitted"
        case .toolStart:
            return "Using \(toolName ?? "tool")"
        case .toolComplete:
            return "Completed \(toolName ?? "tool")"
        case .sessionStop:
            return "Session stopped"
        }
    }
}
