//
//  CompactGraphView.swift
//  Sentinel
//
//  Compact graph visualization for menu bar popover
//

import SwiftUI

struct CompactGraphView: View {
    @ObservedObject var session: AgentSession
    @State private var nodes: [SessionGraphNode] = []
    @State private var selectedNode: SessionGraphNode?
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 12) {
            // Mini timeline graph with liquid glass background
            GeometryReader { geometry in
                ZStack {
                    // Subtle background
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                        )

                    // Timeline path
                    if !nodes.isEmpty {
                        timelinePath(in: geometry.size)
                            .trim(from: 0, to: animationProgress)
                            .stroke(
                                Color.primary.opacity(0.2),
                                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                            )

                        // Nodes
                        ForEach(nodes) { node in
                            Circle()
                                .fill(node.nodeColor)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5)
                                )
                                .shadow(color: node.nodeColor.opacity(0.3), radius: 3)
                                .position(node.position)
                                .scaleEffect(selectedNode?.id == node.id ? 1.4 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedNode?.id == node.id)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedNode = node
                                    }
                                }
                        }
                    }
                }
                .padding(8)
            }
            .frame(height: 70)

            // Selected event detail with native styling
            if let node = selectedNode {
                HStack(spacing: 10) {
                    // Icon
                    Image(systemName: node.event.type.iconName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(node.nodeColor)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(node.nodeColor.opacity(0.12))
                        )

                    // Content
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(node.event.type.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)

                            if let tool = node.event.toolName {
                                ToolTagView(toolName: tool, size: .small)
                            }
                        }

                        Text(formatTime(node.event.timestamp))
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color(.sRGB, white: 0, opacity: 0.06), lineWidth: 0.5)
                        )
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .onAppear {
            buildGraph()
            withAnimation(.easeInOut(duration: 0.8)) {
                animationProgress = 1.0
            }
        }
        .onChange(of: session.events) { _ in
            buildGraph()
        }
    }
    
    private func timelinePath(in size: CGSize) -> Path {
        Path { path in
            guard !nodes.isEmpty else { return }
            
            path.move(to: nodes[0].position)
            for node in nodes.dropFirst() {
                path.addLine(to: node.position)
            }
        }
    }
    
    private func buildGraph() {
        let events = session.events
        guard !events.isEmpty else { return }
        
        let width: CGFloat = 300
        let height: CGFloat = 60
        let padding: CGFloat = 20
        
        nodes = events.enumerated().map { index, event in
            let progress = CGFloat(index) / CGFloat(max(1, events.count - 1))
            let x = padding + (width - padding * 2) * progress
            
            // Gentle wave
            let wave = sin(progress * .pi) * 8
            let y = height / 2 + wave
            
            return SessionGraphNode(
                event: event,
                position: CGPoint(x: x, y: y),
                narrative: ""
            )
        }
        
        if selectedNode == nil {
            selectedNode = nodes.last
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
