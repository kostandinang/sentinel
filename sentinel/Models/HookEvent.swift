//
//  HookEvent.swift
//  Sentinel
//
//  Represents individual hook events from agent sessions
//

import Foundation

enum HookType: String, Codable {
    // Legacy hooks (for backwards compatibility)
    case promptSubmit = "prompt-submit"
    case toolStart = "tool-start"
    case toolComplete = "tool-complete"
    case sessionStop = "session-stop"

    // Claude Code hooks
    case preToolUse = "pre-tool-use"
    case postToolUse = "post-tool-use"
    case userPromptSubmit = "user-prompt-submit"
    case notification = "notification"
    case stop = "stop"
    case subagentStop = "subagent-stop"
    case preCompact = "pre-compact"
    case sessionStart = "session-start"
    case sessionEnd = "session-end"

    var displayName: String {
        switch self {
        case .promptSubmit, .userPromptSubmit:
            return "Prompt Submitted"
        case .toolStart, .preToolUse:
            return "Tool Starting"
        case .toolComplete, .postToolUse:
            return "Tool Completed"
        case .sessionStop, .stop:
            return "Agent Stopped"
        case .notification:
            return "Notification"
        case .subagentStop:
            return "Subagent Stopped"
        case .preCompact:
            return "Compacting Context"
        case .sessionStart:
            return "Session Started"
        case .sessionEnd:
            return "Session Ended"
        }
    }

    var iconName: String {
        switch self {
        case .promptSubmit, .userPromptSubmit:
            return "text.bubble.fill"
        case .toolStart, .preToolUse:
            return "play.circle.fill"
        case .toolComplete, .postToolUse:
            return "checkmark.circle.fill"
        case .sessionStop, .stop:
            return "stop.circle.fill"
        case .notification:
            return "bell.fill"
        case .subagentStop:
            return "stop.fill"
        case .preCompact:
            return "arrow.down.circle.fill"
        case .sessionStart:
            return "play.fill"
        case .sessionEnd:
            return "xmark.circle.fill"
        }
    }
}

struct HookEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let type: HookType
    let details: String
    let toolName: String?
    let toolInput: String?
    let toolResponse: String?
    let prompt: String?

    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         type: HookType,
         details: String,
         toolName: String? = nil,
         toolInput: String? = nil,
         toolResponse: String? = nil,
         prompt: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.details = details
        self.toolName = toolName
        self.toolInput = toolInput
        self.toolResponse = toolResponse
        self.prompt = prompt
    }

    var displayText: String {
        switch type {
        case .promptSubmit, .userPromptSubmit:
            if let prompt = prompt, !prompt.isEmpty {
                return "Prompt: \(prompt.prefix(50))\(prompt.count > 50 ? "..." : "")"
            }
            return "Prompt submitted"
        case .toolStart, .preToolUse:
            return "Using \(toolName ?? "tool")"
        case .toolComplete, .postToolUse:
            return "Completed \(toolName ?? "tool")"
        case .sessionStop, .stop:
            return "Session stopped"
        case .notification:
            return "Notification: \(details)"
        case .subagentStop:
            return "Subagent stopped"
        case .preCompact:
            return "Compacting context"
        case .sessionStart:
            return "Session started"
        case .sessionEnd:
            return "Session ended"
        }
    }

    var hasDetailedInfo: Bool {
        toolInput != nil || toolResponse != nil || (prompt != nil && !prompt!.isEmpty)
    }
}
