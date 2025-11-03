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
    @State private var searchText = ""
    @State private var selectedAgentFilter: AgentType?

    var filteredSessions: [AgentSession] {
        var sessions = sessionManager.sessions

        // Filter by active status
        if showActiveOnly {
            sessions = sessions.filter { $0.isActive }
        }

        // Filter by agent type
        if let agentFilter = selectedAgentFilter {
            sessions = sessions.filter { $0.agentType == agentFilter }
        }

        // Filter by search text
        if !searchText.isEmpty {
            sessions = sessions.filter { session in
                session.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                session.workingDirectory.localizedCaseInsensitiveContains(searchText)
            }
        }

        return sessions
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with filters
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("Sessions")
                        .font(.system(size: 16, weight: .semibold))

                    Spacer()

                    // Active sessions count
                    if sessionManager.activeSessions.count > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("\(sessionManager.activeSessions.count)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                    }
                }

                // Search bar
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    TextField("Search sessions...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)

                // Filter controls
                HStack(spacing: 8) {
                    // Active only toggle
                    Toggle(isOn: $showActiveOnly) {
                        HStack(spacing: 4) {
                            Image(systemName: showActiveOnly ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 11))
                            Text("Active")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .toggleStyle(.button)
                    .controlSize(.small)

                    // Agent type filters
                    ForEach([AgentType.claudeCode, AgentType.gemini, AgentType.warp], id: \.self) { agentType in
                        Button(action: {
                            if selectedAgentFilter == agentType {
                                selectedAgentFilter = nil
                            } else {
                                selectedAgentFilter = agentType
                            }
                        }) {
                            AgentTagView(
                                agentType: agentType,
                                size: .small
                            )
                            .opacity(selectedAgentFilter == nil || selectedAgentFilter == agentType ? 1.0 : 0.4)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Results count
                    Text("\(filteredSessions.count)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Session list
            if filteredSessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: searchText.isEmpty ? (showActiveOnly ? "tray" : "clock") : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))

                    if !searchText.isEmpty {
                        Text("No matches found")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        Text("Try a different search term")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    } else {
                        Text(showActiveOnly ? "No active sessions" : "No sessions yet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        Text(showActiveOnly ? "Sessions will appear when agents start" : "Start an agent to begin monitoring")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
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
    @State private var showCopiedFeedback = false

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator - simple color dot
            Circle()
                .fill(color(for: session.status))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // Project name
                    Text(session.displayTitle)
                        .font(.system(size: 13, weight: .semibold))

                    AgentTagView(agentType: session.agentType, size: .small)
                }

                // Duration only
                Text(session.durationFormatted)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: { copyWorkingDirectory() }) {
                Label("Copy Working Directory", systemImage: "doc.on.doc")
            }

            Button(action: { copyPID() }) {
                Label("Copy Process ID", systemImage: "number")
            }

            Divider()

            Button(action: { openInFinder() }) {
                Label("Reveal in Finder", systemImage: "folder")
            }

            Button(action: { openInTerminal() }) {
                Label("Open in Terminal", systemImage: "terminal")
            }

            if session.isActive {
                Divider()

                Button(action: {}) {
                    Label("Stop Session", systemImage: "stop.circle")
                }
                .disabled(true)
            }
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

    private func copyWorkingDirectory() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(session.workingDirectory, forType: .string)
    }

    private func copyPID() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("\(session.pid)", forType: .string)
    }

    private func openInFinder() {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: session.workingDirectory)
    }

    private func openInTerminal() {
        let script = """
        tell application "Terminal"
            do script "cd '\(session.workingDirectory)'"
            activate
        end tell
        """

        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(nil)
        }
    }
}
