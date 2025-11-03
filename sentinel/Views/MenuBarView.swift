//
//  MenuBarView.swift
//  Sentinel
//
//  Menu bar extra view and popover content
//

import SwiftUI

struct MenuBarView: View {
    @StateObject private var viewModel = MenuBarViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    let onOpenMainWindow: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header - clean and minimal
            HStack(spacing: 8) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Sentinel")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Quick status
            if sessionManager.activeSessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No Active Sessions")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    Text("Start an agent to begin monitoring")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(sessionManager.activeSessions.prefix(5)) { session in
                            SessionQuickRowView(session: session)
                        }

                        if sessionManager.activeSessions.count > 5 {
                            Button(action: onOpenMainWindow) {
                                HStack(spacing: 6) {
                                    Image(systemName: "ellipsis.circle.fill")
                                        .font(.caption)
                                    Text("View \(sessionManager.activeSessions.count - 5) more sessions")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                }
                .frame(maxHeight: 320)
            }

            Divider()

            // Footer actions with keyboard hints
            HStack(spacing: 10) {
                Button(action: onOpenMainWindow) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 11))
                        Text("Open Sentinel")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("o", modifiers: [.command])

                Spacer()

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Text("Quit")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("q", modifiers: [.command])
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 340)
    }
}

struct SessionQuickRowView: View {
    @ObservedObject var session: AgentSession
    @State private var isExpanded = false
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            // Session summary
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    // Status indicator with pulse animation
                    ZStack {
                        if session.status == .usingTool {
                            Circle()
                                .fill(color(for: session.status).opacity(0.3))
                                .frame(width: 22, height: 22)
                                .scaleEffect(isExpanded ? 1.0 : 1.2)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isExpanded)
                        }

                        Image(systemName: session.status.iconName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(color(for: session.status))
                            .frame(width: 22, height: 22)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(session.displayTitle)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)

                            AgentTagView(agentType: session.agentType, size: .small)
                        }

                        HStack(spacing: 6) {
                            // Status text
                            Text(session.status.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(color(for: session.status))

                            if let lastActivity = session.lastActivity {
                                Text("•")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text(lastActivity.displayText)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer(minLength: 8)

                    Text(session.durationFormatted)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)

                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.system(size: 14))
                        .foregroundColor(isExpanded ? .blue : .secondary.opacity(0.5))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isExpanded ? Color.blue.opacity(0.12) : (isHovered ? Color.secondary.opacity(0.05) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        isExpanded ? Color.blue.opacity(0.3) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }

            // Expanded stats view
            if isExpanded {
                SessionStatsView(session: session)
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
                    .padding(.bottom, 8)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .padding(.horizontal, 4)
    }

    private func color(for status: SessionStatus) -> Color {
        switch status {
        case .idle: return .gray
        case .active: return .blue
        case .usingTool: return .orange
        case .error: return .red
        case .stopped: return .gray
        }
    }
}

// Agent type tag component
struct AgentTypeTag: View {
    let agentType: AgentType

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: agentType.iconName)
                .font(.system(size: 8))
            Text(tagText)
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(tagColor)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(tagColor.opacity(0.15))
        .cornerRadius(3)
    }

    private var tagText: String {
        switch agentType {
        case .claudeCode: return "Claude"
        case .gemini: return "Gemini"
        case .warp: return "Warp"
        case .githubCopilot: return "Copilot"
        }
    }

    private var tagColor: Color {
        switch agentType {
        case .claudeCode: return .blue
        case .gemini: return .purple
        case .warp: return .green
        case .githubCopilot: return .orange
        }
    }
}

// Compact stats view for expanded state
struct SessionStatsView: View {
    @ObservedObject var session: AgentSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Stats grid
            HStack(spacing: 16) {
                StatItem(
                    icon: "clock.arrow.circlepath",
                    label: "Events",
                    value: "\(session.events.count)"
                )

                StatItem(
                    icon: "hammer.fill",
                    label: "Tools",
                    value: "\(toolUseCount)"
                )

                StatItem(
                    icon: "checkmark.circle.fill",
                    label: "Completed",
                    value: "\(completedToolCount)"
                )
            }

            if let currentTool = session.currentTool {
                Divider()
                HStack(spacing: 6) {
                    Image(systemName: "gear")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("Current: \(currentTool)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(6)
    }

    private var toolUseCount: Int {
        session.events.filter { $0.type == .toolStart }.count
    }

    private var completedToolCount: Int {
        session.events.filter { $0.type == .toolComplete }.count
    }
}

// Individual stat item
struct StatItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
