//
//  SessionDetailView.swift
//  Sentinel
//
//  Detailed view of a single session
//

import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var session: AgentSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: session.status.iconName)
                            .font(.title)
                            .foregroundColor(color(for: session.status))

                        Text(session.displayTitle)
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()
                    }

                    Text(session.status.rawValue)
                        .font(.subheadline)
                        .foregroundColor(color(for: session.status))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color(for: session.status).opacity(0.1))
                        .cornerRadius(4)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Session info
                GroupBox(label: Label("Session Info", systemImage: "info.circle")) {
                    VStack(spacing: 12) {
                        InfoRow(label: "Working Directory", value: session.workingDirectory)
                        InfoRow(label: "Process ID", value: "\(session.pid)")
                        InfoRow(label: "Agent Type", value: session.agentType.displayName)
                        InfoRow(label: "Started", value: formatDate(session.startTime))
                        InfoRow(label: "Duration", value: session.durationFormatted)

                        if let currentTool = session.currentTool {
                            InfoRow(label: "Current Tool", value: currentTool)
                        }
                    }
                    .padding(.vertical, 8)
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

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .leading)

            Text(value)
                .fontWeight(.medium)
                .textSelection(.enabled)

            Spacer()
        }
    }
}

struct EventRowView: View {
    let event: HookEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: event.type.iconName)
                .foregroundColor(color(for: event.type))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.displayText)
                    .font(.body)

                Text(formatTimestamp(event.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func color(for type: HookType) -> Color {
        switch type {
        case .promptSubmit: return .blue
        case .toolStart: return .orange
        case .toolComplete: return .green
        case .sessionStop: return .gray
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// Empty state view
struct EmptySessionDetailView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("No Session Selected")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Select a session from the list to view details")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
