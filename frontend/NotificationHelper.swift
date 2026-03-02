//
//  NotificationHelper.swift
//  Cue
//
//  Created by Jackson Moody on 3/1/26.
//

import UserNotifications

enum NotificationHelper {
    static let surveyUnlockedCategoryIdentifier = "SURVEY_UNLOCKED"

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
