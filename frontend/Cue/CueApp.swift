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
    @StateObject private var variantManager = VariantManager()
    @StateObject private var sessionManager = SessionManager()
    
    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .environmentObject(workoutManager)
                .environmentObject(variantManager)
                .environmentObject(sessionManager)
                .onAppear {
                    workoutManager.variantManager = variantManager
                    sessionManager.variantManager = variantManager
                    WatchConnectivityManager.shared.onSessionRecorded = {
                        Task {
                            await sessionManager.loadSessionCount()
                        }
                    }
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        _ = WatchConnectivityManager.shared
        return true
    }
}
