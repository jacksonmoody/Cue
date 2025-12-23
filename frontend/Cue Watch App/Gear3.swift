//
//  Gear3.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/22/25.

// Gear 3: Substitution of a better and higher reward
// 4-7-8 Breathing Exercise

import SwiftUI

struct Gear3: View {
    @Environment(NavigationRouter.self) private var router
    @State private var currentPhase: Int = 0
    @State private var opacity: Double = 0
    private let phaseTimings: [(fadeIn: Double, display: Double, fadeOut: Double)] = [
        (fadeIn: 1.5, display: 1.5, fadeOut: 1.5),
        (fadeIn: 1.5, display: 71.5, fadeOut: 3)
    ]
    
    var body: some View {
        ZStack {
            if currentPhase == 0 {
                Text("Let's try a quick breathing exercise...")
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(opacity)
            }
            
            if currentPhase == 1 {
                Breathe()
                    .opacity(opacity)
            }
        }
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.fadeIn + timing.display) {
            withAnimation(.easeInOut(duration: timing.fadeOut)) {
                opacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + timing.fadeOut) {
                if phase < 1 {
                    animatePhase(phase: phase + 1)
                }
                if phase == 1 {
                    router.navigateHome()
                }
            }
        }
    }
}

#Preview {
    Gear3()
        .environment(NavigationRouter())
}
