//
//  Breathe.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/22/25.
//

import SwiftUI
import Combine
import AVFoundation

struct Breathe: View {
    enum BreathingPhase {
        case inhale, hold, exhale
        
        var duration: Int {
            switch self {
            case .inhale: return 4
            case .hold: return 7
            case .exhale: return 8
            }
        }
        
        var instruction: String {
            switch self {
            case .inhale: return "In"
            case .hold: return "Hold"
            case .exhale: return "Out"
            }
        }
    }
    
    @State private var phase: BreathingPhase = .inhale
    @State private var timeElapsedInPhase = 0
    @State private var circleScale: CGFloat = 0.5
    @State private var pulseOpacity: Double = 1.0
    @State private var displayText: String = "In"
    @State private var audioPlayer: AVAudioPlayer?
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .scaleEffect(1.0)
            
            ZStack {
                SwirlingOrb()
                    .scaleEffect(circleScale)
                
                if phase == .hold {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 4)
                        .scaleEffect(circleScale)
                        .opacity(pulseOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                pulseOpacity = 0.1
                            }
                        }
                }
            }
            .animation(.linear(duration: Double(phase.duration)), value: circleScale)
            
            Text(displayText)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .shadow(radius: 5)
                .id(displayText)
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
        }
        .onAppear {
            playAudio()
            startCycle()
        }
        .onDisappear {
            audioPlayer?.stop()
            audioPlayer = nil
        }
        .onReceive(timer) { _ in
            advanceTime()
        }
    }
    
    
    func playAudio() {
        guard let url = Bundle.main.url(forResource: "breathe", withExtension: "mp3") else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    func startCycle() {
        WKInterfaceDevice.current().play(.click)
        
        phase = .inhale
        timeElapsedInPhase = 0
        displayText = phase.instruction
        circleScale = 0.5
        
        withAnimation(.easeInOut(duration: 4)) {
            circleScale = 1.0
        }
    }
    
    func advanceTime() {
        timeElapsedInPhase += 1
        
        if timeElapsedInPhase >= phase.duration {
            moveToNextPhase()
        } else {
            if timeElapsedInPhase == 0 {
                withAnimation {
                    displayText = phase.instruction
                }
            } else {
                withAnimation {
                    displayText = "\(timeElapsedInPhase + 1)"
                }
            }
        }
    }
    
    func moveToNextPhase() {
        WKInterfaceDevice.current().play(.click)
        
        switch phase {
        case .inhale:
            phase = .hold
            
        case .hold:
            phase = .exhale
            withAnimation(.easeInOut(duration: 8)) {
                circleScale = 0.5
            }
            
        case .exhale:
            phase = .inhale
            withAnimation(.easeInOut(duration: 4)) {
                circleScale = 1.0
            }
        }
        
        timeElapsedInPhase = 0
        withAnimation {
            displayText = phase.instruction
        }
        pulseOpacity = 1.0
    }
}

struct SwirlingOrb: View {
    @State private var isAnimating = false
    let gradientColors: [Color] = [
        Color(red: 1.0, green: 0.98, blue: 0.85),
        Color(red: 1.0, green: 0.75, blue: 0.85),
        Color(red: 0.8, green: 0.6, blue: 0.9),
        Color(red: 0.4, green: 0.6, blue: 1.0),
        Color(red: 0.6, green: 0.8, blue: 1.0),
        Color(red: 1.0, green: 0.98, blue: 0.85)
    ]
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center
                    )
                )
                .blur(radius: 10)
                .mask(Circle())
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: isAnimating)
            
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [.white.opacity(0.4), .clear]),
                        center: .topLeading,
                        startRadius: 10,
                        endRadius: 100
                    )
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    Breathe()
}
