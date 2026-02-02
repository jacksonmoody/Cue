//
//  SettingsView.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/22/25.
//

import SwiftUI

struct SettingsView: View {
    private static let reflectionReminderHourKey = "reflectionReminderHour"
    private static let reflectionReminderMinuteKey = "reflectionReminderMinute"

    static var defaultStartDate: Date {
        var components = DateComponents()
        components.hour = 17
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func initialDate() -> Date {
        let defaults = UserDefaults.standard
        guard let hour = defaults.object(forKey: reflectionReminderHourKey) as? Int,
              let minute = defaults.object(forKey: reflectionReminderMinuteKey) as? Int else {
            return defaultStartDate
        }
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? defaultStartDate
    }

    @State private var date = SettingsView.initialDate()

    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue.opacity(0.5), .gradientPurple.opacity(0.5)], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            VStack {
                Text("Pick a time to receive reflection reminders.")
                DatePicker(
                    "Reminder Time",
                    selection: $date,
                    displayedComponents: [.hourAndMinute]
                )
                .padding(.horizontal)
            }
            .padding(.horizontal)
            .navigationTitle {
                Text("Adjust Time")
                    .foregroundColor(.white)
            }
        }
        .onChange(of: date) { _, newDate in
            let defaults = UserDefaults.standard
            defaults.set(Calendar.current.component(.hour, from: newDate), forKey: Self.reflectionReminderHourKey)
            defaults.set(Calendar.current.component(.minute, from: newDate), forKey: Self.reflectionReminderMinuteKey)
            WatchDelegate.scheduleReflectionReminderIfNeeded()
        }
    }
}

#Preview {
    SettingsView()
}
