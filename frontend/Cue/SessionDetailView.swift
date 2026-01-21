//
//  SessionDetailView.swift
//  Cue
//
//  Created by Jackson Moody on 1/20/26.
//

import SwiftUI
import Charts
import HealthKit

struct SessionDetailView: View {
    let session: Session
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: "Date & Time", value: formatDate(session.startDate))
                        DetailRow(label: "Duration", value: formatDuration(session.duration))
                    }
                    .padding(.horizontal)
                    VStack(alignment: .leading, spacing: 12) {
                        HeartRateGraph(session: session)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
    }
}

struct HeartRateGraph: View {
    struct DataPoint: Identifiable {
        var time: Double
        var hr: Double
        var id = UUID()
    }
    
    let session: Session
    @State private var part1Label: String = ""
    @State private var part2Label: String = ""
    @State private var part3Label: String = ""
    @State private var data: [DataPoint] = []
    
    init(session: Session) {
        self.session = session
        _part1Label = State(initialValue: session.gear1.text)
        _part2Label = State(initialValue: session.gear2.text)
        _part3Label = State(initialValue: session.gear3.text)
        _data = State(initialValue: HeartRateGraph.makeFakeData(for: session))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            graphView
                .frame(height: 300)
            VStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("What triggered this response?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    TextField("Label", text: $part1Label)
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                }
                
                VStack(alignment: .leading) {
                    Text("What was your body's immediate reaction?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    TextField("Label", text: $part2Label)
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                }
                
                VStack(alignment: .leading) {
                    Text("How did you choose to respond?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    TextField("Label", text: $part3Label)
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                }
            }
            .task {
                await loadHRData()
            }
        }
    }
    
    private var graphView: some View {
        let maxHr = data.map(\.hr).max() ?? 200
        return Chart(data) { point in
            PointMark(
                x: .value("Time", point.time),
                y: .value("Heart Rate", point.hr)
            )
            .foregroundStyle(.red)
            .symbolSize(10)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let gear1Date = session.gear1Finished {
                    chartAnnotation(date: gear1Date, proxy: proxy, geometry: geometry, label: part1Label, startDate: session.startDate)
                }
                // Gear 2 end date is equivalent to gear 3 start date (annotated here)
                if let gear2Date = session.gear2Finished {
                    chartAnnotation(date: gear2Date, proxy: proxy, geometry: geometry, label: part3Label, startDate: session.startDate)
                }
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisGridLine()
                    .foregroundStyle(.white.opacity(0.5))
                AxisTick()
                    .foregroundStyle(.white.opacity(0.5))
                AxisValueLabel {
                    if let seconds = value.as(Double.self) {
                        Text(formatDuration(seconds))
                    }
                }
                .foregroundStyle(.white)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                    .foregroundStyle(.white.opacity(0.7))
                AxisTick()
                    .foregroundStyle(.white.opacity(0.7))
                AxisValueLabel()
                    .foregroundStyle(.white)
            }
        }
        .chartYAxisLabel(alignment: .leading) {
            Text("Heart Rate (BPM)")
                .font(Font.caption.bold())
                .foregroundStyle(.white)
        }
        .chartYScale(domain: [30, maxHr + 20])
        .chartXAxisLabel(alignment: .center) {
            Text("Time")
                .font(Font.caption.bold())
                .foregroundStyle(.white)
        }
    }
    
    private struct chartAnnotation: View {
        let date: Date
        let proxy: ChartProxy
        let geometry: GeometryProxy
        let label: String
        let startDate: Date
        
        var body: some View {
            let targetTime = date.timeIntervalSince(startDate)
            if let xPos = proxy.position(forX: targetTime),
               let plotFrameAnchor = proxy.plotFrame {
                let plotFrame = geometry[plotFrameAnchor]
                let topOffset: CGFloat = 20
                let lineHeight = plotFrame.height - topOffset
                VStack(spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .padding(3)
                        .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [2, 5]))
                        .foregroundStyle(.white)
                        .frame(width: 1.5, height: lineHeight)
                }
                .position(x: plotFrame.minX + xPos, y: plotFrame.minY + topOffset + lineHeight / 2)
            }
        }
    }
    
    private static func makeFakeData(for session: Session) -> [DataPoint] {
        // Generate a sine curve for heart rate data
        let totalDuration = min(session.endDate?.timeIntervalSince(session.startDate) ?? 0, 60)
        let sampleCount = min(Int(totalDuration), 90)
        let baselineHR = 85.0
        let amplitude = 25.0
        let frequency = 2.0 // Number of complete cycles
        
        var points: [DataPoint] = []
        points.reserveCapacity(sampleCount)
        
        for i in 0..<sampleCount {
            let t = Double(i) / Double(sampleCount - 1)
            
            // Sine wave: baseline + amplitude * sin(2π * frequency * t)
            let hrBase = baselineHR + amplitude * sin(2 * .pi * frequency * t)
            
            // Add small random noise
            let noise = Double.random(in: -2...2)
            let hr = max(50, hrBase + noise)
            
            let time = t * totalDuration
            points.append(DataPoint(time: time, hr: hr))
        }
        
        return points
    }
    
    private func loadHRData() async {
        do {
            let store = HKHealthStore()
            let hrType = HKQuantityType(.heartRate)
            let datePredicate = HKQuery.predicateForSamples(withStart: session.startDate, end: session.endDate, options: [])
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.quantitySample(type: hrType, predicate: datePredicate)],
                sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)])
            let results = try await descriptor.result(for: store)
            data = results.map { sample in
                DataPoint(time: sample.startDate.timeIntervalSince(session.startDate), hr: sample.quantity.doubleValue(for: .count()))
            }
        } catch {
            print("Error fetching HR data: \(error.localizedDescription)")
        }
    }
}

fileprivate func formatDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%d min %d sec", minutes, seconds)
}

#Preview {
    NavigationStack {
        SessionDetailView(session: Session(id: UUID(), startDate: .now, gear1Finished: .now + 14, gear2Finished: .now + 50, endDate: .now + 650, gear1: .init(text: "11am Thesis Meeting", icon: "calendar"), gear2: .init(text:"Heart Racing", icon: "heart"), gear3: .init(text:"Mindful Breaths", icon: "lungs")))
    }
}

