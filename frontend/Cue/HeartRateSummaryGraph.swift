//
//  HeartRateSummaryGraph.swift
//  Cue
//
//  Created by Jackson Moody on 3/8/26.
//

import SwiftUI
import Charts
import HealthKit

struct NormalizedHRPoint: Identifiable {
    let id = UUID()
    let normalizedTime: Double
    let avgHR: Double
    let series: String
}

struct HeartRateComputation {
    static let binsPerHalf = 20
    static let totalBins = binsPerHalf * 2
    static let binWidth = 2.0 / Double(totalBins)

    struct RawNormalizedSample {
        let normalizedTime: Double
        let hr: Double
        let gear1Text: String?
        let gear3Text: String?
    }

    static func loadNormalizedSamples(for sessions: [Session]) async -> [RawNormalizedSample] {
        let store = HKHealthStore()
        let hrType = HKQuantityType(.heartRate)
        let hrUnit = HKUnit.count().unitDivided(by: HKUnit.minute())

        let validSessions = sessions.filter { $0.gear3Started != nil && $0.endDate != nil }

        return await withTaskGroup(of: [RawNormalizedSample].self) { group in
            for session in validSessions {
                group.addTask {
                    guard let gear3Started = session.gear3Started,
                          let endDate = session.endDate else { return [] }

                    let datePredicate = HKQuery.predicateForSamples(
                        withStart: session.startDate, end: endDate, options: [])
                    let descriptor = HKSampleQueryDescriptor(
                        predicates: [.quantitySample(type: hrType, predicate: datePredicate)],
                        sortDescriptors: [SortDescriptor(\.endDate, order: .forward)])

                    guard let results = try? await descriptor.result(for: store) else { return [] }

                    let beforeDuration = gear3Started.timeIntervalSince(session.startDate)
                    let afterDuration = endDate.timeIntervalSince(gear3Started)

                    guard beforeDuration > 0, afterDuration > 0 else { return [] }

                    return results.compactMap { sample in
                        let sampleTime = sample.startDate.timeIntervalSince(session.startDate)
                        let hr = sample.quantity.doubleValue(for: hrUnit)
                        let normalizedTime: Double

                        if sampleTime <= beforeDuration {
                            normalizedTime = sampleTime / beforeDuration
                        } else {
                            let afterTime = sampleTime - beforeDuration
                            normalizedTime = 1.0 + (afterTime / afterDuration)
                        }

                        return RawNormalizedSample(
                            normalizedTime: min(normalizedTime, 2.0),
                            hr: hr,
                            gear1Text: session.gear1?.text,
                            gear3Text: session.gear3?.text
                        )
                    }
                }
            }

            var allSamples: [RawNormalizedSample] = []
            for await batch in group {
                allSamples.append(contentsOf: batch)
            }
            return allSamples
        }
    }

    static func binSamples(_ samples: [RawNormalizedSample], series: String = "Average") -> [NormalizedHRPoint] {
        var bins: [[Double]] = Array(repeating: [], count: totalBins)

        for sample in samples {
            let binIndex = min(Int(sample.normalizedTime / binWidth), totalBins - 1)
            bins[binIndex].append(sample.hr)
        }

        return bins.enumerated().compactMap { index, values in
            guard !values.isEmpty else { return nil }
            let avg = values.reduce(0, +) / Double(values.count)
            let time = (Double(index) + 0.5) * binWidth
            return NormalizedHRPoint(normalizedTime: time, avgHR: avg, series: series)
        }
    }

    static func binSamplesGrouped(
        _ samples: [RawNormalizedSample],
        groupBy keyPath: KeyPath<RawNormalizedSample, String?>
    ) -> [NormalizedHRPoint] {
        let grouped = Dictionary(grouping: samples) { $0[keyPath: keyPath] ?? "Unknown" }
        return grouped.flatMap { key, groupSamples in
            binSamples(groupSamples, series: key)
        }
    }

    static func binSamplesGroupedWithMapping(
        _ samples: [RawNormalizedSample],
        keyPath: KeyPath<RawNormalizedSample, String?>,
        mapping: [String: String]
    ) -> [NormalizedHRPoint] {
        let grouped = Dictionary(grouping: samples) { sample -> String in
            let key = sample[keyPath: keyPath] ?? "Unknown"
            return mapping[key] ?? key
        }
        return grouped.flatMap { key, groupSamples in
            binSamples(groupSamples, series: key)
        }
    }
}

struct HeartRateSummaryGraph: View {
    let sessions: [Session]
    @State private var data: [NormalizedHRPoint] = []
    @State private var allSamples: [HeartRateComputation.RawNormalizedSample] = []
    @State private var loading = true

    var body: some View {
        NavigationLink {
            HeartRateDetailView(sessions: sessions, allSamples: allSamples)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Reflection Trends")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                if loading {
                    ProgressView()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                } else if data.isEmpty {
                    Text("Not enough data to display trends.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                } else {
                    chartView
                        .frame(height: 200)
                }
            }
            .padding(.vertical, 8)
        }
        .task {
            allSamples = await HeartRateComputation.loadNormalizedSamples(for: sessions)
            withAnimation {
                data = HeartRateComputation.binSamples(allSamples)
            }
            loading = false
        }
    }

    private var chartView: some View {
        let minHR = (data.map(\.avgHR).min() ?? 60) - 5
        let maxHR = (data.map(\.avgHR).max() ?? 100) + 5

        return Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("Time", point.normalizedTime),
                    y: .value("Heart Rate", point.avgHR)
                )
                .foregroundStyle(.red)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Time", point.normalizedTime),
                    y: .value("Heart Rate", point.avgHR)
                )
                .foregroundStyle(.red)
                .symbolSize(20)
            }

            RuleMark(x: .value("Divider", 1.0))
                .foregroundStyle(.white.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
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
                .font(.caption2.bold())
                .foregroundStyle(.white)
        }
    }
}
