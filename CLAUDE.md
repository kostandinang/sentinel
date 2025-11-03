# Sentinel - Project Context for Claude Code

## Project Overview

Sentinel is a native macOS menu bar application that monitors and displays real-time status of Claude Code agent sessions. The app provides a clean, minimal interface for tracking multiple agent sessions simultaneously with live updates, notifications, and detailed activity timelines.

## Core Philosophy

- **Native First:** Build a true macOS app that feels like it belongs on the platform
- **Minimal & Clean:** Every UI element must serve a purpose; no clutter
- **Real-time:** Instant updates when agent activity occurs
- **Extensible:** Start with Claude Code but design for multiple agent types
- **Reliable:** Zero crashes, graceful error handling, defensive programming

## Technology Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI (100% SwiftUI, no UIKit)
- **Reactive:** Combine framework for state management
- **macOS Target:** macOS 13.0+ (Ventura and later)
- **Architecture:** MVVM pattern with clear separation of concerns

## Project Structure Philosophy

### Models (Data Layer)

Pure Swift structs/classes with no UI dependencies. Should be:

- Codable for persistence
- Equatable/Hashable where needed
- Immutable where possible (prefer `let` over `var`)
- Well-documented with clear property purposes

### ViewModels (Business Logic)

ObservableObject classes that:

- Bridge models and views
- Handle all business logic
- Manage state mutations
- Never import SwiftUI (except for @Published)
- Are unit-testable

### Views (Presentation Layer)

SwiftUI views that:

- Are as dumb as possible (minimal logic)
- Observe ViewModels via @StateObject/@ObservedObject
- Focus purely on presentation
- Use SF Symbols for icons
- Support dark mode automatically

### Services (Infrastructure)

Reusable components for:

- URL scheme handling
- Notification management
- Process monitoring
- Persistence/storage
- Network calls (if needed later)

## Key Design Patterns

### 1. URL Scheme Communication

```swift
// Expected URL format
sentinel://hook?type=prompt-submit&pid=12345&pwd=/Users/dev/project

// URL components to parse
- Scheme: "sentinel"
- Host: "hook"
- Query parameters: type, pid, pwd, tool (optional)
```

**Important:** Always URL-decode parameters, especially `pwd` and `tool` which may contain special characters.

### 2. Session State Management

Sessions are identified by PID (Process ID):

- One PID = One unique session
- Sessions persist until Stop hook or PID dies
- Track all events chronologically
- Auto-cleanup dead PIDs periodically

### 3. Menu Bar Status Icon

The menu bar icon is the primary interface:

- Must update instantly when hooks received
- Show aggregated status when multiple sessions active
- Badge count for multiple active sessions
- Animated transitions between states

### 4. Notification Strategy

Be conservative with notifications:

- **DO notify:** Session start, session end, errors
- **DON'T notify:** Every tool use (too noisy)
- Make notifications actionable (click to open session)
- Respect user's notification preferences
- Group related notifications

## Swift/SwiftUI Best Practices

### Code Style

```swift
// ✅ Good: Clear, descriptive names
func handleSessionStartHook(pid: Int, workingDirectory: String) {
    // Implementation
}

// ❌ Bad: Abbreviated, unclear
func hndlSessStrt(p: Int, wd: String) {
    // Implementation
}

// ✅ Good: Guard statements for early returns
guard let session = sessions[pid] else {
    logger.error("Session not found for PID: \(pid)")
    return
}

// ✅ Good: Computed properties for derived state
var activeSessionCount: Int {
    sessions.values.filter { $0.status == .active }.count
}
```

### SwiftUI Patterns

```swift
// ✅ Good: Extract subviews for clarity
struct SessionListView: View {
    var body: some View {
        List(sessions) { session in
            SessionRowView(session: session)
        }
    }
}

// ✅ Good: Use @ViewBuilder for conditional content
@ViewBuilder
var statusIcon: some View {
    switch status {
    case .idle: Image(systemName: "shield")
    case .active: Image(systemName: "shield.fill")
    case .error: Image(systemName: "exclamationmark.shield")
    }
}

// ✅ Good: Preferences for consistent styling
extension Font {
    static let sessionTitle = Font.system(.body, design: .default).weight(.semibold)
    static let sessionDetail = Font.system(.caption, design: .monospaced)
}
```

### Error Handling

```swift
// ✅ Good: Specific error types
enum SentinelError: LocalizedError {
    case invalidURL(String)
    case sessionNotFound(pid: Int)
    case persistenceFailure(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid hook URL: \(url)"
        case .sessionNotFound(let pid):
            return "No session found for PID \(pid)"
        case .persistenceFailure(let error):
            return "Failed to save data: \(error.localizedDescription)"
        }
    }
}

// ✅ Good: Graceful degradation
func loadSessions() {
    do {
        sessions = try persistenceService.load()
    } catch {
        logger.error("Failed to load sessions: \(error)")
        // Continue with empty sessions rather than crashing
        sessions = []
    }
}
```

## Critical Implementation Details

### URL Scheme Registration

In `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourname.sentinel</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>sentinel</string>
        </array>
    </dict>
</array>
```

### Menu Bar Setup

```swift
// App should be menu bar only (LSUIElement = true)
<key>LSUIElement</key>
<true/>

// Hide dock icon, show only in menu bar
```

### Process Monitoring

```swift
// Check if PID is still alive
func isProcessAlive(pid: Int) -> Bool {
    kill(pid_t(pid), 0) == 0
}

// Monitor PIDs periodically (every 5 seconds)
Timer.publish(every: 5, on: .main, in: .common)
    .autoconnect()
    .sink { _ in cleanupDeadSessions() }
```

### Persistence

```swift
// Use ApplicationSupport directory
let appSupportURL = FileManager.default.urls(
    for: .applicationSupportDirectory,
    in: .userDomainMask
).first!

let sentinelURL = appSupportURL.appendingPathComponent("Sentinel")
let sessionsURL = sentinelURL.appendingPathComponent("sessions.json")

// Save sessions as JSON
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let data = try encoder.encode(sessions)
try data.write(to: sessionsURL)
```

## UI/UX Guidelines

### Color Semantics

- **Blue (#007AFF):** Active, working, normal operation
- **Orange (#FF9500):** Warning, tool use, attention
- **Red (#FF3B30):** Error, critical issue
- **Gray (#8E8E93):** Idle, disabled, secondary
- **Green (#34C759):** Success, completed (use sparingly)

### Animation Timing

- **Menu bar icon:** 0.3s ease-in-out for state changes
- **List updates:** 0.2s spring animation
- **Window appearance:** 0.25s ease-out
- **Pulse animation:** 1.5s continuous for active state

### Typography Hierarchy

1. **Session Title:** Body, Semibold
2. **Status Text:** Callout, Regular
3. **Timestamps:** Caption, Regular
4. **Directory Path:** Caption, Monospaced
5. **Details:** Footnote, Regular

### Spacing

- **Padding (small):** 8pt
- **Padding (medium):** 12pt
- **Padding (large):** 16pt
- **List row height:** 60pt minimum
- **Icon size:** 16x16 (menu bar), 24x24 (window)

## Testing Strategy

### Unit Tests

- URL parsing logic
- Session state transitions
- PID lifecycle management
- Persistence save/load

### Integration Tests

- URL scheme handling end-to-end
- Notification delivery
- Multi-session scenarios

### Manual Testing Checklist

- [ ] Menu bar icon updates correctly
- [ ] Window opens and closes smoothly
- [ ] Notifications appear appropriately
- [ ] Dark mode looks correct
- [ ] Multiple sessions tracked simultaneously
- [ ] Dead PIDs cleaned up
- [ ] Data persists across app restarts
- [ ] Accessibility with VoiceOver

## Common Pitfalls to Avoid

### ❌ Don't:

- Use UIKit when SwiftUI can do it
- Block the main thread with heavy operations
- Hardcode colors (use semantic colors)
- Ignore error cases
- Over-notify the user
- Store sensitive data without encryption
- Assume hooks always arrive in order
- Parse URLs manually (use URLComponents)

### ✅ Do:

- Use async/await for I/O operations
- Leverage Combine for reactive updates
- Support keyboard navigation
- Handle edge cases gracefully
- Log errors for debugging
- Test with multiple simultaneous sessions
- Validate all external input (URLs, PIDs)
- Document complex logic

## Development Workflow

### Phase 1: Foundation (Day 1-2)

1. Set up Xcode project structure
2. Implement data models
3. Create URL scheme handler
4. Build basic session manager

### Phase 2: Core Features (Day 3-4)

1. Menu bar integration
2. Session tracking logic
3. Basic window with session list
4. Notification system

### Phase 3: Polish (Day 5-6)

1. Animations and transitions
2. Dark mode refinement
3. Settings panel
4. Persistence implementation

### Phase 4: Testing & Docs (Day 7)

1. Comprehensive testing
2. README with setup instructions
3. Sample hooks.json file
4. App icon design

## Debugging Tips

### URL Scheme Testing

```bash
# Test URL scheme from terminal
open "sentinel://hook?type=prompt-submit&pid=12345&pwd=/Users/test/project"

# Monitor system log for URL scheme events
log stream --predicate 'process == "Sentinel"' --level debug
```

### Session Tracking

Add debug logging:

```swift
func handleHook(_ url: URL) {
    print("📥 Received hook: \(url)")
    // Parse and handle...
    print("✅ Hook processed successfully")
}
```

### Menu Bar Issues

```swift
// Verify status item exists
if statusItem == nil {
    print("⚠️ Status item not initialized!")
}
```

## Resources & References

### Apple Documentation

- [Human Interface Guidelines - Menu Bar Extras](https://developer.apple.com/design/human-interface-guidelines/menu-bar-extras)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [UserNotifications](https://developer.apple.com/documentation/usernotifications)

### Design Inspiration

- macOS system apps (Activity Monitor, Time Machine)
- Menu bar apps (Bartender, Magnet, CleanShot)
- Focus on simplicity and clarity

## Questions to Consider

When implementing features, ask:

1. Is this the simplest solution that works?
2. Does this feel native to macOS?
3. Will this scale to 10+ concurrent sessions?
4. How does this handle errors gracefully?
5. Is this accessible to all users?
6. Does this respect the user's attention?

## Success Metrics

A successful implementation will:

- ✅ Launch instantly (< 1 second)
- ✅ Handle 20+ concurrent sessions smoothly
- ✅ Update menu bar icon within 100ms of hook
- ✅ Never crash, even with malformed input
- ✅ Feel indistinguishable from Apple's own apps
- ✅ Receive positive feedback on UI/UX clarity

## Final Notes

Remember: Sentinel is a **monitoring tool**, not a control panel. Its job is to observe and inform, not to interfere with agent operations. Keep the interface minimal, the updates instant, and the notifications meaningful.

Build something you'd want to use every day. 🛡️
