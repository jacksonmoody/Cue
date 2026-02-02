//
//  Taps.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 1/30/26.
//

import SwiftUI
import AVFoundation
import WatchKit

struct Taps: View {
    let completeReflection: (Bool) -> Void
    let startDate = Date()
    private let phaseTimings: [(fadeIn: Double, display: Double, fadeOut: Double)] = [
        (fadeIn: 1.5, display: 3.5, fadeOut: 1.5),
        (fadeIn: 1.5, display: 3.0, fadeOut: 1.5),
        (fadeIn: 1.5, display: 2.0, fadeOut: 1.5),
        (fadeIn: 1.5, display: 73.5, fadeOut: 1.5)
    ]
    
    private let tapInterval: TimeInterval = 0.85
    
    @State private var currentPhase: Int = 0
    @State private var opacity: Double = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var leftHandTapped: Bool = true
    @State private var tapTimer: Timer?
    
    var body: some View {
        TimelineView(ReflectTimelineSchedule(from: startDate)) { context in
            ZStack {
                Color.white.ignoresSafeArea(.all)
                if currentPhase == 3 {
                    VStack {
                        Text("Now gently alternate taps, left then right.")
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center)
                            .font(.caption2.bold())
                        ZStack {
                            Image("taps")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 178)
                            Image(systemName:"hand.wave.fill")
                                .foregroundStyle(.yellow)
                                .font(.system(size: 26, weight: .bold))
                                .offset(x: -13, y: 21)
                                .rotationEffect(Angle(degrees: 8))
                                .scaleEffect(leftHandTapped ? 1 : 1.3)
                                .opacity(leftHandTapped ? 1 : 0)
                                .animation(.spring(duration: 0.3), value: leftHandTapped)
                            Image(systemName:"hand.wave.fill")
                                .foregroundStyle(.yellow)
                                .scaleEffect(x: -1, y: 1)
                                .font(.system(size: 24, weight: .bold))
                                .offset(x: 16, y: 17)
                                .rotationEffect(Angle(degrees: -8))
                                .scaleEffect(leftHandTapped ? 1.3 : 1)
                                .opacity(leftHandTapped ? 0 : 1)
                                .animation(.spring(duration: 0.3), value: leftHandTapped)
                        }
                    }
                    .opacity(opacity)
                }
                Group {
                    if currentPhase == 0 {
                        Text("Find a quiet space. Sit or stand with your back straight and feet flat on the ground.")
                    }
                    if currentPhase == 1 {
                        Text("Cross your arms over your chest, similarly to how you would hug yourself.")
                    }
                    if currentPhase == 2 {
                        Text("Breathe slowly and deeply throughout the exercise.")
                    }
                }
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .fontWeight(.bold)
                .opacity(opacity)
            }
        }
        .onAppear {
            animatePhase(phase: 0)
        }
        .onDisappear {
            stopTapAnimation()
            audioPlayer?.stop()
            audioPlayer = nil
        }
    }
    
    private func animatePhase(phase: Int) {
        currentPhase = phase
        let timing = phaseTimings[phase]
        
        withAnimation(.easeInOut(duration: timing.fadeIn)) {
            opacity = 1.0
        }
        
        if currentPhase == 3 {
            playAudio()
            startTapAnimation()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.fadeIn + timing.display) {
            if phase == 3 {
                stopTapAnimation()
            }
            withAnimation(.easeInOut(duration: timing.fadeOut)) {
                opacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + timing.fadeOut) {
                if phase < 3 {
                    animatePhase(phase: phase + 1)
                } else {
                    completeReflection(false)
                }
            }
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
    
    private func startTapAnimation() {
        tapTimer?.invalidate()
        leftHandTapped = true
        WKInterfaceDevice.current().play(.click)
        tapTimer = Timer.scheduledTimer(withTimeInterval: tapInterval, repeats: true) { _ in
            leftHandTapped.toggle()
            WKInterfaceDevice.current().play(.click)
        }
    }
    
    private func stopTapAnimation() {
        tapTimer?.invalidate()
        tapTimer = nil
    }
}

#Preview {
    Taps(completeReflection: { _ in })
}
