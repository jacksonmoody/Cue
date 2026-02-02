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
    let completeReflection: (Bool) -> Void
    
    enum BreathingPhase: CaseIterable {
        case inhale, hold, exhale
        
        var duration: TimeInterval {
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
    
    @State private var startDate = Date()
    @State private var audioPlayer: AVAudioPlayer?
    private var totalCycleDuration: TimeInterval {
        BreathingPhase.allCases.reduce(0) { $0 + $1.duration }
    }
    @State private var opacity = 1.0
    
    var body: some View {
        TimelineView(ReflectTimelineSchedule(from: startDate)) { context in
            let elapsed = context.date.timeIntervalSince(startDate)
            let cycleElapsed = elapsed.truncatingRemainder(dividingBy: totalCycleDuration)
            let (phase, phaseElapsed) = calculatePhase(cycleElapsed: cycleElapsed)
            BreatheVisuals(
                date: context.date,
                phase: phase,
                phaseElapsed: phaseElapsed,
                opacity: opacity
            )
        }
        .onAppear {
            startDate = Date()
            playAudio()
            DispatchQueue.main.asyncAfter(deadline: .now() + 73.5) {
                withAnimation(.easeInOut(duration: 2.5)) {
                    opacity = 0
                }
                completeReflection(false)
            }
        }
        .onDisappear {
            audioPlayer?.stop()
            audioPlayer = nil
        }
    }
    
    func calculatePhase(cycleElapsed: TimeInterval) -> (BreathingPhase, TimeInterval) {
        if cycleElapsed < 4 {
            return (.inhale, cycleElapsed)
        } else if cycleElapsed < 11 {
            return (.hold, cycleElapsed - 4)
        } else {
            return (.exhale, cycleElapsed - 11)
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
}

struct BreatheVisuals: View {
    let date: Date
    let phase: Breathe.BreathingPhase
    let phaseElapsed: TimeInterval
    let opacity: Double
    
    var body: some View {
        let circleScale = calculateScale()
        let displayText = calculateText()
        let pulseOpacity = calculatePulse()
        
        ZStack {
            Color.black.ignoresSafeArea(.all)
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .scaleEffect(1.0)
            
            ZStack {
                SwirlingOrb(date: date)
                    .scaleEffect(circleScale)
                
                if phase == .hold {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 4)
                        .scaleEffect(circleScale)
                        .opacity(pulseOpacity)
                }
            }
            
            Text(displayText)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .shadow(radius: 5)
                .id(displayText)
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
        }
        .onChange(of: phase) {
            WKInterfaceDevice.current().play(.click)
        }
        .opacity(opacity)
    }
    
    func calculateScale() -> CGFloat {
        switch phase {
        case .inhale:
            return 0.5 + (0.5 * (phaseElapsed / 4.0))
        case .hold:
            return 1.0
        case .exhale:
            return 1.0 - (0.5 * (phaseElapsed / 8.0))
        }
    }
    
    func calculateText() -> String {
        let seconds = Int(phaseElapsed)
        if seconds == 0 {
            return phase.instruction
        } else {
            return "\(seconds + 1)"
        }
    }
    
    func calculatePulse() -> Double {
        guard phase == .hold else { return 0 }
        let pulseDuration = 2.0
        let progress = phaseElapsed.truncatingRemainder(dividingBy: pulseDuration) / pulseDuration
        let val = cos(progress * 2 * .pi)
        return 0.1 + 0.9 * ((val + 1) / 2)
    }
}

struct SwirlingOrb: View {
    let date: Date
    let gradientColors: [Color] = [
        Color(red: 1.0, green: 0.98, blue: 0.85),
        Color(red: 1.0, green: 0.75, blue: 0.85),
        Color(red: 0.8, green: 0.6, blue: 0.9),
        Color(red: 0.4, green: 0.6, blue: 1.0),
        Color(red: 0.6, green: 0.8, blue: 1.0),
        Color(red: 1.0, green: 0.98, blue: 0.85)
    ]
    
    var body: some View {
        let rotationPeriod = 8.0
        let rotation = (date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: rotationPeriod) / rotationPeriod) * 360
        
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
                .rotationEffect(.degrees(rotation))
            
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
    }
}

#Preview {
    Breathe(completeReflection: {_ in })
}

