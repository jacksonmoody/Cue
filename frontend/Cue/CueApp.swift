//
//  CueApp.swift
//  Cue
//
//  Created by Jackson Moody on 12/14/25.
//

import SwiftUI
import GoogleSignIn
import UserNotifications

@main
struct CueApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var variantManager = VariantManager()
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var locationService = LocationService()
    @StateObject private var reflectionManager = ReflectionManager()
    @StateObject private var tabController = TabController()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(workoutManager)
                .environmentObject(variantManager)
                .environmentObject(sessionManager)
                .environmentObject(locationService)
                .environmentObject(reflectionManager)
                .environmentObject(tabController)
                .onAppear {
                    workoutManager.variantManager = variantManager
                    sessionManager.variantManager = variantManager
                    reflectionManager.variantManager = variantManager
                    WatchConnectivityManager.shared.onSessionRecorded = {
                        Task {
                            await sessionManager.loadSessionCount()
                        }
                    }
                    WatchConnectivityManager.shared.onSessionStateChanged = { isActive in
                        LiveActivityManager.shared.handleSessionStateChange(isActive)
                    }
                    WatchConnectivityManager.shared.onVariantSwitched = { newVariant, newPhase in
                        variantManager.switchVariant(newVariant: newVariant, newPhase: newPhase)
                        UserDefaults.standard.set(true, forKey: "instructionsNeeded")
                        UserDefaults.standard.set(true, forKey: "variantSwitchPending")
                        Task {
                            await sessionManager.loadSessionCount()
                        }
                        CueApp.fireVariantSwitchNotification()
                    }
                    WatchConnectivityManager.shared.onExperimentComplete = {
                        Task {
                            await sessionManager.loadSessionCount()
                        }
                        tabController.open(.survey)
                        CueApp.fireSurveyUnlockedNotification()
                    }
                }
                .onOpenURL { url in
                  GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

extension CueApp {
    static func fireVariantSwitchNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Variant Switched"
        content.body = "You've been moved to a new experimental variant. Open the Cue app to see your updated instructions."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        let request = UNNotificationRequest(
            identifier: "cue.variantSwitched.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    static func fireSurveyUnlockedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Survey Unlocked"
        content.body = "You've completed the experiment! Open the Cue app to take the survey."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        let request = UNNotificationRequest(
            identifier: "cue.surveyUnlocked.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        _ = WatchConnectivityManager.shared
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge, .list])
    }
}
