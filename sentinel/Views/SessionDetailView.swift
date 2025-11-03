//
//  SessionDetailView.swift
//  Sentinel
//
//  Detailed view of a single session
//

import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var session: AgentSession
    @State private var showingGraph = false

    var body: some View {
        ZStack(alignment: .bottom) {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        // Status icon
                        Image(systemName: session.status.iconName)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(color(for: session.status))
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(color(for: session.status).opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(session.displayTitle)
                                    .font(.system(size: 18, weight: .semibold))

                                AgentTagView(agentType: session.agentType, size: .medium)
                            }

                            Text(session.status.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(color(for: session.status))
                        }

                        Spacer()

                        // Graph view button
                        Button(action: { showingGraph = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Timeline Graph")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.12))
                            )
                            .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(session.events.isEmpty)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Session info with copy actions
                GroupBox(label: Label("Session Info", systemImage: "info.circle.fill")) {
                    VStack(spacing: 14) {
                        InfoRow(label: "Working Directory", value: session.workingDirectory, copyable: true)
                        InfoRow(label: "Process ID", value: "\(session.pid)", copyable: true)
                        InfoRow(label: "Agent Type", value: session.agentType.displayName, copyable: false)
                        InfoRow(label: "Started", value: formatDate(session.startTime), copyable: false)
                        InfoRow(label: "Duration", value: session.durationFormatted, copyable: false)

                        if let currentTool = session.currentTool {
                            Divider()
                            HStack(spacing: 8) {
                                Image(systemName: "hammer.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                                Text("Currently using:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text(currentTool)
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.12))
                                    .cornerRadius(4)
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                }

                // Activity timeline
                GroupBox(label: Label("Activity Timeline (\(session.events.count))", systemImage: "clock.arrow.circlepath")) {
                    if session.events.isEmpty {
                        Text("No activity yet")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(session.events.reversed()) { event in
                                EventRowView(event: event)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Spacer()
            }
            .padding()
        }
        
        // Bottom drawer for timeline graph
        if showingGraph {
            GraphDrawerView(isPresented: $showingGraph) {
                SessionGraphView(session: session)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(1000)
        }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showingGraph)
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var copyable: Bool = true
    @State private var showCopiedFeedback = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .leading)

            Text(value)
                .font(.system(size: 12, weight: .regular, design: label == "Process ID" ? .monospaced : .default))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .lineLimit(3)

            Spacer()

            if copyable {
                Button(action: copyToClipboard) {
                    Image(systemName: showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(showCopiedFeedback ? .green : .secondary)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(showCopiedFeedback ? "Copied!" : "Copy to clipboard")
            }
        }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)

        withAnimation(.easeInOut(duration: 0.2)) {
            showCopiedFeedback = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopiedFeedback = false
            }
        }
    }
}

struct EventRowView: View {
    let event: HookEvent
    @State private var isVisible = false
    @State private var isHovered = false
    @State private var showingDetails = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Timeline indicator with connecting line
            ZStack {
                // Connecting line
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 2)

                // Event dot with scale animation and glow
                Circle()
                    .fill(color(for: event.type))
                    .frame(width: 11, height: 11)
                    .overlay(
                        Circle()
                            .strokeBorder(Color(NSColor.controlBackgroundColor), lineWidth: 2.5)
                    )
                    .shadow(color: isRecent ? color(for: event.type).opacity(0.5) : .clear, radius: 6)
                    .scaleEffect(isVisible ? 1.0 : 0.3)
            }
            .frame(width: 11)
            .padding(.trailing, 16)
            .padding(.top, 2)

            // Content card with improved hierarchy
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    // Icon with improved sizing
                    Image(systemName: event.type.iconName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(color(for: event.type))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(color(for: event.type).opacity(0.14))
                                .overlay(
                                    Circle()
                                        .strokeBorder(color(for: event.type).opacity(0.3), lineWidth: 0.5)
                                )
                        )

                    // Event details with better spacing
                    VStack(alignment: .leading, spacing: 6) {
                        // Title row with improved typography
                        HStack(spacing: 0) {
                            Text(eventTitle)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            if let toolName = event.toolName {
                                Text(" ")
                                ToolTagView(toolName: toolName, size: .small)
                            }
                        }

                        // Metadata row with better visual hierarchy
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 9, weight: .medium))
                                Text(formatTimestamp(event.timestamp))
                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                            }
                            .foregroundColor(.secondary)

                            if !isRecent {
                                Text("•")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary.opacity(0.5))

                                Text(timeAgo(from: event.timestamp))
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.75))
                            }
                        }

                        // Additional context for certain event types
                        if let contextText = eventContext {
                            Text(contextText)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.secondary.opacity(0.9))
                                .lineLimit(2)
                                .padding(.top, 2)
                        }
                    }

                    Spacer()

                    // Recent indicator badge
                    if isRecent {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(color(for: event.type))
                                .frame(width: 6, height: 6)

                            Text("Live")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(color(for: event.type))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(color(for: event.type).opacity(0.12))
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? .ultraThinMaterial : .thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                color(for: event.type).opacity(isRecent ? 0.3 : (isHovered ? 0.15 : 0.06)),
                                lineWidth: isRecent ? 1.2 : (isHovered ? 0.8 : 0.5)
                            )
                    )
                    .shadow(
                        color: isRecent ? color(for: event.type).opacity(0.15) : .clear,
                        radius: 8,
                        y: 2
                    )
            )
            .opacity(isVisible ? 1.0 : 0)
            .offset(x: isVisible ? 0 : 20)
            .scaleEffect(isVisible ? 1.0 : 0.95)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            .onTapGesture {
                showingDetails = true
            }
        }
        .padding(.vertical, 5)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.03)) {
                isVisible = true
            }
        }
        .sheet(isPresented: $showingDetails) {
            EventDetailSheet(event: event)
        }
    }

    private var eventTitle: String {
        switch event.type {
        case .promptSubmit, .userPromptSubmit:
            return "Prompt submitted"
        case .toolStart, .preToolUse:
            return event.toolName != nil ? "Started" : "Tool started"
        case .toolComplete, .postToolUse:
            return event.toolName != nil ? "Completed" : "Tool completed"
        case .sessionStop, .stop, .sessionEnd:
            return "Session ended"
        case .notification:
            return "Notification"
        case .subagentStop:
            return "Subagent stopped"
        case .preCompact:
            return "Compacting"
        case .sessionStart:
            return "Session started"
        }
    }

    private var eventContext: String? {
        // Add contextual information based on event type
        switch event.type {
        case .promptSubmit, .userPromptSubmit:
            if let prompt = event.prompt, !prompt.isEmpty {
                return prompt
            }
            return "Agent is processing your request"
        case .toolStart, .preToolUse:
            return nil // Tool name is already displayed in tag
        case .toolComplete, .postToolUse:
            return "Task finished successfully"
        case .sessionStop, .stop, .sessionEnd:
            return "All activities concluded"
        case .notification:
            return event.details
        case .subagentStop:
            return "Subagent task completed"
        case .preCompact:
            return "Context being compacted to save memory"
        case .sessionStart:
            return "New session initialized"
        }
    }

    private var isRecent: Bool {
        Date().timeIntervalSince(event.timestamp) < 15
    }

    private func color(for type: HookType) -> Color {
        switch type {
        case .promptSubmit, .userPromptSubmit:
            return Color(red: 0.0, green: 0.48, blue: 1.0) // Blue
        case .toolStart, .preToolUse:
            return Color(red: 1.0, green: 0.58, blue: 0.0) // Orange
        case .toolComplete, .postToolUse:
            return Color(red: 0.2, green: 0.78, blue: 0.35) // Green
        case .sessionStop, .stop, .sessionEnd:
            return Color(red: 0.56, green: 0.56, blue: 0.58) // Gray
        case .notification:
            return Color(red: 1.0, green: 0.78, blue: 0.0) // Yellow
        case .subagentStop:
            return Color(red: 0.56, green: 0.56, blue: 0.58) // Gray
        case .preCompact:
            return Color(red: 0.68, green: 0.32, blue: 0.87) // Purple
        case .sessionStart:
            return Color(red: 0.2, green: 0.78, blue: 0.35) // Green
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Graph Drawer View

struct GraphDrawerView<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Drawer content - slides from bottom, takes up 80% of screen
                VStack(spacing: 0) {
                    // Drag handle
                    VStack(spacing: 4) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.5))
                            .frame(width: 36, height: 5)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                // Close drawer if dragged down significantly
                                if value.translation.height > 100 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        isPresented = false
                                    }
                                }
                            }
                    )
                    
                    // Header
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accentColor)
                        
                        Text("Timeline Graph")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    // Graph content
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: geometry.size.height * 0.8)
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(16, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.3), radius: 20, y: -5)
            }
        }
    }
}

// Helper for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = NSBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0..<self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo, .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        return path
    }
}

struct UIRectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = UIRectCorner(rawValue: 1 << 0)
    static let topRight = UIRectCorner(rawValue: 1 << 1)
    static let bottomLeft = UIRectCorner(rawValue: 1 << 2)
    static let bottomRight = UIRectCorner(rawValue: 1 << 3)
    static let allCorners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

extension NSBezierPath {
    convenience init(roundedRect rect: CGRect, byRoundingCorners corners: UIRectCorner, cornerRadii: CGSize) {
        self.init()
        
        let topLeft = rect.origin
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        
        // Start from top-left
        if corners.contains(.topLeft) {
            move(to: CGPoint(x: topLeft.x + cornerRadii.width, y: topLeft.y))
        } else {
            move(to: topLeft)
        }
        
        // Top edge and top-right corner
        if corners.contains(.topRight) {
            line(to: CGPoint(x: topRight.x - cornerRadii.width, y: topRight.y))
            curve(to: CGPoint(x: topRight.x, y: topRight.y + cornerRadii.height),
                  controlPoint1: topRight,
                  controlPoint2: topRight)
        } else {
            line(to: topRight)
        }
        
        // Right edge and bottom-right corner
        if corners.contains(.bottomRight) {
            line(to: CGPoint(x: bottomRight.x, y: bottomRight.y - cornerRadii.height))
            curve(to: CGPoint(x: bottomRight.x - cornerRadii.width, y: bottomRight.y),
                  controlPoint1: bottomRight,
                  controlPoint2: bottomRight)
        } else {
            line(to: bottomRight)
        }
        
        // Bottom edge and bottom-left corner
        if corners.contains(.bottomLeft) {
            line(to: CGPoint(x: bottomLeft.x + cornerRadii.width, y: bottomLeft.y))
            curve(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y - cornerRadii.height),
                  controlPoint1: bottomLeft,
                  controlPoint2: bottomLeft)
        } else {
            line(to: bottomLeft)
        }
        
        // Left edge and back to top-left corner
        if corners.contains(.topLeft) {
            line(to: CGPoint(x: topLeft.x, y: topLeft.y + cornerRadii.height))
            curve(to: CGPoint(x: topLeft.x + cornerRadii.width, y: topLeft.y),
                  controlPoint1: topLeft,
                  controlPoint2: topLeft)
        } else {
            line(to: topLeft)
        }
        
        close()
    }
}

// Empty state view
struct EmptySessionDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(.blue.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text("No Session Selected")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Choose a session from the sidebar to view its details")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    QuickTipItem(
                        icon: "command",
                        text: "⌘ + O to view agents"
                    )

                    QuickTipItem(
                        icon: "magnifyingglass",
                        text: "Search to filter sessions"
                    )
                }

                HStack(spacing: 16) {
                    QuickTipItem(
                        icon: "hand.point.up.left",
                        text: "Right-click for quick actions"
                    )

                    QuickTipItem(
                        icon: "doc.on.doc",
                        text: "Click to copy values"
                    )
                }
            }
            .padding(.top, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
}

struct QuickTipItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                )

            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Event Detail Sheet

struct EventDetailSheet: View {
    let event: HookEvent
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: event.type.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color(for: event.type))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(color(for: event.type).opacity(0.14))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.type.displayName)
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text(formatTimestamp(event.timestamp))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event Type Info
                    GroupBox(label: Label("Event Information", systemImage: "info.circle")) {
                        VStack(spacing: 12) {
                            DetailRow(label: "Type", value: event.type.rawValue)
                            DetailRow(label: "Timestamp", value: formatFullTimestamp(event.timestamp))
                            DetailRow(label: "Time Ago", value: timeAgo(from: event.timestamp))

                            if let toolName = event.toolName {
                                DetailRow(label: "Tool", value: toolName)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Prompt Info (if available)
                    if let prompt = event.prompt, !prompt.isEmpty {
                        GroupBox(label: Label("Prompt", systemImage: "text.bubble")) {
                            Text(prompt)
                                .font(.system(size: 13))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(6)
                                .padding(.vertical, 8)
                        }
                    }

                    // Tool Input (if available)
                    if let toolInput = event.toolInput, !toolInput.isEmpty {
                        GroupBox(label: Label("Tool Input", systemImage: "arrow.right.circle")) {
                            ScrollView {
                                Text(toolInput)
                                    .font(.system(size: 11, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color(NSColor.textBackgroundColor))
                                    .cornerRadius(6)
                            }
                            .frame(maxHeight: 200)
                            .padding(.vertical, 8)
                        }
                    }

                    // Tool Response (if available)
                    if let toolResponse = event.toolResponse, !toolResponse.isEmpty {
                        GroupBox(label: Label("Tool Response", systemImage: "arrow.left.circle")) {
                            ScrollView {
                                Text(toolResponse)
                                    .font(.system(size: 11, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color(NSColor.textBackgroundColor))
                                    .cornerRadius(6)
                            }
                            .frame(maxHeight: 200)
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // Raw Data
                    GroupBox(label: Label("Raw Data", systemImage: "doc.text")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(formatEventData())
                                .font(.system(size: 12, design: .monospaced))
                                .textSelection(.enabled)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(6)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Context
                    if let contextText = eventContext {
                        GroupBox(label: Label("Context", systemImage: "bubble.left.and.bubble.right")) {
                            Text(contextText)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private func color(for type: HookType) -> Color {
        switch type {
        case .promptSubmit, .userPromptSubmit:
            return Color(red: 0.0, green: 0.48, blue: 1.0)
        case .toolStart, .preToolUse:
            return Color(red: 1.0, green: 0.58, blue: 0.0)
        case .toolComplete, .postToolUse:
            return Color(red: 0.2, green: 0.78, blue: 0.35)
        case .sessionStop, .stop, .sessionEnd:
            return Color(red: 0.56, green: 0.56, blue: 0.58)
        case .notification:
            return Color(red: 1.0, green: 0.78, blue: 0.0)
        case .subagentStop:
            return Color(red: 0.56, green: 0.56, blue: 0.58)
        case .preCompact:
            return Color(red: 0.68, green: 0.32, blue: 0.87)
        case .sessionStart:
            return Color(red: 0.2, green: 0.78, blue: 0.35)
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatFullTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
    
    private var eventContext: String? {
        switch event.type {
        case .promptSubmit, .userPromptSubmit:
            return "A new prompt was submitted to the agent for processing. This marks the beginning of an interaction."
        case .toolStart, .preToolUse:
            return "The agent has started executing a tool. This indicates active work is being performed."
        case .toolComplete, .postToolUse:
            return "The tool execution has completed successfully. The agent can now process the results."
        case .sessionStop, .stop, .sessionEnd:
            return "The agent session has been terminated. All activities have concluded."
        case .notification:
            return "Claude Code sent a notification, typically for permission requests or status updates."
        case .subagentStop:
            return "A subagent (Task tool) has completed its work and returned control to the main agent."
        case .preCompact:
            return "Context is being compacted to reduce memory usage and stay within token limits."
        case .sessionStart:
            return "A new agent session has been initialized and is ready to accept commands."
        }
    }
    
    private func formatEventData() -> String {
        var lines: [String] = []
        lines.append("ID: \(event.id.uuidString)")
        lines.append("Type: \(event.type.rawValue)")
        lines.append("Timestamp: \(event.timestamp)")
        lines.append("Details: \(event.details)")
        if let toolName = event.toolName {
            lines.append("Tool: \(toolName)")
        }
        if let prompt = event.prompt {
            lines.append("Prompt: \(prompt)")
        }
        if let toolInput = event.toolInput {
            lines.append("Tool Input: \(toolInput)")
        }
        if let toolResponse = event.toolResponse {
            lines.append("Tool Response: \(toolResponse)")
        }
        return lines.joined(separator: "\n")
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}
