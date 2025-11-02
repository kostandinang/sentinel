//
//  SessionManager.swift
//  Sentinel
//
//  Core business logic for managing agent sessions
//

import Foundation
import Combine

class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var sessions: [AgentSession] = []
    @Published var activeSessions: [AgentSession] = []

    private let maxStoredSessions = 20
    private let persistenceKey = "SentinelSessions"
    private var monitorTimer: Timer?

    private init() {
        loadSessions()
        startProcessMonitoring()
    }

    deinit {
        stopProcessMonitoring()
    }

    // MARK: - Session Management

    func handleHook(data: HookData) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Find or create session
            if let session = self.sessions.first(where: { $0.pid == data.pid }) {
                self.updateSession(session, with: data)
            } else {
                self.createSession(with: data)
            }

            self.updateActiveSessions()
            self.saveSessions()
        }
    }

    private func createSession(with data: HookData) {
        let workingDir = data.workingDirectory ?? ProcessMonitor.shared.getWorkingDirectory(pid: data.pid) ?? "Unknown"

        let session = AgentSession(
            pid: data.pid,
            agentType: .claudeCode,
            workingDirectory: workingDir
        )

        let event = HookEvent(
            type: data.type,
            details: data.type.displayName,
            toolName: data.toolName
        )

        session.addEvent(event)
        sessions.insert(session, at: 0) // Add to beginning

        // Send notification for new session
        if data.type == .promptSubmit {
            NotificationManager.shared.notifySessionStarted(workingDirectory: workingDir)
        }

        // Trim old sessions
        if sessions.count > maxStoredSessions {
            sessions = Array(sessions.prefix(maxStoredSessions))
        }
    }

    private func updateSession(_ session: AgentSession, with data: HookData) {
        let event = HookEvent(
            type: data.type,
            details: data.type.displayName,
            toolName: data.toolName
        )

        session.addEvent(event)

        // Send notification for session completion
        if data.type == .sessionStop {
            NotificationManager.shared.notifySessionCompleted(
                workingDirectory: session.workingDirectory,
                duration: session.durationFormatted
            )
        }
    }

    private func updateActiveSessions() {
        activeSessions = sessions.filter { $0.isActive }
    }

    // MARK: - Process Monitoring

    private func startProcessMonitoring() {
        // Check for dead processes every 10 seconds
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkDeadProcesses()
        }
    }

    private func stopProcessMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    private func checkDeadProcesses() {
        let activePIDs = activeSessions.map { $0.pid }
        let deadPIDs = ProcessMonitor.shared.checkDeadProcesses(pids: activePIDs)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            for pid in deadPIDs {
                if let session = self.sessions.first(where: { $0.pid == pid && $0.isActive }) {
                    // Mark session as stopped if process died
                    let event = HookEvent(
                        type: .sessionStop,
                        details: "Process ended",
                        toolName: nil
                    )
                    session.addEvent(event)
                }
            }

            self.updateActiveSessions()
            self.saveSessions()
        }
    }

    // MARK: - Persistence

    private func saveSessions() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(sessions)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            print("Error saving sessions: \(error)")
        }
    }

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else {
            return
        }

        do {
            let decoder = JSONDecoder()
            sessions = try decoder.decode([AgentSession].self, from: data)
            updateActiveSessions()
        } catch {
            print("Error loading sessions: \(error)")
        }
    }

    func clearHistory() {
        sessions.removeAll { !$0.isActive }
        saveSessions()
    }

    // MARK: - Computed Properties

    var currentStatus: SessionStatus {
        if activeSessions.isEmpty {
            return .idle
        }

        // Priority: error > usingTool > active > idle
        if activeSessions.contains(where: { $0.status == .error }) {
            return .error
        }
        if activeSessions.contains(where: { $0.status == .usingTool }) {
            return .usingTool
        }
        if activeSessions.contains(where: { $0.status == .active }) {
            return .active
        }
        return .idle
    }

    var activeSessionCount: Int {
        activeSessions.count
    }
}
