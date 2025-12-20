//
//  WorkoutManager.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import Foundation
import HealthKit
import Combine

class WorkoutManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    var variantManager: VariantManager?
    private let backendService = BackendService.shared

    func startWorkout() {
        guard session == nil else {
            print("Not starting workout due to existing session.")
            return
        }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            return
        }

        guard let session = session else {
            return
        }
        
        session.delegate = self
        builder?.delegate = self
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: configuration)
        let startDate = Date()
        session.startActivity(with: startDate)
        
        builder?.beginCollection(withStart: startDate) { (success, error) in
            if let error = error {
                print("Failed to begin workout collection: \(error.localizedDescription)")
            }
        }
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let typesToShare: Set<HKSampleType> = [
            HKQuantityType.workoutType()
        ]

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                completion(success)
        }
    }

    // MARK: - Session State Control
    @Published var running = false

    func stopWorkout() {
        guard session != nil else { return }
        recordSession(duration: builder?.elapsedTime ?? 0)
    }

    // MARK: - Workout Metrics
    @Published var averageHeartRate: Double = 0
    @Published var heartRate: Double = 0
    @Published var hrv: Double = 0

    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }

        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN):
                let sdnnUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.hrv = statistics.mostRecentQuantity()?.doubleValue(for: sdnnUnit) ?? 0
            default:
                return
            }
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        let isRunning = toState == .running
        DispatchQueue.main.async {
            self.running = isRunning
        }
        
        if toState == .stopped {
            builder?.discardWorkout()
            session?.end()
            
            DispatchQueue.main.async {
                self.builder = nil
                self.session = nil
                self.averageHeartRate = 0
                self.heartRate = 0
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("HKWorkoutSessionDelegate: workoutSession(_:didFailWithError:) \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.running = false
            self.builder = nil
            self.session = nil
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return 
            }

            let statistics = workoutBuilder.statistics(for: quantityType)
            updateForStatistics(statistics)
        }
    }
    
    private func recordSession(duration: TimeInterval) {
        guard let userId = variantManager?.appleUserId else {
            print("Cannot record session: userId not available")
            return
        }
        
        let sessionData: [String: Any] = [
            "userId": userId,
            "duration": duration,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        backendService.post(path: "/api/sessions", body: sessionData) { result in
            switch result {
            case .success:
                WatchConnectivityManager.shared.notifySessionRecorded()
                self.session?.stopActivity(with: nil)
            case .failure(let error):
                print("Failed to record session: \(error.localizedDescription)")
                self.session?.stopActivity(with: nil)
            }
        }
    }
}

