//
//  Gear1.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/22/25.

// Gear 1: Awareness of the Habit Loop.
// Should be highly personal/contextual

import SwiftUI

struct Gear1: View {
    @State private var currentPhase: Int = 0
    @State private var opacity: Double = 0
    private let phaseTimings: [(fadeIn: Double, display: Double, fadeOut: Double)] = [
        (fadeIn: 1.5, display: 3.0, fadeOut: 1.5),
        (fadeIn: 1.5, display: 0.0, fadeOut: 0.0)
    ]
    var body: some View {
        ZStack {
            if currentPhase == 0 {
                VStack(spacing: 10) {
                    Text("Something just shifted.")
                        .fontWeight(.bold)
                    Text("Let's take a moment to reflect...")
                        .fontWeight(.thin)
                }
                .multilineTextAlignment(.center)
                .opacity(opacity)
                .padding()
            }
            if currentPhase == 1 {
                List {
                    Section(header: Text("What may have triggered this response?").padding(.leading, -5).padding(.bottom, 10)) {
                        ListButton("11am Thesis Meeting", image: "calendar")
                        ListButton("Morning Routine", image: "sun.horizon")
                        ListButton("Student Stress", image: "graduationcap")
                        ListButton("Home Stress", image: "house")
                        ListButton("Not Sure", image: "questionmark")
                        ListButton("Other", image: "ellipsis.circle")
                    }
                    .headerProminence(.increased)
                }
                .opacity(opacity)
                .scrollIndicators(.hidden)
            }
        }
//        ProgressView()
//        Text("What triggered this?")
//        Text("Location")
//        Text("calendar events")
//        Text("also send time of day, day of week, occupation")
//        Text("LLM call to personalize")
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        animatePhase(phase: 0)
    }
    
    private func animatePhase(phase: Int) {
        currentPhase = phase
        let timing = phaseTimings[phase]
        withAnimation(.easeInOut(duration: timing.fadeIn)) {
            opacity = 1.0
        }
        
        if phase == 1 {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.fadeIn + timing.display) {
            withAnimation(.easeInOut(duration: timing.fadeOut)) {
                opacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + timing.fadeOut) {
                if phase < 1 {
                    animatePhase(phase: phase + 1)
                }
            }
        }
    }
}

struct ListButton: View {
    @Environment(NavigationRouter.self) private var router
    let text: String
    let image: String
    
    init(_ text: String, image: String) {
        self.text = text
        self.image = image
    }
    
    var body: some View {
        Button {
            router.navigateToGear2()
        } label: {
            HStack {
                Image(systemName: image)
                    .padding(.trailing)
                Text(text)
            }
        }
    }
}

#Preview {
    Gear1()
        .environment(NavigationRouter())
}
