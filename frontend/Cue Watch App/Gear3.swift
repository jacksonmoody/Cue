//
//  Gear3.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/22/25.

// Gear 3: Substitution of a better and higher reward

import SwiftUI

struct Gear3: View {
    @Environment(NavigationRouter.self) private var router
    @EnvironmentObject var reflectionManager: ReflectionManager
    @State private var currentPhase: Int = 0
    @State private var opacity: Double = 0
    @State private var runtimeSession: WKExtendedRuntimeSession?
    @State private var selectedOption: GearOption?
    @State private var showReflectionView: Bool = false
    @State private var reflectionViewOpacity: Double = 0
    private let phaseTimings: [(fadeIn: Double, display: Double, fadeOut: Double)] = [
        (fadeIn: 1.5, display: 1.5, fadeOut: 1.5),
        (fadeIn: 1.5, display: 0, fadeOut: 0),
    ]

    var body: some View {
        ZStack {
            if currentPhase == 0 {
                Text("How would you like to respond instead?")
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(opacity)
                    .padding(.horizontal)
            }
            if currentPhase == 1 && !showReflectionView {
                List {
                    ForEach(reflectionManager.preferences?.gear3Options ?? []) { option in
                        ListButton(option.text, image: option.icon) {
                            handleSelection(option)
                        }
                    }
                    Text("Customize these options in the \"Reflect\" tab of the Cue iOS app.")
                        .font(.system(size: 12))
                        .listRowBackground(Color.clear)
                }
                .opacity(opacity)
                .scrollIndicators(.hidden)
                .padding(.horizontal)
            }
            if showReflectionView, let selectedOption {
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
    }
    
    private func handleSelection(_ option: GearOption) {
        selectedOption = option
        reflectionManager.logGearSelection(option, forGear: 3, atDate: .now)
        transitionToReflectionView()
    }
    
    private func completeReflection(canceled: Bool) {
        reflectionManager.endCurrentSession(atDate: .now)
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
    
    @ViewBuilder
    private func reflectionView(for option: GearOption) -> some View {
        switch option {
        case GearOption(text: "Mindful Breaths", icon: "apple.meditate"):
            Breathe()
        case GearOption(text: "Cross Body Taps", icon: "hand.tap"):
            Text("Cross Body Taps")
                .fontWeight(.bold)
        case GearOption(text: "Visualization", icon: "photo"):
            Text("Visualization")
                .fontWeight(.bold)
        case GearOption(text: "Exercise", icon: "figure.run.treadmill"):
            Text("Exercise")
                .fontWeight(.bold)
        default:
            Text(option.text)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    Gear3()
        .environment(NavigationRouter())
        .environmentObject(ReflectionManager())
}
