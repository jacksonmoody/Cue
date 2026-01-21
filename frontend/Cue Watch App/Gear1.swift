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
                            router.navigateToGear2()
                        }
                        ListButton("Morning Routine", image: "sun.horizon") {
                            router.navigateToGear2()
                        }
                        ListButton("Student Stress", image: "graduationcap") {
                            router.navigateToGear2()
                        }
                        ListButton("Home Stress", image: "house") {
                            router.navigateToGear2()
                        }
                        ListButton("Not Sure", image: "questionmark") {
                            router.navigateToGear2()
                        }
                        ListButton("Other", image: "ellipsis.circle") {
                            router.navigateToGear2()
                        }
                        Text("Customize this response in the \"Reflect\" tab of the Cue iOS app.")
                            .font(.system(size: 12))
                            .listRowBackground(Color.black.opacity(0))
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
}
