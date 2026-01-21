//
//  SessionDetailView.swift
//  Cue
//
//  Created by Jackson Moody on 1/20/26.
//

import SwiftUI

struct SessionDetailView: View {
    let session: Session
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Icon
                    HStack {
                        Spacer()
                        Image(systemName: iconName(for: session.reflectionType))
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.top, 40)
                    
                    // Session Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: "Date & Time", value: formatDate(session.timestamp))
                        DetailRow(label: "Duration", value: formatDuration(session.duration))
                    }
                    .padding(.horizontal)
                    
                    // Heart Rate Graph
                    VStack(alignment: .leading, spacing: 12) {
                        HeartRateGraph()
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func iconName(for reflectionType: ReflectionOptions) -> String {
        switch reflectionType {
        case .breaths:
            return "apple.meditate"
        case .taps:
            return "hand.tap"
        case .visualization:
            return "photo"
        case .exercise:
            return "figure.run.treadmill"
        case .nature:
            return "tree"
        case .friends:
            return "figure.2.arms.open"
        }
    }
    
    private func reflectionTypeName(_ type: ReflectionOptions) -> String {
        switch type {
        case .breaths:
            return "Mindful Breaths"
        case .taps:
            return "Cross Body Taps"
        case .visualization:
            return "Visualization"
        case .exercise:
            return "Exercise"
        case .nature:
            return "Time in Nature"
        case .friends:
            return "Talk with Friend(s)"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d min %d sec", minutes, seconds)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
    }
}

struct HeartRateGraph: View {
    @State private var part1Label = "Student Stress"
    @State private var part2Label = "Heart Racing"
    @State private var part3Label = "Mindful Breaths"
    
    var body: some View {
        VStack(spacing: 16) {
            // Graph
            graphView
                .frame(height: 250)
            
            // Larger text fields below
            VStack(spacing: 12) {
                HStack {
                    Text("What triggered this response?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    TextField("Label", text: $part1Label)
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                }
                
                HStack {
                    Text("What was your body's immediate reaction?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    TextField("Label", text: $part2Label)
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                }
                
                HStack {
                    Text("How did you choose to respond?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    TextField("Label", text: $part3Label)
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                }
            }
        }
    }
    
    private var graphView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                
                // Heart rate line
                Path { path in
                    let width = geometry.size.width - 32
                    let height = geometry.size.height - 80
                    let startX: CGFloat = 16
                    let startY: CGFloat = 60
                    
                    // Section 1: High heart rate (elevated, fluctuating)
                    path.move(to: CGPoint(x: startX, y: startY + height * 0.2))
                    
                    for i in 0...20 {
                        let x = startX + (width / 3) * (CGFloat(i) / 20)
                        let baseY = startY + height * 0.2
                        let variation = sin(Double(i) * 0.8) * 15
                        path.addLine(to: CGPoint(x: x, y: baseY + variation))
                    }
                    
                    // Section 2: Slightly lower heart rate
                    let section2Start = startX + width / 3
                    for i in 0...20 {
                        let x = section2Start + (width / 3) * (CGFloat(i) / 20)
                        let baseY = startY + height * 0.35
                        let variation = sin(Double(i) * 0.8) * 12
                        path.addLine(to: CGPoint(x: x, y: baseY + variation))
                    }
                    
                    // Section 3: Declining heart rate
                    let section3Start = startX + 2 * width / 3
                    for i in 0...20 {
                        let x = section3Start + (width / 3) * (CGFloat(i) / 20)
                        let progress = CGFloat(i) / 20
                        let baseY = startY + height * (0.35 + progress * 0.4)
                        let variation = sin(Double(i) * 0.8) * (12.0 - progress * 8)
                        path.addLine(to: CGPoint(x: x, y: baseY + variation))
                    }
                }
                .stroke(Color.red.opacity(0.8), style: StrokeStyle(lineWidth: 2.5, dash: [6, 6]))
                
                // Section dividers
                Path { path in
                    let width = geometry.size.width - 32
                    let height = geometry.size.height - 80
                    let startX: CGFloat = 16
                    let startY: CGFloat = 60
                    
                    // Divider 1
                    let div1X = startX + width / 3
                    path.move(to: CGPoint(x: div1X, y: startY))
                    path.addLine(to: CGPoint(x: div1X, y: startY + height))
                    
                    // Divider 2
                    let div2X = startX + 2 * width / 3
                    path.move(to: CGPoint(x: div2X, y: startY))
                    path.addLine(to: CGPoint(x: div2X, y: startY + height))
                }
                .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 1, dash: [5]))
                
                // Annotations
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        // Gear 1 annotation
                        VStack(spacing: 4) {
                            Text("Trigger")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.9))
                            Text(part1Label)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Gear 2 annotation
                        VStack(spacing: 4) {
                            Text("Reaction")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.9))
                            Text(part2Label)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Gear 3 annotation
                        VStack(spacing: 4) {
                            Text("Response")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.9))
                            Text(part3Label)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(session: Session(
            id: UUID(),
            timestamp: Date(),
            duration: 600,
            reflectionType: .breaths
        ))
    }
}
