//
//  WorkoutManager.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import Foundation
import HealthKit
import Combine
import UserNotifications

struct SessionResponse: Decodable {
    let userId: String
    let duration: Double
    let variantSwitched: Bool
    let newVariant: Int?
    let newPhase: Int?
    let secondsLogged: Double?
    let experimentComplete: Bool?
}

enum WorkoutPurpose {
    case monitoring
    case reflection
}

class WorkoutManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    var variantManager: VariantManager?
    private let backendService = BackendService.shared
    var currentPurpose: WorkoutPurpose = .monitoring
    var resumeMonitoring = false
    private var reflectionCompletion: (() -> Void)?

    private enum PendingStopAction {
        case monitoringStop // Stop monitoring workout
        case transitionToReflection(monitoringDuration: TimeInterval) // Stop monitoring workout and start reflection workout
        case saveReflection // Save reflection workout
        case discardReflection // Discard reflection workout
    }

    private var pendingStopAction: PendingStopAction = .monitoringStop

    func startWorkout(purpose: WorkoutPurpose = .monitoring) {
        currentPurpose = purpose
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            print("Failed to create workout session: \(error.localizedDescription)")
            notifyWorkoutStartFailed()
            return
        }

        guard let session = session else {
            print("Failed to create workout session: session is nil")
            notifyWorkoutStartFailed()
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
                self.notifyWorkoutStartFailed()
            } else if !success {
                print("Failed to begin workout collection: unknown error")
                self.notifyWorkoutStartFailed()
            }
        }
    }

    func startReflectionWorkout() {
        if session != nil {
            resumeMonitoring = true
            pendingStopAction = .transitionToReflection(monitoringDuration: builder?.elapsedTime ?? 0)
            session?.stopActivity(with: nil)
        } else {
            resumeMonitoring = false
            startWorkout(purpose: .reflection)
        }
    }

    func endReflectionWorkout(completion: @escaping () -> Void = {}) {
        guard session != nil, currentPurpose == .reflection else {
            return
        }
        reflectionCompletion = completion
        pendingStopAction = .saveReflection
        session?.stopActivity(with: nil)
    }

    func cancelReflectionWorkout() {
        guard session != nil, currentPurpose == .reflection else { return }
        pendingStopAction = .discardReflection
        session?.stopActivity(with: nil)
    }
    
    private func notifyWorkoutStartFailed() {
        WatchConnectivityManager.shared.updateSessionState(false)
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let typesToShare: Set<HKSampleType> = [
            HKQuantityType.workoutType()
        ]

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                completion(success)
        }
    }

    func stopWorkout() {
        guard session != nil else { return }
        // If currently in a reflection workout, don't resume monitoring workout after it ends
        if currentPurpose == .reflection {
            resumeMonitoring = false
            WatchConnectivityManager.shared.updateSessionState(false)
            return
        }
        recordSession(duration: builder?.elapsedTime ?? 0)
    }

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

    func queryHeartRateDecline(from startDate: Date, to endDate: Date) async -> Double? {
        let hrType = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: hrType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate)])
        
        let results: [HKQuantitySample]
        do {
            results = try await descriptor.result(for: healthStore)
        } catch {
            print("Heart rate query failed: \(error)")
            return nil
        }
        let unit = HKUnit.count().unitDivided(by: .minute())
        guard let first = results.first, let last = results.last else {
            print("No heart rate samples found in range \(startDate) to \(endDate)")
            return nil
        }
        let firstHR = first.quantity.doubleValue(for: unit)
        let lastHR = last.quantity.doubleValue(for: unit)
        let decline = firstHR - lastHR
        return decline
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        if toState == .running && currentPurpose == .monitoring {
            WatchConnectivityManager.shared.updateSessionState(true)
        }
        
        if toState == .stopped {
            let action = pendingStopAction
            pendingStopAction = .monitoringStop // Default back to stopping monitoring workout

            switch action {
            case .transitionToReflection(let duration):
                cleanupWorkoutSession {
                    self.startWorkout(purpose: .reflection)
                }
                recordMonitoringDuration(duration)

            case .saveReflection:
                builder?.endCollection(withEnd: Date()) { success, error in
                    if let error = error {
                        print("Failed to end workout collection: \(error.localizedDescription)")
                    }
                    self.builder?.finishWorkout { workout, error in
                        if let error = error {
                            print("Failed to finish workout: \(error.localizedDescription)")
                        }
                        self.session?.end()
                        let completion = self.reflectionCompletion
                        self.reflectionCompletion = nil
                        completion?()
                        DispatchQueue.main.async {
                            self.builder = nil
                            self.session = nil
                            self.averageHeartRate = 0
                            self.heartRate = 0
                            self.currentPurpose = .monitoring
                            if self.resumeMonitoring {
                                self.resumeMonitoring = false
                                self.startWorkout(purpose: .monitoring)
                            }
                        }
                    }
                }

            case .discardReflection:
                cleanupWorkoutSession {
                    self.currentPurpose = .monitoring
                    if self.resumeMonitoring {
                        self.resumeMonitoring = false
                        self.startWorkout(purpose: .monitoring)
                    }
                }

            case .monitoringStop:
                WatchConnectivityManager.shared.updateSessionState(false)
                cleanupWorkoutSession()
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("HKWorkoutSessionDelegate: workoutSession(_:didFailWithError:) \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.pendingStopAction = .monitoringStop
            self.builder = nil
            self.session = nil
            WatchConnectivityManager.shared.updateSessionState(false)
        }
    }

    private func cleanupWorkoutSession(then completion: (() -> Void)? = nil) {
        builder?.discardWorkout()
        session?.end()
        DispatchQueue.main.async {
            self.builder = nil
            self.session = nil
            self.averageHeartRate = 0
            self.heartRate = 0
            completion?()
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
    
    private func recordMonitoringDuration(_ duration: TimeInterval) {
        guard let userId = variantManager?.appleUserId else { return }
        var sessionData: [String: Any] = [
            "userId": userId,
            "duration": duration,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        if let variant = variantManager?.variant {
            sessionData["variant"] = variant
        }
        backendService.post(path: "/sessions", body: sessionData) { _ in }
    }

    private func recordSession(duration: TimeInterval) {
        guard let userId = variantManager?.appleUserId else {
            print("Cannot record session: userId not available")
            return
        }
        
        var sessionData: [String: Any] = [
            "userId": userId,
            "duration": duration,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let variant = variantManager?.variant {
            sessionData["variant"] = variant
        }
        
        backendService.postWithResponse(path: "/sessions", body: sessionData, responseType: SessionResponse.self) { result in
            switch result {
            case .success(let response):
                WatchConnectivityManager.shared.notifySessionRecorded()
                if response.variantSwitched, let newVariant = response.newVariant, let newPhase = response.newPhase {
                    DispatchQueue.main.async {
                        self.variantManager?.switchVariant(newVariant: newVariant, newPhase: newPhase)
                        UserDefaults.standard.set(true, forKey: "instructionsNeeded")
                        UserDefaults.standard.set(true, forKey: "variantSwitchPending")
                    }
                    NotificationHelper.fireVariantSwitchNotification()
                    WatchConnectivityManager.shared.notifyVariantSwitched(newVariant: newVariant, newPhase: newPhase)
                }
                if response.experimentComplete == true {
                    WatchConnectivityManager.shared.notifyExperimentComplete()
                }
                self.session?.stopActivity(with: nil)
            case .failure(let error):
                print("Failed to record session: \(error.localizedDescription)")
                self.session?.stopActivity(with: nil)
            }
        }
    }
    
}

