//
//  CueApp.swift
//  Cue
//
//  Created by Jackson Moody on 12/14/25.
//

import SwiftUI
import GoogleSignIn

@main
struct CueApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var variantManager = VariantManager()
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var locationService = LocationService()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(workoutManager)
                .environmentObject(variantManager)
                .environmentObject(sessionManager)
                .environmentObject(locationService)
                .onAppear {
                    workoutManager.variantManager = variantManager
                    sessionManager.variantManager = variantManager
                    WatchConnectivityManager.shared.onSessionRecorded = {
                        Task {
                            await sessionManager.loadSessionCount()
                        }
                    }
                    WatchConnectivityManager.shared.onSessionStateChanged = { isActive in
                        LiveActivityManager.shared.handleSessionStateChange(isActive)
                    }
                }
                .onOpenURL { url in
                  GIDSignIn.sharedInstance.handle(url)
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
