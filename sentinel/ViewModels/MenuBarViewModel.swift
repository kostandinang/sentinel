//
//  MenuBarViewModel.swift
//  Sentinel
//
//  View model for menu bar status and appearance
//

import Foundation
import Combine
import SwiftUI

class MenuBarViewModel: ObservableObject {
    @Published var statusIcon: String = "shield"
    @Published var statusColor: Color = .gray
    @Published var badgeCount: Int = 0
    @Published var shouldAnimate: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let sessionManager = SessionManager.shared

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // Observe session manager changes
        sessionManager.$activeSessions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatus()
            }
            .store(in: &cancellables)
    }

    private func updateStatus() {
        let status = sessionManager.currentStatus
        let count = sessionManager.activeSessionCount

        statusIcon = status.iconName
        badgeCount = count
        shouldAnimate = (status == .active || status == .usingTool)

        switch status {
        case .idle:
            statusColor = .gray
        case .active:
            statusColor = .blue
        case .usingTool:
            statusColor = .orange
        case .error:
            statusColor = .red
        case .stopped:
            statusColor = .gray
        }
    }

    var tooltipText: String {
        let status = sessionManager.currentStatus
        let count = sessionManager.activeSessionCount

        if count == 0 {
            return "Sentinel - No active sessions"
        } else if count == 1 {
            return "Sentinel - 1 active session (\(status.rawValue))"
        } else {
            return "Sentinel - \(count) active sessions (\(status.rawValue))"
        }
    }
}
