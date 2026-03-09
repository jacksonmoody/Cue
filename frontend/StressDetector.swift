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

class StressDetector {
    private let healthStore = HKHealthStore()
    private let motionActivityManager = CMMotionActivityManager()
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
    // 60% of motion events need to be still (with high confidence) to be classified as "still"
    private let motionStillnessThreshold = 0.6
    // For 15 minutes after the reflection notification is triggered, the notification will not be triggered again
    private let notificationCooldown: TimeInterval = 15 * 60
    // For 1 hour after a reflection session is completed, the notification will not be triggered again
    private let postSessionLockout: TimeInterval = 60 * 60

    private(set) var detectorState: StressDetectionState = .idle
    private var baselineRestingHR: Double?
    private var lastBaselineUpdateDate: Date?
    private var lastNotificationAt: Date?
    private var lastSessionCompletedAt: Date?
    private var recentMotionActivities: [(date: Date, isStationary: Bool)] = []
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
        startMotionUpdates()
        Task { await updateBaselineIfNeeded() }
    }

    func stopMonitoring() {
        isMonitoring = false
        motionActivityManager.stopActivityUpdates()
        recentMotionActivities.removeAll()
        detectorState = .idle
        persistState()
    }

    func processHeartRateUpdate(currentHR: Double) {
        guard isMonitoring else { return }
        guard let baseline = baselineRestingHR else { return }

        let now = Date()

        if case .cooldown(let until) = detectorState, now >= until {
            detectorState = .idle
        }

        let hrThreshold = max(baseline + hrElevationAbsolute, baseline * (1 + hrElevationPercent))
        let isElevated = currentHR >= hrThreshold
        let isStill = checkStillness()
        print(currentHR, hrThreshold, isStill)

        switch detectorState {
        case .idle:
            if isElevated && isStill {
                detectorState = .candidate(start: now)
            }

        case .candidate(let start):
            if !(isElevated && isStill) {
                detectorState = .idle
                return
            }

            if now.timeIntervalSince(start) >= requiredElevatedDuration {
                // Check cooldowns before triggering
                if let lastNotif = lastNotificationAt, now.timeIntervalSince(lastNotif) < notificationCooldown {
                    return
                }
                if let lastSession = lastSessionCompletedAt, now.timeIntervalSince(lastSession) < postSessionLockout {
                    return
                }
                trigger(currentHR: currentHR, baseline: baseline, at: now)
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

        if true {
//        if variantManager?.variant == 1 {
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

    private func startMotionUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        motionActivityManager.startActivityUpdates(to: queue) { [weak self] activity in
            guard let self, let activity else { return }
            DispatchQueue.main.async {
                self.recentMotionActivities.append((date: activity.startDate, isStationary: activity.stationary))
                let cutoff = Date().addingTimeInterval(-self.motionWindowDuration)
                self.recentMotionActivities.removeAll { $0.date < cutoff }
                print(self.recentMotionActivities)
            }
        }
    }

    private func checkStillness() -> Bool {
        guard !recentMotionActivities.isEmpty else { return false }
        let stationaryCount = recentMotionActivities.filter(\.isStationary).count
        let ratio = Double(stationaryCount) / Double(recentMotionActivities.count)
        print("ratio: ", ratio)
        return ratio >= motionStillnessThreshold
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
