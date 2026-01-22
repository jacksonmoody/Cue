//
//  Gear1.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/22/25.

// Gear 1: Awareness of the Habit Loop
// Brewer emphasizes a highly personal/contextual prompt

import SwiftUI

struct Gear1: View {
    @Environment(NavigationRouter.self) private var router
    @EnvironmentObject var reflectionManager: ReflectionManager
    @State private var currentPhase: Int = 0
    @State private var opacity: Double = 0
    private let phaseTimings: [(fadeIn: Double, display: Double, fadeOut: Double)] = [
        (fadeIn: 1.5, display: 3.0, fadeOut: 1.5),
        (fadeIn: 1.5, display: 0.0, fadeOut: 0.0)
    ]
    var body: some View {
        ZStack {
            if currentPhase == 0 {
                Text("Let's take a moment to reflect...")
                        .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .opacity(opacity)
                .padding(.horizontal)
            }
            if currentPhase == 1 {
                List {
                    Section(header: Text("What may have triggered this response?").padding(.leading, -5).padding(.bottom, 10).padding(.trailing, -10)) {
                        ListButton("11am Thesis Meeting", image: "calendar") {
                            gear1Selection()
                        }
                        ListButton("Morning Routine", image: "sun.horizon") {
                            gear1Selection()
                        }
                        ListButton("Student Stress", image: "graduationcap") {
                            gear1Selection()
                        }
                        ListButton("Home Stress", image: "house") {
                            gear1Selection()
                        }
                        ListButton("Not Sure", image: "questionmark") {
                            gear1Selection()
                        }
                        ListButton("Other", image: "ellipsis.circle") {
                            gear1Selection()
                        }
                        Text("Customize this response in the \"Reflect\" tab of the Cue iOS app.")
                            .font(.system(size: 12))
                            .listRowBackground(Color.clear)
                    }
                    .headerProminence(.increased)
                }
                .opacity(opacity)
                .scrollIndicators(.hidden)
                .padding(.horizontal)
            }
        }
        .onAppear {
            animatePhase(phase:0)
        }
        .task {
            await setupReflection()
        }
    }
    
    private func setupReflection() async {
        reflectionManager.startNewSession()
        await reflectionManager.loadPreferences()
    }
    
    private func gear1Selection() {
        reflectionManager.logGearSelection(GearOption(text: "test", icon: "star"), forGear: 1, atDate: .now)
        router.navigateToGear2()
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
    let text: String
    let image: String
    let action: () -> Void
    
    init(_ text: String, image: String, action: @escaping () -> Void) {
        self.text = text
        self.image = image
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
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
        .environmentObject(ReflectionManager())
}
