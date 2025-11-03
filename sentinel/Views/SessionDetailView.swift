//
//  SessionDetailView.swift
//  Sentinel
//
//  Detailed view of a single session
//

import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var session: AgentSession
    @State private var showingGraph = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        // Status icon
                        Image(systemName: session.status.iconName)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(color(for: session.status))
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(color(for: session.status).opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(session.displayTitle)
                                    .font(.system(size: 18, weight: .semibold))

                                AgentTagView(agentType: session.agentType, size: .medium)
                            }

                            Text(session.status.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(color(for: session.status))
                        }

                        Spacer()

                        // Graph view button
                        Button(action: { showingGraph = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Timeline Graph")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.12))
                            )
                            .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(session.events.isEmpty)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Session info with copy actions
                GroupBox(label: Label("Session Info", systemImage: "info.circle.fill")) {
                    VStack(spacing: 14) {
                        InfoRow(label: "Working Directory", value: session.workingDirectory, copyable: true)
                        InfoRow(label: "Process ID", value: "\(session.pid)", copyable: true)
                        InfoRow(label: "Agent Type", value: session.agentType.displayName, copyable: false)
                        InfoRow(label: "Started", value: formatDate(session.startTime), copyable: false)
                        InfoRow(label: "Duration", value: session.durationFormatted, copyable: false)

                        if let currentTool = session.currentTool {
                            Divider()
                            HStack(spacing: 8) {
                                Image(systemName: "hammer.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                                Text("Currently using:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text(currentTool)
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.12))
                                    .cornerRadius(4)
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                }

                // Activity timeline
                GroupBox(label: Label("Activity Timeline (\(session.events.count))", systemImage: "clock.arrow.circlepath")) {
                    if session.events.isEmpty {
                        Text("No activity yet")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(session.events.reversed()) { event in
                                EventRowView(event: event)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingGraph) {
            SessionGraphView(session: session)
                .frame(minWidth: 1000, minHeight: 700)
        }
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var copyable: Bool = true
    @State private var showCopiedFeedback = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .leading)

            Text(value)
                .font(.system(size: 12, weight: .regular, design: label == "Process ID" ? .monospaced : .default))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .lineLimit(3)

            Spacer()

            if copyable {
                Button(action: copyToClipboard) {
                    Image(systemName: showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(showCopiedFeedback ? .green : .secondary)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(showCopiedFeedback ? "Copied!" : "Copy to clipboard")
            }
        }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)

        withAnimation(.easeInOut(duration: 0.2)) {
            showCopiedFeedback = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopiedFeedback = false
            }
        }
    }
}

struct EventRowView: View {
    let event: HookEvent
    @State private var isVisible = false
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Timeline indicator with connecting line
            ZStack {
                // Connecting line
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 2)

                // Event dot with scale animation and glow
                Circle()
                    .fill(color(for: event.type))
                    .frame(width: 11, height: 11)
                    .overlay(
                        Circle()
                            .strokeBorder(Color(NSColor.controlBackgroundColor), lineWidth: 2.5)
                    )
                    .shadow(color: isRecent ? color(for: event.type).opacity(0.5) : .clear, radius: 6)
                    .scaleEffect(isVisible ? 1.0 : 0.3)
            }
            .frame(width: 11)
            .padding(.trailing, 16)
            .padding(.top, 2)

            // Content card with improved hierarchy
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    // Icon with improved sizing
                    Image(systemName: event.type.iconName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(color(for: event.type))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(color(for: event.type).opacity(0.14))
                                .overlay(
                                    Circle()
                                        .strokeBorder(color(for: event.type).opacity(0.3), lineWidth: 0.5)
                                )
                        )

                    // Event details with better spacing
                    VStack(alignment: .leading, spacing: 6) {
                        // Title row with improved typography
                        HStack(spacing: 0) {
                            Text(eventTitle)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            if let toolName = event.toolName {
                                Text(" ")
                                ToolTagView(toolName: toolName, size: .small)
                            }
                        }

                        // Metadata row with better visual hierarchy
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 9, weight: .medium))
                                Text(formatTimestamp(event.timestamp))
                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                            }
                            .foregroundColor(.secondary)

                            if !isRecent {
                                Text("•")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary.opacity(0.5))

                                Text(timeAgo(from: event.timestamp))
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.75))
                            }
                        }

                        // Additional context for certain event types
                        if let contextText = eventContext {
                            Text(contextText)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.secondary.opacity(0.9))
                                .lineLimit(2)
                                .padding(.top, 2)
                        }
                    }

                    Spacer()

                    // Recent indicator badge
                    if isRecent {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(color(for: event.type))
                                .frame(width: 6, height: 6)

                            Text("Live")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(color(for: event.type))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(color(for: event.type).opacity(0.12))
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? .ultraThinMaterial : .thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                color(for: event.type).opacity(isRecent ? 0.3 : (isHovered ? 0.15 : 0.06)),
                                lineWidth: isRecent ? 1.2 : (isHovered ? 0.8 : 0.5)
                            )
                    )
                    .shadow(
                        color: isRecent ? color(for: event.type).opacity(0.15) : .clear,
                        radius: 8,
                        y: 2
                    )
            )
            .opacity(isVisible ? 1.0 : 0)
            .offset(x: isVisible ? 0 : 20)
            .scaleEffect(isVisible ? 1.0 : 0.95)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .padding(.vertical, 5)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.03)) {
                isVisible = true
            }
        }
    }

    private var eventTitle: String {
        switch event.type {
        case .promptSubmit:
            return "Prompt submitted"
        case .toolStart:
            return event.toolName != nil ? "Started" : "Tool started"
        case .toolComplete:
            return event.toolName != nil ? "Completed" : "Tool completed"
        case .sessionStop:
            return "Session ended"
        }
    }

    private var eventContext: String? {
        // Add contextual information based on event type
        switch event.type {
        case .promptSubmit:
            return "Agent is processing your request"
        case .toolStart:
            return nil // Tool name is already displayed in tag
        case .toolComplete:
            return "Task finished successfully"
        case .sessionStop:
            return "All activities concluded"
        }
    }

    private var isRecent: Bool {
        Date().timeIntervalSince(event.timestamp) < 15
    }

    private func color(for type: HookType) -> Color {
        switch type {
        case .promptSubmit:
            return Color(red: 0.0, green: 0.48, blue: 1.0) // Blue
        case .toolStart:
            return Color(red: 1.0, green: 0.58, blue: 0.0) // Orange
        case .toolComplete:
            return Color(red: 0.2, green: 0.78, blue: 0.35) // Green
        case .sessionStop:
            return Color(red: 0.56, green: 0.56, blue: 0.58) // Gray
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// Empty state view
struct EmptySessionDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(.blue.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text("No Session Selected")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Choose a session from the sidebar to view its details")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    QuickTipItem(
                        icon: "command",
                        text: "⌘ + O to open Sentinel"
                    )

                    QuickTipItem(
                        icon: "magnifyingglass",
                        text: "Search to filter sessions"
                    )
                }

                HStack(spacing: 16) {
                    QuickTipItem(
                        icon: "hand.point.up.left",
                        text: "Right-click for quick actions"
                    )

                    QuickTipItem(
                        icon: "doc.on.doc",
                        text: "Click to copy values"
                    )
                }
            }
            .padding(.top, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
}

struct QuickTipItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                )

            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}
