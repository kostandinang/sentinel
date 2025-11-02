//
//  MenuBarView.swift
//  Sentinel
//
//  Menu bar extra view and popover content
//

import SwiftUI

struct MenuBarView: View {
    @StateObject private var viewModel = MenuBarViewModel()
    @ObservedObject private var sessionManager = SessionManager.shared
    @State private var showingMainWindow = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(.blue)
                Text("Sentinel")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Quick status
            if sessionManager.activeSessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "shield")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    Text("No active sessions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(sessionManager.activeSessions.prefix(5)) { session in
                            SessionQuickRowView(session: session)
                        }

                        if sessionManager.activeSessions.count > 5 {
                            Text("+ \(sessionManager.activeSessions.count - 5) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 300)
            }

            Divider()

            // Footer actions
            HStack(spacing: 12) {
                Button("Open Sentinel") {
                    showingMainWindow = true
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 320)
        .sheet(isPresented: $showingMainWindow) {
            MainWindow()
        }
    }
}

struct SessionQuickRowView: View {
    @ObservedObject var session: AgentSession

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: session.status.iconName)
                .foregroundColor(color(for: session.status))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayTitle)
                    .font(.subheadline)
                    .lineLimit(1)

                if let lastActivity = session.lastActivity {
                    Text(lastActivity.displayText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(session.durationFormatted)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
        .padding(.horizontal, 8)
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
