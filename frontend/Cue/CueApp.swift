//
//  CueApp.swift
//  Cue
//
//  Created by Jackson Moody on 12/14/25.
//

import SwiftUI

@main
struct CueApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var workoutManager = WorkoutManager()
    
    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .environmentObject(workoutManager)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        _ = WatchConnectivityManager.shared
        return true
    }
}
