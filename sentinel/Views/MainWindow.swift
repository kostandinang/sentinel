//
//  MainWindow.swift
//  Sentinel
//
//  Main application window with session list and details
//

import SwiftUI

struct MainWindow: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedSession: AgentSession?
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            // Sidebar - Session list
            SessionListView(
                sessionManager: sessionManager,
                selectedSession: $selectedSession
            )
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 450)
        } detail: {
            // Detail view
            if let session = selectedSession {
                SessionDetailView(session: session)
                    .id(session.id)
                    .navigationTitle(session.displayTitle)
                    .toolbar {
                        ToolbarItemGroup(placement: .automatic) {
                            // Refresh button
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedSession = sessionManager.sessions.first(where: { $0.id == session.id })
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                            }
                            .help("Refresh session details")
                            .keyboardShortcut("r", modifiers: [.command])

                            // Settings button
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gear")
                            }
                            .help("Open settings")
                            .keyboardShortcut(",", modifiers: [.command])
                        }
                    }
            } else {
                EmptySessionDetailView()
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gear")
                            }
                            .help("Open settings")
                            .keyboardShortcut(",", modifiers: [.command])
                        }
                    }
            }
        }
        .frame(minWidth: 900, minHeight: 650)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            if selectedSession == nil, let firstSession = sessionManager.sessions.first {
                selectedSession = firstSession
            }
        }
    }
}
