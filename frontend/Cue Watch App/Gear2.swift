//
//  Gear2.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/22/25.

// Gear 2: Disillusionment with the Reward
// Brewer emphasizes felt experience over cognition.

import SwiftUI
import WatchKit

struct Gear2: View {
    @Environment(NavigationRouter.self) private var router
    @State private var currentPhase: Int = 0
    @State private var opacity: Double = 0
    @State private var vibrationTimer: Timer?
    @State private var isMuted: Bool = false
    private let phaseTimings: [(fadeIn: Double, display: Double, fadeOut: Double)] = [
        (fadeIn: 1.5, display: 3.0, fadeOut: 1.5),
        (fadeIn: 1.5, display: 4.0, fadeOut: 1.5),
        (fadeIn: 2.0, display: 0.0, fadeOut: 0.0)
    ]
    
    var body: some View {
        ZStack {
            MuteTesterView()
            if currentPhase == 0 {
                Text("Now, shift your attention to your body...")
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(opacity)
                    .padding(.horizontal)
            }
            
            if currentPhase == 1 {
                Text("If you were to follow your body's usual response, what might you feel here?")
                    .fontWeight(.bold)
                    .opacity(opacity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if currentPhase == 2 {
                List {
                    ListButton("Heart Racing", image: "heart") {
                        navigateNext()
                    }
                    ListButton("Muscle Tensing", image: "dumbbell") {
                        navigateNext()
                    }
                    ListButton("Rapid Breathing", image: "lungs") {
                        navigateNext()
                    }
                    ListButton("Feeling Heavy", image: "scalemass") {
                        navigateNext()
                    }
                    ListButton("Other", image: "questionmark") {
                        navigateNext()
                    }
                    ListButton("No Change", image: "circle.slash") {
                        navigateNext()
                    }
                }
                .opacity(opacity)
                .scrollIndicators(.hidden)
                .padding(.horizontal)
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopVibration()
        }
        .onReceive(updateSilentState) { silent in
            isMuted = silent
        }
    }
    
    private func startAnimation() {
        animatePhase(phase: 0)
    }
    
    private func animatePhase(phase: Int) {
        currentPhase = phase
        let timing = phaseTimings[phase]
        
        if phase == 0 {
            startVibration()
        }
        
        withAnimation(.easeInOut(duration: timing.fadeIn)) {
            opacity = 1.0
        }
        
        if phase == 2 {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.fadeIn + timing.display) {
            if phase == 1 {
                stopVibration()
            }
            
            withAnimation(.easeInOut(duration: timing.fadeOut)) {
                opacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + timing.fadeOut) {
                if phase < 2 {
                    animatePhase(phase: phase + 1)
                }
            }
        }
    }
    
    private func startVibration() {
        stopVibration()
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            WKInterfaceDevice.current().play(.click)
        }
    }
    
    private func stopVibration() {
        vibrationTimer?.invalidate()
        vibrationTimer = nil
    }

    private func navigateNext() {
        if isMuted {
            router.navigateToMuted()
        } else {
            router.navigateToGear3()
        }
    }
}

#Preview {
    Gear2()
        .environment(NavigationRouter())
}
