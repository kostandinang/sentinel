//
//  SessionListView.swift
//  Sentinel
//
//  Main window session list view
//

import SwiftUI

struct SessionListView: View {
    @ObservedObject var sessionManager: SessionManager
    @Binding var selectedSession: AgentSession?
    @State private var showActiveOnly = false

    var filteredSessions: [AgentSession] {
        if showActiveOnly {
            return sessionManager.sessions.filter { $0.isActive }
        }
        return sessionManager.sessions
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with filter
            HStack {
                Text("Sessions")
                    .font(.headline)

                Spacer()

                Toggle("Active Only", isOn: $showActiveOnly)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Session list
            if filteredSessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: showActiveOnly ? "tray" : "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text(showActiveOnly ? "No active sessions" : "No sessions yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text(showActiveOnly ? "Sessions will appear here when agents are running" : "Start a Claude Code session to begin monitoring")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredSessions, selection: $selectedSession) { session in
                    SessionRowView(session: session)
                        .tag(session)
                }
                .listStyle(.sidebar)
            }
        }
    }
}

struct SessionRowView: View {
    @ObservedObject var session: AgentSession

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(color(for: session.status))
                    .frame(width: 12, height: 12)

                if session.status == .usingTool {
                    Circle()
                        .stroke(color(for: session.status), lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .opacity(0.5)
                }
            }
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                // Project name
                Text(session.displayTitle)
                    .font(.body)
                    .fontWeight(.medium)

                // Status and last activity
                HStack(spacing: 8) {
                    Text(session.status.rawValue)
                        .font(.caption)
                        .foregroundColor(color(for: session.status))

                    if let lastActivity = session.lastActivity {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(lastActivity.displayText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Duration
                Text(session.durationFormatted)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Event count badge
            if !session.events.isEmpty {
                Text("\(session.events.count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
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
