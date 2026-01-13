//
//  Gear3.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/22/25.

// Gear 3: Substitution of a better and higher reward
// 4-7-8 Visual breathing exercise inspired by the Hoberman Sphere

import SwiftUI

struct Gear3: View {
    @Environment(NavigationRouter.self) private var router
    @State private var currentPhase: Int = 0
    @State private var opacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    @State private var runtimeSession: WKExtendedRuntimeSession?
    private let phaseTimings: [(fadeIn: Double, display: Double, fadeOut: Double)] = [
        (fadeIn: 1.5, display: 1.5, fadeOut: 1.5),
        (fadeIn: 1.5, display: 71.5, fadeOut: 3)
    ]

    var body: some View {
        ZStack {
            if currentPhase == 0 {
                Color.black.ignoresSafeArea(.all)
                    .opacity(backgroundOpacity)
                Text("Let's try a quick breathing exercise...")
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(opacity)
                    .padding(.horizontal)
            }
            if currentPhase == 1 {
                Color.black.ignoresSafeArea(.all)
                    .opacity(backgroundOpacity)
                Breathe()
                    .opacity(opacity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel", systemImage: "xmark") {
                    completeReflection(canceled: true)
                }
            }
        }
        .onAppear {
            startExtendedRuntimeSession()
            animatePhase(phase: 0)
        }
    }
    
    private func completeReflection(canceled: Bool) {
        endExtendedRuntimeSession()
        router.navigateHome()
    }

    private func startExtendedRuntimeSession() {
        let session = WKExtendedRuntimeSession()
        runtimeSession = session
        session.start()
    }

    private func endExtendedRuntimeSession() {
        runtimeSession?.invalidate()
        runtimeSession = nil
    }
    
    private func animatePhase(phase: Int) {
        currentPhase = phase
        let timing = phaseTimings[phase]
        
        withAnimation(.easeInOut(duration: timing.fadeIn)) {
            opacity = 1.0
            if phase == 0 {
                backgroundOpacity = 1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.fadeIn + timing.display) {
            withAnimation(.easeInOut(duration: timing.fadeOut)) {
                opacity = 0.0
                
                if phase == 1 {
                    backgroundOpacity = 0.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + timing.fadeOut) {
                if phase < 1 {
                    animatePhase(phase: phase + 1)
                }
                if phase == 1 {
                    completeReflection(canceled:false)
                }
            }
        }
    }
}

#Preview {
    Gear3()
        .environment(NavigationRouter())
}
