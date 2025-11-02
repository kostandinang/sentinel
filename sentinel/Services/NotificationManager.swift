//
//  NotificationManager.swift
//  Sentinel
//
//  Handles macOS native notifications for agent events
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {
        requestAuthorization()
    }

    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            if granted {
                print("Notification authorization granted")
            }
        }
    }

    func sendNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }

    func notifySessionStarted(workingDirectory: String) {
        let url = URL(fileURLWithPath: workingDirectory)
        let projectName = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent

        sendNotification(
            title: "Sentinel: New Session",
            body: "Agent session started in \(projectName)"
        )
    }

    func notifySessionCompleted(workingDirectory: String, duration: String) {
        let url = URL(fileURLWithPath: workingDirectory)
        let projectName = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent

        sendNotification(
            title: "Sentinel: Session Completed",
            body: "\(projectName) session ended (Duration: \(duration))"
        )
    }

    func notifyLongRunningOperation(toolName: String, workingDirectory: String) {
        let url = URL(fileURLWithPath: workingDirectory)
        let projectName = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent

        sendNotification(
            title: "Sentinel: Long Operation",
            body: "\(toolName) running in \(projectName)..."
        )
    }

    func notifyError(message: String) {
        sendNotification(
            title: "Sentinel: Error",
            body: message
        )
    }
}
