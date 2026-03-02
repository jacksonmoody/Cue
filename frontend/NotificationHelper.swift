//
//  NotificationHelper.swift
//  Cue
//
//  Created by Jackson Moody on 3/1/26.
//

import UserNotifications

enum NotificationHelper {
    static let surveyUnlockedCategoryIdentifier = "SURVEY_UNLOCKED"
    static let monitoringReminderCategoryIdentifier = "MONITORING_REMINDER"
    private static let monitoringReminderOpenActionIdentifier = "OPEN_MONITORING"
    private static let enableMonitoringIdentifier = "cue.reminder.enableMonitoring"
    private static let disableMonitoringIdentifier = "cue.reminder.disableMonitoring"

    static func registerMonitoringReminderCategory() {
        let openAction = UNNotificationAction(
            identifier: monitoringReminderOpenActionIdentifier,
            title: "Open Cue",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: monitoringReminderCategoryIdentifier,
            actions: [openAction],
            intentIdentifiers: [],
            options: []
        )
        let existing = UNUserNotificationCenter.current()
        existing.getNotificationCategories { categories in
            var updated = categories
            updated.insert(category)
            existing.setNotificationCategories(updated)
        }
    }

    static func scheduleMonitoringReminders() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: [enableMonitoringIdentifier, disableMonitoringIdentifier]
        )

        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        let enableContent = UNMutableNotificationContent()
        enableContent.title = "Enable Monitoring"
        enableContent.body = "Remember to enable Cue monitoring before beginning your day."
        enableContent.sound = .default
        enableContent.interruptionLevel = .timeSensitive
        enableContent.relevanceScore = 1.0
        enableContent.categoryIdentifier = monitoringReminderCategoryIdentifier
        let enableTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(
            identifier: enableMonitoringIdentifier,
            content: enableContent,
            trigger: enableTrigger
        ))

        components.hour = 21
        let disableContent = UNMutableNotificationContent()
        disableContent.title = "Disable Monitoring"
        disableContent.body = "Winding down for the day? Consider disabling monitoring to conserve battery."
        disableContent.sound = .default
        disableContent.interruptionLevel = .timeSensitive
        disableContent.relevanceScore = 1.0
        disableContent.categoryIdentifier = monitoringReminderCategoryIdentifier
        let disableTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(
            identifier: disableMonitoringIdentifier,
            content: disableContent,
            trigger: disableTrigger
        ))
    }

    static func fireVariantSwitchNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Variant Switched"
        content.body = "You've advanced to the next experimental variant. Open the Cue app to see your updated instructions."
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
        content.categoryIdentifier = surveyUnlockedCategoryIdentifier
        let request = UNNotificationRequest(
            identifier: "cue.surveyUnlocked.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
