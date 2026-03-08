//
//  HeartRateDetailView.swift
//  Cue
//
//  Created by Jackson Moody on 3/8/26.
//

import SwiftUI
import Charts

private struct TriggerGroup: Decodable {
    let group: String
    let triggers: [String]
}

struct HeartRateDetailView: View {
    let sessions: [Session]
    let allSamples: [HeartRateComputation.RawNormalizedSample]

    @State private var overallData: [NormalizedHRPoint] = []
    @State private var byGear3Data: [NormalizedHRPoint] = []
    @State private var byGear1Data: [NormalizedHRPoint] = []
    @State private var loading = true

    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(.all)

            if loading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        chartSection(
                            title: "Overall Trend",
                            subtitle: "Average heart rate across all sessions.",
                            data: overallData,
                            multiSeries: false
                        )

                        Divider().background(.white)

                        chartSection(
                            title: "Grouped by Reflection Method",
                            subtitle: "Average heart rate during reflection, grouped by reflection method chosen.",
                            data: byGear3Data,
                            multiSeries: true
                        )

                        Divider().background(.white)

                        chartSection(
                            title: "Grouped by Trigger",
                            subtitle: "Average heart rate during reflection, grouped by reflection trigger.",
                            data: byGear1Data,
                            multiSeries: true
                        )
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Reflection Trends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await computeGraphData()
            loading = false
        }
    }

    private func computeGraphData() async {
        let beforeSamples = allSamples.filter { $0.normalizedTime < 1.0 }
        let afterSamples = allSamples.filter { $0.normalizedTime >= 1.0 }

        overallData = HeartRateComputation.binSamples(allSamples)

        // Graph 2: single averaged line before, split by gear 3 choice after
        byGear3Data = HeartRateComputation.binSamples(beforeSamples, series: "Average")
            + HeartRateComputation.binSamplesGrouped(afterSamples, groupBy: \.gear3Text)

        // Graph 3: split by gear 1 trigger before, single averaged line after
        let uniqueTriggers = Set(allSamples.compactMap(\.gear1Text))

        if uniqueTriggers.count > 5 {
            if let mapping = await fetchTriggerGroupMapping(triggers: Array(uniqueTriggers)) {
                byGear1Data = HeartRateComputation.binSamplesGroupedWithMapping(
                        beforeSamples, keyPath: \.gear1Text, mapping: mapping)
                    + HeartRateComputation.binSamples(afterSamples, series: "Average")
                return
            }
        }

        byGear1Data = HeartRateComputation.binSamplesGrouped(beforeSamples, groupBy: \.gear1Text)
            + HeartRateComputation.binSamples(afterSamples, series: "Average")
    }

    private func fetchTriggerGroupMapping(triggers: [String]) async -> [String: String]? {
        do {
            let body: [String: Any] = ["triggers": triggers]
            let groups = try await BackendService.shared.post(
                path: "/group-triggers",
                body: body,
                responseType: [TriggerGroup].self
            )
            var mapping: [String: String] = [:]
            for group in groups {
                for trigger in group.triggers {
                    mapping[trigger] = group.group
                }
            }
            return mapping
        } catch {
            print("Failed to fetch trigger groupings: \(error.localizedDescription)")
            return nil
        }
    }

    @ViewBuilder
    private func chartSection(
        title: String,
        subtitle: String,
        data: [NormalizedHRPoint],
        multiSeries: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            if data.isEmpty {
                Text("Not enough data.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
            } else {
                InteractiveNormalizedChart(data: data, multiSeries: multiSeries)
                    .frame(height: 250)
                if multiSeries {
                    ChartLegend(data: data)
                }
            }
        }
    }
}

private struct InteractiveNormalizedChart: View {
    let data: [NormalizedHRPoint]
    let multiSeries: Bool
    @State private var selectedPoints: [NormalizedHRPoint] = []

    private var minHR: Double { (data.map(\.avgHR).min() ?? 60) - 5 }
    private var maxHR: Double { (data.map(\.avgHR).max() ?? 100) + 5 }
    private var seriesNames: [String] { Array(Set(data.map(\.series))).sorted() }

    var body: some View {
        chart
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    selectedPoints = findNearestPoints(
                                        at: value.location.x, proxy: proxy, geometry: geometry)
                                }
                                .onEnded { _ in
                                    selectedPoints = []
                                }
                        )
                }
            }
            .chartXScale(domain: 0...2)
            .chartYScale(domain: minHR...maxHR)
            .chartXAxis {
                AxisMarks(values: [0.0, 2.0]) { value in
                    AxisGridLine()
                        .foregroundStyle(.clear)
                    if let v = value.as(Double.self) {
                        AxisValueLabel(anchor: v < 1.0 ? .topLeading : .topTrailing) {
                            Text(v < 1.0 ? "Before Reflection" : "After Reflection")
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.3))
                    AxisTick()
                        .foregroundStyle(.white.opacity(0.5))
                    AxisValueLabel()
                        .foregroundStyle(.white)
                }
            }
            .chartYAxisLabel(alignment: .leading) {
                Text("BPM")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            .chartLegend(.hidden)
    }

    @ViewBuilder
    private var chart: some View {
        if multiSeries {
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Time", point.normalizedTime),
                        y: .value("Heart Rate", point.avgHR)
                    )
                    .foregroundStyle(by: .value("Series", point.series))
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Time", point.normalizedTime),
                        y: .value("Heart Rate", point.avgHR)
                    )
                    .foregroundStyle(by: .value("Series", point.series))
                    .symbolSize(20)
                }

                selectionMarks

                RuleMark(x: .value("Divider", 1.0))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            }
            .chartForegroundStyleScale(
                domain: seriesNames, range: colorsForSeries(seriesNames))
        } else {
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Time", point.normalizedTime),
                        y: .value("Heart Rate", point.avgHR)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Time", point.normalizedTime),
                        y: .value("Heart Rate", point.avgHR)
                    )
                    .foregroundStyle(.red)
                    .symbolSize(25)
                }

                selectionMarks

                RuleMark(x: .value("Divider", 1.0))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            }
        }
    }

    @ChartContentBuilder
    private var selectionMarks: some ChartContent {
        if let first = selectedPoints.first {
            RuleMark(x: .value("Selected", first.normalizedTime))
                .foregroundStyle(.white.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .annotation(
                    position: .top, spacing: 8,
                    overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(selectedPoints) { point in
                            HStack(spacing: 6) {
                                if multiSeries && point.series != "Average" {
                                    Circle()
                                        .fill(colorForSeries(point.series))
                                        .frame(width: 6, height: 6)
                                    Text("\(point.series): \(Int(point.avgHR)) BPM")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                } else {
                                    Text("\(Int(point.avgHR)) BPM")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black, in: RoundedRectangle(cornerRadius: 8))
                }

            ForEach(selectedPoints) { point in
                PointMark(
                    x: .value("Selected", point.normalizedTime),
                    y: .value("Heart Rate", point.avgHR)
                )
                .foregroundStyle(.white)
                .symbolSize(60)
            }
        }
    }

    private func findNearestPoints(
        at locationX: CGFloat, proxy: ChartProxy, geometry: GeometryProxy
    ) -> [NormalizedHRPoint] {
        guard let plotFrameAnchor = proxy.plotFrame else { return [] }
        let plotFrame = geometry[plotFrameAnchor]
        let relativeX = locationX - plotFrame.minX
        guard relativeX >= 0, relativeX <= plotFrame.width else { return [] }
        guard let time: Double = proxy.value(atX: relativeX) else { return [] }

        if multiSeries {
            let sameHalf = data.filter { time < 1.0 ? $0.normalizedTime < 1.0 : $0.normalizedTime >= 1.0 }
            let grouped = Dictionary(grouping: sameHalf) { $0.series }
            return grouped.compactMap { _, points in
                points.min(by: { abs($0.normalizedTime - time) < abs($1.normalizedTime - time) })
            }
            .sorted { $0.series < $1.series }
        } else {
            if let nearest = data.min(by: { abs($0.normalizedTime - time) < abs($1.normalizedTime - time) }) {
                return [nearest]
            }
            return []
        }
    }

    private func colorForSeries(_ series: String) -> Color {
        let colors = colorsForSeries(seriesNames)
        guard let index = seriesNames.firstIndex(of: series), index < colors.count else {
            return .white
        }
        return colors[index]
    }

    private func colorsForSeries(_ names: [String]) -> [Color] {
        let otherPalette: [Color] = [.cyan, .yellow, .green, .orange, .pink, .mint, .indigo, .purple, .teal]
        var otherIndex = 0
        return names.map { name in
            if name == "Average" {
                return .red
            } else {
                let color = otherPalette[otherIndex % otherPalette.count]
                otherIndex += 1
                return color
            }
        }
    }
}

private struct ChartLegend: View {
    let data: [NormalizedHRPoint]

    private var seriesNames: [String] { Array(Set(data.map(\.series))).sorted() }
    private var colors: [Color] {
        let otherPalette: [Color] = [.cyan, .yellow, .green, .orange, .pink, .mint, .indigo, .purple, .teal]
        var otherIndex = 0
        return seriesNames.map { name in
            if name == "Average" {
                return .red
            } else {
                let color = otherPalette[otherIndex % otherPalette.count]
                otherIndex += 1
                return color
            }
        }
    }

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(zip(seriesNames, colors)), id: \.0) { name, color in
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(name)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
