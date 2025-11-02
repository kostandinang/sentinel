//
//  SentinelApp.swift
//  Sentinel
//
//  Main app entry point with menu bar integration and URL scheme handling
//

import SwiftUI
import AppKit

@main
struct SentinelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Hide the main window scene since we're menu bar only
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from dock
        NSApp.setActivationPolicy(.accessory)

        // Setup menu bar
        setupMenuBar()

        // Register URL scheme handler
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:replyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    private func setupMenuBar() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "shield", accessibilityDescription: "Sentinel")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarView())

        // Monitor for outside clicks
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            if self?.popover?.isShown == true {
                self?.closePopover()
            }
        }

        // Update menu bar icon based on session status
        setupStatusObserver()
    }

    private func setupStatusObserver() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMenuBarIcon()
        }
    }

    private func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }

        let sessionManager = SessionManager.shared
        let status = sessionManager.currentStatus
        let count = sessionManager.activeSessionCount

        // Update icon
        let iconName: String
        switch status {
        case .idle:
            iconName = "shield"
        case .active:
            iconName = "shield.fill"
        case .usingTool:
            iconName = "shield.lefthalf.filled"
        case .error:
            iconName = "exclamationmark.shield"
        case .stopped:
            iconName = "shield.slash"
        }

        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Sentinel")

        // Update tooltip
        let tooltipText: String
        if count == 0 {
            tooltipText = "Sentinel - No active sessions"
        } else if count == 1 {
            tooltipText = "Sentinel - 1 active session (\(status.rawValue))"
        } else {
            tooltipText = "Sentinel - \(count) active sessions (\(status.rawValue))"
        }
        button.toolTip = tooltipText
    }

    @objc func togglePopover() {
        if let popover = popover {
            if popover.isShown {
                closePopover()
            } else {
                showPopover()
            }
        }
    }

    private func showPopover() {
        if let button = statusItem?.button, let popover = popover {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            print("Invalid URL received")
            return
        }

        handleURL(url)
    }

    private func handleURL(_ url: URL) {
        print("Received URL: \(url)")

        // Parse the URL
        guard let hookData = URLSchemeHandler.shared.handleURL(url) else {
            print("Failed to parse hook data from URL: \(url)")
            NotificationManager.shared.notifyError(message: "Invalid hook URL received")
            return
        }

        // Process the hook
        SessionManager.shared.handleHook(data: hookData)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
