//
//  SessionGraphNode.swift
//  Sentinel
//
//  Graph node representation for session timeline visualization
//

import Foundation
import SwiftUI

/// Represents a node in the session activity graph
struct SessionGraphNode: Identifiable, Hashable {
    let id: UUID
    let event: HookEvent
    let position: CGPoint
    let narrative: String

    /// Connections to subsequent nodes
    var nextNodes: [UUID]

    init(event: HookEvent, position: CGPoint = .zero, narrative: String = "") {
        self.id = event.id
        self.event = event
        self.position = position
        self.narrative = narrative
        self.nextNodes = []
    }

    /// Visual representation properties
    var nodeColor: Color {
        switch event.type {
        case .promptSubmit, .userPromptSubmit:
            return Color(red: 0.0, green: 0.48, blue: 1.0) // macOS Blue
        case .toolStart, .preToolUse:
            return Color(red: 1.0, green: 0.58, blue: 0.0) // macOS Orange
        case .toolComplete, .postToolUse:
            return Color(red: 0.2, green: 0.78, blue: 0.35) // macOS Green
        case .sessionStop, .stop, .sessionEnd:
            return Color(red: 0.56, green: 0.56, blue: 0.58) // macOS Gray
        case .notification:
            return Color(red: 1.0, green: 0.78, blue: 0.0) // Yellow
        case .subagentStop:
            return Color(red: 0.56, green: 0.56, blue: 0.58) // Gray
        case .preCompact:
            return Color(red: 0.68, green: 0.32, blue: 0.87) // Purple
        case .sessionStart:
            return Color(red: 0.2, green: 0.78, blue: 0.35) // Green
        }
    }

    var nodeSize: CGFloat {
        switch event.type {
        case .promptSubmit, .userPromptSubmit:
            return 50
        case .toolStart, .preToolUse:
            return 45
        case .toolComplete, .postToolUse:
            return 40
        case .sessionStop, .stop, .sessionEnd:
            return 55
        case .notification:
            return 35
        case .subagentStop:
            return 40
        case .preCompact:
            return 42
        case .sessionStart:
            return 48
        }
    }

    var glowRadius: CGFloat {
        switch event.type {
        case .promptSubmit, .userPromptSubmit:
            return 15
        case .toolStart, .preToolUse:
            return 20
        case .toolComplete, .postToolUse:
            return 10
        case .sessionStop, .stop, .sessionEnd:
            return 12
        case .notification:
            return 8
        case .subagentStop:
            return 10
        case .preCompact:
            return 14
        case .sessionStart:
            return 16
        }
    }

    static func == (lhs: SessionGraphNode, rhs: SessionGraphNode) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Represents an edge connecting two nodes
struct SessionGraphEdge: Identifiable, Hashable {
    let id: UUID
    let from: UUID
    let to: UUID
    let strength: Double // 0.0 to 1.0

    init(from: UUID, to: UUID, strength: Double = 1.0) {
        self.id = UUID()
        self.from = from
        self.to = to
        self.strength = strength
    }

    var strokeWidth: CGFloat {
        CGFloat(2 + strength * 3)
    }

    var opacity: Double {
        0.3 + strength * 0.5
    }

    static func == (lhs: SessionGraphEdge, rhs: SessionGraphEdge) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Builds a graph representation from session events
class SessionGraphBuilder {

    /// Generate narrative text for an event based on context
    static func generateNarrative(for event: HookEvent, index: Int, total: Int) -> String {
        switch event.type {
        case .promptSubmit, .userPromptSubmit:
            if index == 0 {
                return "The journey begins with your first prompt..."
            } else {
                return "You continued the conversation with a new prompt"
            }

        case .toolStart, .preToolUse:
            if let tool = event.toolName {
                return "Claude is using \(tool) to help accomplish your task"
            }
            return "Claude started using a tool"

        case .toolComplete, .postToolUse:
            if let tool = event.toolName {
                return "Successfully completed \(tool) operation"
            }
            return "Tool operation completed"

        case .sessionStop, .stop, .sessionEnd:
            return "Session concluded after \(total) events"

        case .notification:
            return "Claude sent a notification"

        case .subagentStop:
            return "Subagent task completed"

        case .preCompact:
            return "Context is being optimized"

        case .sessionStart:
            return "Session initialized and ready"
        }
    }

    /// Build a graph from session events with automatic layout
    static func buildGraph(from events: [HookEvent], containerSize: CGSize) -> (nodes: [SessionGraphNode], edges: [SessionGraphEdge]) {
        guard !events.isEmpty else { return ([], []) }

        var nodes: [SessionGraphNode] = []
        var edges: [SessionGraphEdge] = []

        // Layout configuration
        let padding: CGFloat = 80

        // Create nodes with positions
        for (index, event) in events.enumerated() {
            let narrative = generateNarrative(for: event, index: index, total: events.count)

            // Layout in a flowing timeline pattern
            let position = calculateNodePosition(
                index: index,
                total: events.count,
                containerSize: containerSize,
                padding: padding
            )

            let node = SessionGraphNode(
                event: event,
                position: position,
                narrative: narrative
            )

            nodes.append(node)

            // Create edge to previous node
            if index > 0 {
                let previousNode = nodes[index - 1]

                // Calculate edge strength based on time proximity
                let timeDiff = event.timestamp.timeIntervalSince(previousNode.event.timestamp)
                let strength = min(1.0, max(0.3, 1.0 - timeDiff / 60.0)) // Weaker if > 1 min apart

                let edge = SessionGraphEdge(
                    from: previousNode.id,
                    to: node.id,
                    strength: strength
                )
                edges.append(edge)

                // Update node connections
                nodes[index - 1].nextNodes.append(node.id)
            }
        }

        return (nodes, edges)
    }

    /// Calculate node position in a flowing, organic timeline layout
    private static func calculateNodePosition(
        index: Int,
        total: Int,
        containerSize: CGSize,
        padding: CGFloat
    ) -> CGPoint {
        let usableWidth = containerSize.width - padding * 2
        let usableHeight = containerSize.height - padding * 2

        // Create a flowing S-curve timeline
        let progress = CGFloat(index) / CGFloat(max(1, total - 1))

        // Horizontal position follows the timeline
        let x = padding + usableWidth * progress

        // Vertical position creates a gentle wave
        let wave = sin(progress * .pi * 2) * (usableHeight * 0.25)
        let y = containerSize.height / 2 + wave

        return CGPoint(x: x, y: y)
    }
}
