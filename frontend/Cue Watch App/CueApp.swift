//
//  CueApp.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/14/25.
//

import SwiftUI
import WatchKit
import UserNotifications
import HealthKit

@main
struct Cue_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(WatchDelegate.self) var delegate
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var variantManager = VariantManager()
    @State private var navigationRouter = NavigationRouter()
    
    var body: some Scene {
        WindowGroup {
             RootView()
                .onAppear {
                    workoutManager.variantManager = variantManager
                    delegate.workoutManager = workoutManager
                    if delegate.launchedFromNotification {
                        print("User launched app from local notification")
                        navigationRouter.navigateToGear1()
                    }
                }
                .environmentObject(workoutManager)
                .environmentObject(variantManager)
                .environment(navigationRouter)
        }
    }
}

class WatchDelegate: NSObject, WKApplicationDelegate {
    weak var workoutManager: WorkoutManager?
    var launchedFromNotification = false

    func applicationDidFinishLaunching() {
        _ = WatchConnectivityManager.shared
    }

    func didReceive(_ notification: UNNotification) {
        launchedFromNotification = true
    }
    
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            workoutManager?.startWorkout()
        }
    }
}


