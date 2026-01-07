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
                        Button("  11am Meeting", systemImage: "calendar"){
                            router.navigateToGear2()
                        }
                        Button("  Morning Routine", systemImage: "sun.horizon") {
                            router.navigateToGear2()
                        }
                        Button("  Student Stress", systemImage: "graduationcap"){
                            router.navigateToGear2()
                        }
                        Button("  Home Stress", systemImage: "house"){
                            router.navigateToGear2()
                        }
                        Button("  Not Sure", systemImage: "questionmark"){
                            router.navigateToGear2()
                        }
                        Button("  Other", systemImage: "ellipsis.circle"){
                            router.navigateToGear2()
                        }
                    }
                    .headerProminence(.increased)
                }
                .opacity(opacity)
                .scrollIndicators(.hidden)
                .padding()
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

#Preview {
    Gear1()
        .environment(NavigationRouter())
}
