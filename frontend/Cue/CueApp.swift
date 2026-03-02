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
                    appDelegate.tabController = tabController
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
                        NotificationHelper.fireVariantSwitchNotification()
                    }
                    WatchConnectivityManager.shared.onExperimentComplete = {
                        Task {
                            await sessionManager.loadSessionCount()
                        }
                        tabController.open(.survey)
                        NotificationHelper.fireSurveyUnlockedNotification()
                    }
                }
                .onOpenURL { url in
                  GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    weak var tabController: TabController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        _ = WatchConnectivityManager.shared
        UNUserNotificationCenter.current().delegate = self
        NotificationHelper.registerMonitoringReminderCategory()
        NotificationHelper.scheduleMonitoringReminders()
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let categoryId = response.notification.request.content.categoryIdentifier
        if categoryId == NotificationHelper.surveyUnlockedCategoryIdentifier {
            DispatchQueue.main.async { [weak self] in
                self?.tabController?.open(.survey)
            }
        } else if categoryId == NotificationHelper.monitoringReminderCategoryIdentifier {
            DispatchQueue.main.async { [weak self] in
                self?.tabController?.open(.manage)
            }
        }
        completionHandler()
    }
}
