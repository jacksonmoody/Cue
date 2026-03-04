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
        .navigationTitle(session.title ?? "Reflection Details")
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
    @EnvironmentObject var reflectionManager: ReflectionManager
    
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
    @State private var loading: Bool = true
    @State private var selectedDataPoint: DataPoint?
    
    @FocusState private var part1Focused: Bool
    @FocusState private var part2Focused: Bool
    @FocusState private var part3Focused: Bool
    
    init(session: Session) {
        self.session = session
        _part1Label = State(initialValue: session.gear1?.text ?? "Unknown")
        _part2Label = State(initialValue: session.gear2?.text ?? "Unknown")
        _part3Label = State(initialValue: session.gear3?.text ?? "Unknown")
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if loading {
                ProgressView()
                    .frame(height: 300)
            } else if !data.isEmpty {
                graphView
                    .frame(height: 300)
            }
            VStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("What triggered this response?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    HStack(spacing: 10) {
                        Image(systemName: session.gear1?.icon ?? "")
                            .foregroundStyle(.white)
                        TextField("Label", text: $part1Label)
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline)
                            .focused($part1Focused)
                            .onChange(of: part1Focused) { _, isFocused in
                                if !isFocused {
                                    updateSession()
                                }
                            }
                            .onSubmit {
                                updateSession()
                            }
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("What was your body's immediate reaction?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    HStack(spacing: 10) {
                        Image(systemName: session.gear2?.icon ?? "")
                            .foregroundStyle(.white)
                        TextField("Label", text: $part2Label)
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline)
                            .focused($part2Focused)
                            .onChange(of: part2Focused) { _, isFocused in
                                if !isFocused {
                                    updateSession()
                                }
                            }
                            .onSubmit {
                                updateSession()
                            }
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("How did you choose to reflect?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    HStack(spacing: 10) {
                        Image(systemName: session.gear3?.icon ?? "")
                            .foregroundStyle(.white)
                        TextField("Label", text: $part3Label)
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline)
                            .focused($part3Focused)
                            .onChange(of: part3Focused) { _, isFocused in
                                if !isFocused {
                                    updateSession()
                                }
                            }
                            .onSubmit {
                                updateSession()
                            }
                    }
                }
            }
            .padding(.bottom)
            .task {
                defer { loading = false }
                await loadHRData()
            }
        }
    }
    
    private func findNearestDataPoint(at locationX: CGFloat, proxy: ChartProxy, geometry: GeometryProxy) -> DataPoint? {
        guard let plotFrameAnchor = proxy.plotFrame else { return nil }
        let plotFrame = geometry[plotFrameAnchor]
        let relativeX = locationX - plotFrame.minX
        guard relativeX >= 0, relativeX <= plotFrame.width else { return nil }
        guard let time: Double = proxy.value(atX: relativeX) else { return nil }
        return data.min(by: { abs($0.time - time) < abs($1.time - time) })
    }
    
    private var graphView: some View {
        let maxHr = data.map(\.hr).max() ?? 200
        let dataMinTime = data.map(\.time).min() ?? 0
        let dataMaxTime = data.map(\.time).max() ?? 0
        let gear1Time = session.gear1Finished?.timeIntervalSince(session.startDate)
        let gear3Time = session.gear3Started?.timeIntervalSince(session.startDate)
        let allTimes = [dataMinTime, dataMaxTime, gear1Time, gear3Time].compactMap { $0 }
        let xMin: Double = 0
        let xMax = (allTimes.max() ?? 0) + 5
        return Chart(data) { point in
            PointMark(
                x: .value("Time", point.time),
                y: .value("Heart Rate", point.hr)
            )
            .foregroundStyle(.red)
            .symbolSize(25)
            
            if let selected = selectedDataPoint, selected.id == point.id {
                RuleMark(x: .value("Time", selected.time))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, spacing: 8) {
                        VStack(spacing: 4) {
                            Text("\(Int(selected.hr)) BPM")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                            Text(formatDuration(selected.time))
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black, in: RoundedRectangle(cornerRadius: 8))
                    }
                
                PointMark(
                    x: .value("Time", selected.time),
                    y: .value("Heart Rate", selected.hr)
                )
                .foregroundStyle(.white)
                .symbolSize(60)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                selectedDataPoint = findNearestDataPoint(at: value.location.x, proxy: proxy, geometry: geometry)
                            }
                            .onEnded { _ in
                                selectedDataPoint = nil
                            }
                    )
                
                if let gear1Date = session.gear1Finished {
                    chartAnnotation(date: gear1Date, proxy: proxy, geometry: geometry, label: part1Label, startDate: session.startDate, offset: 20)
                }
                if let gear3Date = session.gear3Started {
                    chartAnnotation(date: gear3Date, proxy: proxy, geometry: geometry, label: part3Label, startDate: session.startDate, offset: 50)
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
                        Text(formatChartTime(seconds))
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
        .chartXScale(domain: xMin...xMax)
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
        let offset: CGFloat
        
        @State private var labelWidth: CGFloat = 0
        
        var body: some View {
            let targetTime = date.timeIntervalSince(startDate)
            if let xPos = proxy.position(forX: targetTime),
               let plotFrameAnchor = proxy.plotFrame {
                let plotFrame = geometry[plotFrameAnchor]
                let lineX = plotFrame.minX + xPos
                let lineHeight = plotFrame.height - offset - 10
                let halfLabel = labelWidth / 2
                let clampedLabelX = min(max(lineX, plotFrame.minX + halfLabel), plotFrame.maxX - halfLabel)
                ZStack {
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [2, 5]))
                        .foregroundStyle(.white)
                        .frame(width: 1.5, height: lineHeight)
                        .position(x: lineX, y: plotFrame.minY + offset + 10 + lineHeight / 2)
                    
                    Text(label)
                        .font(.caption)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
                        .onGeometryChange(for: CGFloat.self) { geo in
                            geo.size.width
                        } action: { newWidth in
                            labelWidth = newWidth
                        }
                        .position(x: clampedLabelX, y: plotFrame.minY + offset)
                }
            }
        }
    }
    
    private func loadHRData() async {
        guard let endDate = session.endDate else {
            return
        }
        do {
            let store = HKHealthStore()
            let hrType = HKQuantityType(.heartRate)
            let datePredicate = HKQuery.predicateForSamples(withStart: session.startDate, end: endDate, options: [])
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.quantitySample(type: hrType, predicate: datePredicate)],
                sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)])
            let results = try await descriptor.result(for: store)
            let hrUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            withAnimation {
                data = results.map { sample in
                    DataPoint(time: sample.startDate.timeIntervalSince(session.startDate), hr: sample.quantity.doubleValue(for: hrUnit))
                }
            }
        } catch {
            print("Error fetching HR data: \(error.localizedDescription)")
        }
    }
    private func updateSession() {
        var newSession = session
        newSession.gear1 = GearOption(text: part1Label, icon: session.gear1?.icon ?? "")
        newSession.gear2 = GearOption(text: part2Label, icon: session.gear2?.icon ?? "")
        newSession.gear3 = GearOption(text: part3Label, icon: session.gear3?.icon ?? "")
        reflectionManager.updateSession(newSession)
    }
}

fileprivate func formatChartTime(_ duration: TimeInterval) -> String {
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%d:%02d", minutes, seconds)
}

fileprivate func formatDuration(_ duration: TimeInterval) -> String {
    if duration == 0 { return "Incomplete" }
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%d min %d sec", minutes, seconds)
}

#Preview {
    NavigationStack {
        SessionDetailView(session: Session(startDate: Date()))
    }
}

