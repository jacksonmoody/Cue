//
//  SettingsView.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/22/25.
//

import SwiftUI

struct SettingsView: View {
    static var defaultStartDate: Date {
        var components = DateComponents()
        components.hour = 17
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    @State private var date = SettingsView.defaultStartDate
    
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
    }
}

#Preview {
    SettingsView()
}
