//
//  MainWindow.swift
//  Sentinel
//
//  Main application window with session list and details
//

import SwiftUI

struct MainWindow: View {
    @ObservedObject private var sessionManager = SessionManager.shared
    @State private var selectedSession: AgentSession?
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            // Sidebar - Session list
            SessionListView(
                sessionManager: sessionManager,
                selectedSession: $selectedSession
            )
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            // Detail view
            if let session = selectedSession {
                SessionDetailView(session: session)
                    .navigationTitle(session.displayTitle)
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                    }
            } else {
                EmptySessionDetailView()
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                    }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}
