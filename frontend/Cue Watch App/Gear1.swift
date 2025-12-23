//
//  Gear1.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/22/25.

// Gear 1: Awareness of the Habit Loop.
// Should be highly personal/contextual

import SwiftUI

struct Gear1: View {
    @Environment(NavigationRouter.self) private var router
    var body: some View {
        ProgressView()
        Text("What triggered this?")
        Text("Location")
        Text("calendar events")
        Text("also send time of day, day of week, occupation")
        Text("LLM call to personalize")
        Button("Next") {
            router.navigateToGear2()
        }
    }
}

#Preview {
    Gear1()
        .environment(NavigationRouter())
}
