//
//  CueApp.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/14/25.
//

import SwiftUI
import WatchKit
import UserNotifications

@main
struct Cue_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(WatchDelegate.self) var delegate
    @StateObject private var workoutManager = WorkoutManager()
    
    var body: some Scene {
        WindowGroup {
             OnboardingView()
                .onAppear {
                    if delegate.launchedFromNotification {
                        print("User launched app from local notification")
                    }
                }
                .environmentObject(workoutManager)
        }
    }
}

class WatchDelegate: NSObject, WKApplicationDelegate {
    var launchedFromNotification = false

    func applicationDidFinishLaunching() {
        _ = WatchConnectivityManager.shared
    }

    func didReceive(_ notification: UNNotification) {
        launchedFromNotification = true
    }
}


