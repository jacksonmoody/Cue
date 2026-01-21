//
//  Gear3.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/22/25.

// Gear 3: Substitution of a better and higher reward
// 4-7-8 Visual breathing exercise inspired by the Hoberman Sphere

import SwiftUI

enum ReflectionOptions {
    case breaths, taps, visualization, exercise, nature, friends
}

struct Gear3: View {
    @Environment(NavigationRouter.self) private var router
    @State private var currentPhase: Int = 0
    @State private var opacity: Double = 0
    @State private var runtimeSession: WKExtendedRuntimeSession?
    @State private var selection: ReflectionOptions?
    @State private var showReflectionView: Bool = false
    @State private var reflectionViewOpacity: Double = 0
    private let phaseTimings: [(fadeIn: Double, display: Double, fadeOut: Double)] = [
        (fadeIn: 1.5, display: 1.5, fadeOut: 1.5),
        (fadeIn: 1.5, display: 0, fadeOut: 0),
    ]

    var body: some View {
        ZStack {
            if currentPhase == 0 {
                Text("How else would you like to respond?")
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(opacity)
                    .padding(.horizontal)
            }
            if currentPhase == 1 && !showReflectionView {
                List {
                    ListButton("Mindful Breaths", image: "apple.meditate") {
                        selection = .breaths
                    }
                    ListButton("Cross Body Taps", image: "hand.tap") {
                        selection = .taps
                    }
                    ListButton("Visualization", image: "photo") {
                        selection = .visualization
                    }
                    ListButton("Exercise", image: "figure.run.treadmill") {
                        selection = .exercise
                    }
                    ListButton("Time in Nature", image: "tree") {
                        selection = .nature
                    }
                    ListButton("Talk with Friend(s)", image: "figure.2.arms.open") {
                        selection = .friends
                    }
                    Text("Customize these options in the \"Reflect\" tab of the Cue iOS app.")
                        .font(.system(size: 12))
                        .listRowBackground(Color.black.opacity(0))
                }
                .opacity(opacity)
                .scrollIndicators(.hidden)
                .padding(.horizontal)
            }
            if showReflectionView, let selectedOption = selection {
                reflectionView(for: selectedOption)
                    .opacity(reflectionViewOpacity)
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
        .onChange(of: selection) { oldValue, newValue in
            if newValue != nil {
                transitionToReflectionView()
            }
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
    
    @ViewBuilder
    private func reflectionView(for option: ReflectionOptions) -> some View {
        switch option {
        case .breaths:
            Breathe()
        case .taps:
            Text("Cross Body Taps")
                .fontWeight(.bold)
        case .visualization:
            Text("Visualization")
                .fontWeight(.bold)
        case .exercise:
            Text("Exercise")
                .fontWeight(.bold)
        case .nature:
            Text("Time in Nature")
                .fontWeight(.bold)
        case .friends:
            Text("Talk with Friend(s)")
                .fontWeight(.bold)
        }
    }
    
    private func transitionToReflectionView() {
        withAnimation(.easeInOut(duration: 1.5)) {
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showReflectionView = true
            reflectionViewOpacity = 0.0
            withAnimation(.easeInOut(duration: 0.5)) {
                reflectionViewOpacity = 1.0
            }
        }
    }
}

#Preview {
    Gear3()
        .environment(NavigationRouter())
}
