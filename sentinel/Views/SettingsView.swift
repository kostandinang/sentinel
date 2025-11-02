//
//  SettingsView.swift
//  Sentinel
//
//  Settings and configuration panel
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var sessionManager = SessionManager.shared
    @AppStorage("notifyOnNewSession") private var notifyOnNewSession = true
    @AppStorage("notifyOnCompletion") private var notifyOnCompletion = true
    @AppStorage("notifyOnLongOperation") private var notifyOnLongOperation = false
    @AppStorage("longOperationThreshold") private var longOperationThreshold = 60.0

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("New Session Started", isOn: $notifyOnNewSession)
                    .help("Show notification when a new agent session begins")

                Toggle("Session Completed", isOn: $notifyOnCompletion)
                    .help("Show notification when a session ends")

                Toggle("Long Running Operations", isOn: $notifyOnLongOperation)
                    .help("Warn about operations taking longer than threshold")

                if notifyOnLongOperation {
                    HStack {
                        Text("Threshold:")
                        Slider(value: $longOperationThreshold, in: 30...300, step: 30)
                        Text("\(Int(longOperationThreshold))s")
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }

            Section("Monitoring") {
                HStack {
                    Text("Supported Agents:")
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        ForEach(AgentType.allCases, id: \.self) { type in
                            HStack(spacing: 4) {
                                Image(systemName: type.iconName)
                                Text(type.displayName)
                            }
                            .font(.caption)
                        }
                    }
                }

                HStack {
                    Text("URL Scheme:")
                    Spacer()
                    Text("sentinel://")
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            Section("Data") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Session History")
                            .font(.body)
                        Text("\(sessionManager.sessions.count) sessions stored")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Clear History") {
                        sessionManager.clearHistory()
                    }
                    .disabled(sessionManager.sessions.filter { !$0.isActive }.isEmpty)
                }
            }

            Section("Hook Configuration") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("To enable Sentinel monitoring, add hooks to your Claude Code configuration:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("~/.claude-code/hooks.json")
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)

                        Spacer()

                        Button("Copy Example") {
                            copyExampleHooks()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    Text("See documentation for full setup instructions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Section("About") {
                HStack {
                    Text("Version:")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Active Sessions:")
                    Spacer()
                    Text("\(sessionManager.activeSessionCount)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 600)
    }

    private func copyExampleHooks() {
        let examplePath = Bundle.main.path(forResource: "example-hooks", ofType: "json") ?? ""
        if let content = try? String(contentsOfFile: examplePath, encoding: .utf8) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
        }
    }
}
