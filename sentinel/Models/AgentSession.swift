//
//  AgentSession.swift
//  Sentinel
//
//  Core data model for tracking agent sessions
//

import Foundation
import Combine

enum SessionStatus: String, Codable {
    case idle = "Idle"
    case active = "Active"
    case usingTool = "Using Tool"
    case stopped = "Stopped"
    case error = "Error"

    var iconName: String {
        switch self {
        case .idle:
            return "shield"
        case .active:
            return "shield.fill"
        case .usingTool:
            return "shield.lefthalf.filled"
        case .stopped:
            return "shield.slash"
        case .error:
            return "exclamationmark.shield"
        }
    }

    var colorName: String {
        switch self {
        case .idle:
            return "gray"
        case .active:
            return "blue"
        case .usingTool:
            return "orange"
        case .stopped:
            return "gray"
        case .error:
            return "red"
        }
    }
}

class AgentSession: Identifiable, Codable, ObservableObject, Hashable {
    let id: UUID
    let pid: Int
    let agentType: AgentType
    let workingDirectory: String
    let startTime: Date

    @Published var status: SessionStatus
    @Published var currentTool: String?
    @Published var events: [HookEvent]

    // Computed properties
    var displayTitle: String {
        let url = URL(fileURLWithPath: workingDirectory)
        return url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
    }

    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    var durationFormatted: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: duration) ?? "0s"
    }

    var lastActivity: HookEvent? {
        events.last
    }

    var isActive: Bool {
        status != .stopped && status != .error
    }

    // Codable conformance with @Published properties
    enum CodingKeys: String, CodingKey {
        case id, pid, agentType, workingDirectory, startTime, status, currentTool, events
    }

    init(id: UUID = UUID(), pid: Int, agentType: AgentType, workingDirectory: String, startTime: Date = Date()) {
        self.id = id
        self.pid = pid
        self.agentType = agentType
        self.workingDirectory = workingDirectory
        self.startTime = startTime
        self.status = .idle
        self.currentTool = nil
        self.events = []
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        pid = try container.decode(Int.self, forKey: .pid)
        agentType = try container.decode(AgentType.self, forKey: .agentType)
        workingDirectory = try container.decode(String.self, forKey: .workingDirectory)
        startTime = try container.decode(Date.self, forKey: .startTime)
        status = try container.decode(SessionStatus.self, forKey: .status)
        currentTool = try container.decodeIfPresent(String.self, forKey: .currentTool)
        events = try container.decode([HookEvent].self, forKey: .events)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(pid, forKey: .pid)
        try container.encode(agentType, forKey: .agentType)
        try container.encode(workingDirectory, forKey: .workingDirectory)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(currentTool, forKey: .currentTool)
        try container.encode(events, forKey: .events)
    }

    func addEvent(_ event: HookEvent) {
        events.append(event)

        // Update status based on event type
        switch event.type {
        case .promptSubmit, .userPromptSubmit:
            status = .active
        case .toolStart, .preToolUse:
            status = .usingTool
            currentTool = event.toolName
        case .toolComplete, .postToolUse:
            status = .active
            currentTool = nil
        case .sessionStop, .stop, .sessionEnd:
            status = .stopped
            currentTool = nil
        case .notification, .preCompact:
            // Don't change status for these events
            break
        case .subagentStop:
            // Return to active status after subagent completes
            status = .active
        case .sessionStart:
            status = .active
        }
    }

    // Hashable conformance
    static func == (lhs: AgentSession, rhs: AgentSession) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
