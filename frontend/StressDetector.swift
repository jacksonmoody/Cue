//
//  StressDetector.swift
//  Cue
//
//  Created by Jackson Moody on 3/8/26.
//

import Foundation
import HealthKit
import CoreMotion
import UserNotifications
import Combine

enum StressDetectionState: Codable {
    case idle
    case candidate(start: Date)
    case cooldown(until: Date)
}

@MainActor
class StressDetector {
    private let healthStore = HKHealthStore()
    private let pedometer = CMPedometer()
    private let backendService = BackendService.shared

    weak var variantManager: VariantManager?

    // Take resting HR samples over the past week
    private let baselineWindow = 7
    // HR needs to be 20 BPM above baseline to trigger notification
    private let hrElevationAbsolute = 20.0
    // Or HR needs to be elevated 30% above baseline
    private let hrElevationPercent = 0.3
    // Need 1 minute of elevated heart rate and stillness for the reflection notification to be triggered
    private let requiredElevatedDuration: TimeInterval = 1 * 60
    // Need 5 minutes of stillness for the reflection notification to be triggered
    private let motionWindowDuration: TimeInterval = 5 * 60
    // Fewer than 20 steps in the motion window counts as still
    private let pedometerStepThreshold = 20
    // For 1 hour after the reflection notification is triggered, the notification will not be triggered again
    private let notificationCooldown: TimeInterval = 60 * 60
    // For 1 hour after a reflection session is completed, the notification will not be triggered again
    private let postSessionLockout: TimeInterval = 60 * 60
    // Fallback absolute HR threshold when no baseline is available
    private let fallbackHRThreshold = 90.0
    // Candidate state expires after 5 minutes with no confirming HR update
    private let candidateTimeout: TimeInterval = 5 * 60
    // Cache stillness result for 30 seconds to avoid excessive pedometer queries
    private let stillnessCacheDuration: TimeInterval = 30

    private(set) var detectorState: StressDetectionState = .idle
    private var baselineRestingHR: Double?
    private var lastBaselineUpdateDate: Date?
    private var lastNotificationAt: Date?
    private var lastSessionCompletedAt: Date?
    private var cachedStillness: Bool?
    private var lastStillnessCheckDate: Date?
    private var isMonitoring = false

    private let stateKey = "stressDetectorState"
    private let baselineKey = "stressDetectorBaseline"
    private let baselineDateKey = "stressDetectorBaselineDate"
    private let lastNotificationKey = "stressDetectorLastNotification"
    private let lastSessionCompletedKey = "stressDetectorLastSessionCompleted"

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        loadPersistedState()
        Task { await updateBaselineIfNeeded() }
    }

    func stopMonitoring() {
        isMonitoring = false
        detectorState = .idle
        persistState()
    }

    func processHeartRateUpdate(currentHR: Double) async {
        guard isMonitoring else { return }

        let now = Date()
        let baseline = baselineRestingHR

        if case .cooldown(let until) = detectorState, now >= until {
            detectorState = .idle
        }

        let hrThreshold: Double
        if let baseline {
            hrThreshold = max(baseline + hrElevationAbsolute, baseline * (1 + hrElevationPercent))
        } else {
            hrThreshold = fallbackHRThreshold
        }

        let isElevated = currentHR >= hrThreshold
        let isStill = await checkStillness()

        switch detectorState {
        case .idle:
            if isElevated && isStill {
                detectorState = .candidate(start: now)
            }

        case .candidate(let start):
            if now.timeIntervalSince(start) > candidateTimeout {
                detectorState = .idle
                return
            }

            if !(isElevated && isStill) {
                detectorState = .idle
                return
            }

            if now.timeIntervalSince(start) >= requiredElevatedDuration {
                if let lastNotif = lastNotificationAt, now.timeIntervalSince(lastNotif) < notificationCooldown {
                    detectorState = .idle
                } else if let lastSession = lastSessionCompletedAt, now.timeIntervalSince(lastSession) < postSessionLockout {
                    detectorState = .idle
                } else {
                    trigger(currentHR: currentHR, baseline: baseline ?? fallbackHRThreshold, at: now)
                }
            }

        case .cooldown:
            break
        }

        persistState()
    }

    func recordSessionCompletion() {
        lastSessionCompletedAt = Date()
        persistState()
    }

    private func trigger(currentHR: Double, baseline: Double, at now: Date) {
        lastNotificationAt = now
        detectorState = .cooldown(until: now.addingTimeInterval(notificationCooldown))
        persistState()

        logTriggerToBackend(currentHR: currentHR, baseline: baseline, triggeredAt: now)

        if variantManager?.variant == 1 {
            NotificationHelper.fireStressTriggerNotification()
        }
    }

    private func logTriggerToBackend(currentHR: Double, baseline: Double, triggeredAt: Date) {
        guard let userId = variantManager?.appleUserId else { return }
        let variant = variantManager?.variant

        var body: [String: Any] = [
            "userId": userId,
            "triggeredAtTime": ISO8601DateFormatter().string(from: triggeredAt),
            "heartRate": currentHR,
            "baseline": baseline
        ]
        if let variant {
            body["variant"] = variant
        }

        backendService.post(path: "/triggers", body: body) { result in
            if case .failure(let error) = result {
                print("Failed to log trigger: \(error.localizedDescription)")
            }
        }
    }

    private func updateBaselineIfNeeded() async {
        // Only update the baseline if it's been more than one day since the last update
        if let lastUpdate = lastBaselineUpdateDate,
           Calendar.current.isDateInToday(lastUpdate),
           baselineRestingHR != nil {
            return
        }

        let restingHRType = HKQuantityType(.restingHeartRate)
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -baselineWindow, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: restingHRType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: baselineWindow
        )

        do {
            let samples = try await descriptor.result(for: healthStore)
            guard !samples.isEmpty else { return }

            let unit = HKUnit.count().unitDivided(by: .minute())
            let values = samples.map { $0.quantity.doubleValue(for: unit) }.sorted()
            let median: Double
            if values.count % 2 == 0 {
                median = (values[values.count / 2 - 1] + values[values.count / 2]) / 2.0
            } else {
                median = values[values.count / 2]
            }
            baselineRestingHR = median
            lastBaselineUpdateDate = now
            persistState()
        } catch {
            print("Failed to query resting heart rate: \(error.localizedDescription)")
        }
    }

    private func checkStillness() async -> Bool {
        let now = Date()
        if let cached = cachedStillness,
           let lastCheck = lastStillnessCheckDate,
           now.timeIntervalSince(lastCheck) < stillnessCacheDuration {
            return cached
        }

        guard CMPedometer.isStepCountingAvailable() else { return false }
        let steps = await queryRecentSteps()
        guard let steps else { return false }

        let result = steps < pedometerStepThreshold
        cachedStillness = result
        lastStillnessCheckDate = now
        return result
    }

    private func queryRecentSteps() async -> Int? {
        let now = Date()
        let start = now.addingTimeInterval(-motionWindowDuration)
        return await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(from: start, to: now) { data, error in
                if let error {
                    print("Pedometer query failed: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                } else {
                    continuation.resume(returning: data?.numberOfSteps.intValue ?? 0)
                }
            }
        }
    }

    private func persistState() {
        let defaults = UserDefaults.standard
        if let encoded = try? JSONEncoder().encode(detectorState) {
            defaults.set(encoded, forKey: stateKey)
        }
        if let baseline = baselineRestingHR {
            defaults.set(baseline, forKey: baselineKey)
        }
        if let baselineDate = lastBaselineUpdateDate {
            defaults.set(baselineDate, forKey: baselineDateKey)
        }
        if let lastNotif = lastNotificationAt {
            defaults.set(lastNotif, forKey: lastNotificationKey)
        }
        if let lastSession = lastSessionCompletedAt {
            defaults.set(lastSession, forKey: lastSessionCompletedKey)
        }
    }

    private func loadPersistedState() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: stateKey),
           let state = try? JSONDecoder().decode(StressDetectionState.self, from: data) {
            detectorState = state
        }
        if defaults.object(forKey: baselineKey) != nil {
            baselineRestingHR = defaults.double(forKey: baselineKey)
        }
        lastBaselineUpdateDate = defaults.object(forKey: baselineDateKey) as? Date
        lastNotificationAt = defaults.object(forKey: lastNotificationKey) as? Date
        lastSessionCompletedAt = defaults.object(forKey: lastSessionCompletedKey) as? Date
    }
}
