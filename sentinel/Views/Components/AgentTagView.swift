//
//  AgentTagView.swift
//  Sentinel
//
//  Tag component for displaying agent types with monochrome outline style
//

import SwiftUI

/// Clean, monochrome tag component for agent types
struct AgentTagView: View {
    let agentType: AgentType
    let size: TagSize

    enum TagSize {
        case small, medium, large

        var fontSize: Font {
            switch self {
            case .small: return .system(size: 9, weight: .semibold, design: .monospaced)
            case .medium: return .system(size: 10, weight: .semibold, design: .monospaced)
            case .large: return .system(size: 11, weight: .semibold, design: .monospaced)
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 5, bottom: 2, trailing: 5)
            case .medium: return EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 6)
            case .large: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 5
            case .large: return 6
            }
        }

        var lineWidth: CGFloat {
            switch self {
            case .small: return 0.75
            case .medium: return 1.0
            case .large: return 1.25
            }
        }
    }

    init(agentType: AgentType, size: TagSize = .medium) {
        self.agentType = agentType
        self.size = size
    }

    var body: some View {
        Text(agentType.tagLabel)
            .font(size.fontSize)
            .foregroundColor(.primary)
            .padding(size.padding)
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .strokeBorder(Color.primary.opacity(0.3), lineWidth: size.lineWidth)
            )
    }
}

// Extension to get short tag labels for agent types
extension AgentType {
    var tagLabel: String {
        switch self {
        case .claudeCode: return "C"
        case .gemini: return "G"
        case .warp: return "W"
        }
    }

    var tagTooltip: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .gemini: return "Gemini"
        case .warp: return "Warp"
        }
    }
}
