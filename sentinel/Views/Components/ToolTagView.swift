//
//  ToolTagView.swift
//  Sentinel
//
//  Displays a tool name tag with appropriate styling
//

import SwiftUI

enum ToolTagSize {
    case small
    case medium

    var fontSize: CGFloat {
        switch self {
        case .small: return 11
        case .medium: return 12
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 4
        }
    }
}

struct ToolTagView: View {
    let toolName: String
    var size: ToolTagSize = .medium

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: toolIcon)
                .font(.system(size: size.fontSize - 1, weight: .medium))

            Text(toolName)
                .font(.system(size: size.fontSize, weight: .semibold, design: .rounded))
        }
        .foregroundColor(toolColor)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            Capsule()
                .fill(toolColor.opacity(0.12))
        )
        .overlay(
            Capsule()
                .strokeBorder(toolColor.opacity(0.25), lineWidth: 0.5)
        )
    }

    private var toolIcon: String {
        let lower = toolName.lowercased()

        // Common tool categorization
        if lower.contains("bash") || lower.contains("shell") {
            return "terminal.fill"
        } else if lower.contains("read") || lower.contains("file") {
            return "doc.text.fill"
        } else if lower.contains("write") || lower.contains("edit") {
            return "pencil.line"
        } else if lower.contains("grep") || lower.contains("search") {
            return "magnifyingglass"
        } else if lower.contains("git") {
            return "arrow.triangle.branch"
        } else if lower.contains("web") || lower.contains("fetch") {
            return "network"
        } else {
            return "wrench.fill"
        }
    }

    private var toolColor: Color {
        let lower = toolName.lowercased()

        // Semantic coloring based on tool type
        if lower.contains("bash") || lower.contains("shell") {
            return Color(red: 0.4, green: 0.4, blue: 0.95) // Purple-blue
        } else if lower.contains("read") {
            return Color(red: 0.0, green: 0.55, blue: 0.88) // Blue
        } else if lower.contains("write") || lower.contains("edit") {
            return Color(red: 1.0, green: 0.45, blue: 0.0) // Orange
        } else if lower.contains("grep") || lower.contains("search") {
            return Color(red: 0.95, green: 0.65, blue: 0.0) // Yellow-orange
        } else if lower.contains("git") {
            return Color(red: 0.9, green: 0.3, blue: 0.25) // Git red
        } else if lower.contains("web") || lower.contains("fetch") {
            return Color(red: 0.35, green: 0.65, blue: 0.95) // Sky blue
        } else {
            return Color(red: 0.56, green: 0.56, blue: 0.58) // Gray
        }
    }
}
