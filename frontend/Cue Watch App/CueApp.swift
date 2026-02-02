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
    @StateObject private var reflectionManager = ReflectionManager()
    @StateObject private var locationService = LocationService()
    @State private var navigationRouter = NavigationRouter()
    
    var body: some Scene {
        WindowGroup {
             RootView()
                .onAppear {
                    workoutManager.variantManager = variantManager
                    reflectionManager.variantManager = variantManager
                    delegate.workoutManager = workoutManager
                    delegate.navigationRouter = navigationRouter
                }
                .environmentObject(workoutManager)
                .environmentObject(variantManager)
                .environmentObject(reflectionManager)
                .environmentObject(locationService)
                .environment(navigationRouter)
        }
    }
}

extension WatchDelegate: WKExtensionDelegate {}
class WatchDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    weak var workoutManager: WorkoutManager?
    weak var navigationRouter: NavigationRouter?

    func applicationDidFinishLaunching() {
        _ = WatchConnectivityManager.shared
        UNUserNotificationCenter.current().delegate = self
        WatchDelegate.registerReflectionReminderCategory()
        scheduleMonitoringNotifications()
        Self.scheduleReflectionReminderIfNeeded()
        debugNotifications()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == Self.reflectionReminderOpenActionIdentifier {
            DispatchQueue.main.async { [weak self] in
                self?.navigationRouter?.navigateToGear1()
            }
        }
        completionHandler()
    }

    private func debugNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("Pending local notifications (\(requests.count)):")
            for req in requests {
                print("  - id: \(req.identifier), title: \(req.content.title), body: \(req.content.body), trigger: \(String(describing: req.trigger))")
            }
        }
    }
    
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            workoutManager?.startWorkout()
        }
    }

}

// Variant 2 scheduled reflection reminders
extension WatchDelegate {
    static let scheduledReflectionIdentifier = "cue.reminder.scheduledReflection"
    static let reflectionReminderCategoryIdentifier = "REFLECTION_REMINDER"
    static let reflectionReminderOpenActionIdentifier = "OPEN_REFLECTION"

    static func registerReflectionReminderCategory() {
        let action = UNNotificationAction(identifier: reflectionReminderOpenActionIdentifier, title: "Reflect", options: [.foreground])
        let category = UNNotificationCategory(
            identifier: reflectionReminderCategoryIdentifier,
            actions: [action],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func scheduleReflectionReminderIfNeeded() {
        // Only schedule if in Variant 2
        let defaults = UserDefaults.standard
        guard let variant = defaults.object(forKey: "variantId") as? Int, variant == 2 else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [scheduledReflectionIdentifier]
            )
            return
        }
        // Default to 5pm if no preference found
        let hour = (defaults.object(forKey: "reflectionReminderHour") as? Int) ?? 17
        let minute = (defaults.object(forKey: "reflectionReminderMinute") as? Int) ?? 0
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [scheduledReflectionIdentifier]
        )
        let content = UNMutableNotificationContent()
        content.title = "Daily Reflection"
        content.body = "Let's take a moment to reflect with Cue."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        content.categoryIdentifier = reflectionReminderCategoryIdentifier
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: scheduledReflectionIdentifier,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}

// Monitoring reminders at 9am and 10pm (all variants)
private extension WatchDelegate {
    static let disableMonitoringIdentifier = "cue.reminder.disableMonitoring"
    static let enableMonitoringIdentifier = "cue.reminder.enableMonitoring"

    func scheduleMonitoringNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: [Self.enableMonitoringIdentifier, Self.disableMonitoringIdentifier]
        )

        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        let enableContent = UNMutableNotificationContent()
        enableContent.title = "Enable Monitoring"
        enableContent.body = "Remember to enable Cue monitoring before beginning your day!"
        enableContent.interruptionLevel = .timeSensitive
        let enableTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(
            identifier: Self.enableMonitoringIdentifier,
            content: enableContent,
            trigger: enableTrigger
        ))

        components.hour = 22
        let disableContent = UNMutableNotificationContent()
        disableContent.title = "Disable Monitoring"
        disableContent.body = "Heading to bed? Consider disabling Cue monitoring to conserve battery."
        disableContent.interruptionLevel = .timeSensitive
        let disableTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(
            identifier: Self.disableMonitoringIdentifier,
            content: disableContent,
            trigger: disableTrigger
        ))
    }
}

