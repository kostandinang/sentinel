//
//  SessionGraphView.swift
//  Sentinel
//
//  Interactive graph visualization of session timeline with storytelling
//

import SwiftUI

struct SessionGraphView: View {
    @ObservedObject var session: AgentSession
    @State private var nodes: [SessionGraphNode] = []
    @State private var edges: [SessionGraphEdge] = []
    @State private var selectedNode: SessionGraphNode?
    @State private var animationProgress: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var isDragging = false
    @State private var currentStoryIndex: Int = 0
    @State private var showNarrative: Bool = true

    @Namespace private var animation

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                backgroundGradient

                // Graph canvas
                graphCanvas(in: geometry)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(magnificationGesture)
                    .gesture(dragGesture)

                // Narrative overlay
                if showNarrative, let node = selectedNode ?? nodes.first {
                    narrativeOverlay(for: node)
                }

                // Controls
                controls
            }
            .onAppear {
                buildGraph(in: geometry.size)
                animateGraph()
            }
            .onChange(of: session.events) { _ in
                buildGraph(in: geometry.size)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        Color(NSColor.windowBackgroundColor)
            .ignoresSafeArea()
    }

    // MARK: - Graph Canvas

    private func graphCanvas(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Edges
            ForEach(Array(edges.enumerated()), id: \.element.id) { index, edge in
                if let fromNode = nodes.first(where: { $0.id == edge.from }),
                   let toNode = nodes.first(where: { $0.id == edge.to }) {
                    EdgeView(
                        from: fromNode.position,
                        to: toNode.position,
                        edge: edge,
                        progress: min(1.0, max(0, animationProgress - CGFloat(index) * 0.1))
                    )
                }
            }

            // Nodes
            ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                NodeView(
                    node: node,
                    isSelected: selectedNode?.id == node.id,
                    progress: min(1.0, max(0, animationProgress - CGFloat(index) * 0.15))
                )
                .position(node.position)
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedNode = node
                        currentStoryIndex = index
                    }
                }
                .matchedGeometryEffect(id: node.id, in: animation)
            }

            // Connection lines to selected node
            if let selected = selectedNode {
                connectionHighlights(for: selected)
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }

    // MARK: - Node Highlights

    private func connectionHighlights(for node: SessionGraphNode) -> some View {
        ForEach(node.nextNodes, id: \.self) { nextId in
            if let nextNode = nodes.first(where: { $0.id == nextId }) {
                Path { path in
                    path.move(to: node.position)
                    path.addLine(to: nextNode.position)
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [node.nodeColor, nextNode.nodeColor]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .shadow(color: node.nodeColor.opacity(0.5), radius: 10)
            }
        }
    }

    // MARK: - Narrative Overlay

    private func narrativeOverlay(for node: SessionGraphNode) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                // Icon with color
                Image(systemName: node.event.type.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(node.nodeColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(node.nodeColor.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 6) {
                    // Event type
                    Text(node.event.type.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    // Timestamp
                    Text(formatTime(node.event.timestamp))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { showNarrative.toggle() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Narrative text
            Text(node.narrative)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)

            // Additional details
            if let tool = node.event.toolName {
                ToolTagView(toolName: tool, size: .medium)
            }

            Divider()

            // Navigation
            HStack {
                Button(action: previousNode) {
                    Label("Previous", systemImage: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                }
                .disabled(currentStoryIndex == 0)

                Spacer()

                Text("\(currentStoryIndex + 1) / \(nodes.count)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: nextNode) {
                    Label("Next", systemImage: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .labelStyle(.trailingIcon)
                }
                .disabled(currentStoryIndex == nodes.count - 1)
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 20, y: 8)
        .padding()
        .frame(maxWidth: 480)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Controls

    private var controls: some View {
        VStack {
            Spacer()

            HStack(spacing: 12) {
                // Reset view button
                Button(action: resetView) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
                .buttonStyle(.plain)

                // Zoom controls
                HStack(spacing: 0) {
                    Button(action: { zoomOut() }) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                    }

                    Divider()
                        .frame(height: 20)

                    Button(action: { zoomIn() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                    }
                }
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .buttonStyle(.plain)

                // Timeline scrubber
                Slider(
                    value: Binding(
                        get: { Double(currentStoryIndex) },
                        set: { index in
                            currentStoryIndex = Int(index)
                            selectedNode = nodes[currentStoryIndex]
                        }
                    ),
                    in: 0...Double(max(0, nodes.count - 1)),
                    step: 1
                )
                .frame(maxWidth: 200)
                .tint(selectedNode?.nodeColor ?? Color.accentColor)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 12, y: 4)
            .padding()
        }
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(3.0, max(0.5, value))
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                offset = value.translation
            }
            .onEnded { _ in
                isDragging = false
            }
    }

    // MARK: - Helper Functions

    private func buildGraph(in size: CGSize) {
        let graph = SessionGraphBuilder.buildGraph(from: session.events, containerSize: size)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            nodes = graph.nodes
            edges = graph.edges
            if selectedNode == nil {
                selectedNode = nodes.first
            }
        }
    }

    private func animateGraph() {
        withAnimation(.easeInOut(duration: 2.0)) {
            animationProgress = 1.0
        }
    }

    private func resetView() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            scale = 1.0
            offset = .zero
            selectedNode = nodes.first
            currentStoryIndex = 0
        }
    }

    private func zoomIn() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            scale = min(3.0, scale + 0.2)
        }
    }

    private func zoomOut() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            scale = max(0.5, scale - 0.2)
        }
    }

    private func nextNode() {
        guard currentStoryIndex < nodes.count - 1 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            currentStoryIndex += 1
            selectedNode = nodes[currentStoryIndex]
        }
    }

    private func previousNode() {
        guard currentStoryIndex > 0 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            currentStoryIndex -= 1
            selectedNode = nodes[currentStoryIndex]
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Node View

struct NodeView: View {
    let node: SessionGraphNode
    let isSelected: Bool
    let progress: CGFloat

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Subtle glow effect for selected node
            if isSelected {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                node.nodeColor.opacity(0.2),
                                node.nodeColor.opacity(0.0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: node.glowRadius
                        )
                    )
                    .frame(width: node.nodeSize + node.glowRadius * 2, height: node.nodeSize + node.glowRadius * 2)
                    .opacity(isPulsing ? 0.6 : 0.3)
            }

            // Main node with liquid glass effect
            Circle()
                .fill(node.nodeColor)
                .frame(width: node.nodeSize, height: node.nodeSize)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
                )
                .shadow(color: node.nodeColor.opacity(0.3), radius: 6, y: 3)

            // Icon
            Image(systemName: node.event.type.iconName)
                .font(.system(size: node.nodeSize * 0.4, weight: .medium))
                .foregroundColor(.white)

            // Selection ring
            if isSelected {
                Circle()
                    .strokeBorder(node.nodeColor, lineWidth: 2.5)
                    .frame(width: node.nodeSize + 10, height: node.nodeSize + 10)
                    .shadow(color: node.nodeColor.opacity(0.4), radius: 8)
            }
        }
        .scaleEffect(progress * (isSelected ? 1.1 : 1.0))
        .opacity(progress)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Edge View

struct EdgeView: View {
    let from: CGPoint
    let to: CGPoint
    let edge: SessionGraphEdge
    let progress: CGFloat

    var body: some View {
        Path { path in
            path.move(to: from)

            // Create a curved path
            let controlPoint = CGPoint(
                x: (from.x + to.x) / 2,
                y: min(from.y, to.y) - 30
            )
            path.addQuadCurve(to: to, control: controlPoint)
        }
        .trim(from: 0, to: progress)
        .stroke(
            Color.primary.opacity(0.15),
            style: StrokeStyle(
                lineWidth: 2,
                lineCap: .round,
                lineJoin: .round
            )
        )
        .opacity(edge.opacity * Double(progress))
    }

    private var interpolatedPosition: CGPoint {
        let t = progress
        let controlPoint = CGPoint(
            x: (from.x + to.x) / 2,
            y: min(from.y, to.y) - 30
        )

        // Quadratic Bezier interpolation
        let x = pow(1 - t, 2) * from.x + 2 * (1 - t) * t * controlPoint.x + pow(t, 2) * to.x
        let y = pow(1 - t, 2) * from.y + 2 * (1 - t) * t * controlPoint.y + pow(t, 2) * to.y

        return CGPoint(x: x, y: y)
    }
}

// MARK: - Trailing Icon Label Style

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: TrailingIconLabelStyle { TrailingIconLabelStyle() }
}
