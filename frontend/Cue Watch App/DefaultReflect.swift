//
//  DefaultReflect.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 1/30/26.
//

import SwiftUI
import Combine
import AVFoundation

struct DefaultReflect: View {
    let title: String
    let icon: String
    let completeReflection: (Bool) -> Void
    let randomOption: String
    let shouldPlayAudio: Bool
    let startDate: Date
    static let backgroundOptions = ["lines", "silk", "waves"]
    
    init(title: String, icon: String, playAudio: Bool = true, completeReflection: @escaping (Bool) -> Void) {
        self.title = title
        self.icon = icon
        self.completeReflection = completeReflection
        self.randomOption = Self.backgroundOptions.randomElement() ?? "lines"
        self.startDate = Date()
        self.shouldPlayAudio = playAudio
    }
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var opacity = 1.0
    
    var body: some View {
        TimelineView(ReflectTimelineSchedule(from: startDate)) { context in
            ZStack {
                Color.black.ignoresSafeArea(.all)
                ReflectBackground(videoTitle: randomOption)
                VStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                    Text(title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Text("Press \"X\" when you feel done reflecting")
                        .multilineTextAlignment(.center)
                        .font(Font.caption)
                        .frame(maxWidth: 160)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            playAudio()
        }
        .onDisappear {
            audioPlayer?.stop()
            audioPlayer = nil
        }
    }
    
    func playAudio() {
        guard let url = Bundle.main.url(forResource: "breathe", withExtension: "mp3") else {
            return
        }
        guard shouldPlayAudio else {
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
}

// Ensure that view continues updating frequently even with Always On Display
struct ReflectTimelineSchedule: TimelineSchedule {
    var startDate: Date

    init(from startDate: Date) {
        self.startDate = startDate
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> PeriodicTimelineSchedule.Entries {
        PeriodicTimelineSchedule(from: self.startDate, by: 1.0 / 30.0)
            .entries(from: startDate, mode: mode)
    }
}

#Preview {
    DefaultReflect(title: "Exercise", icon: "figure.run.treadmill", playAudio: false, completeReflection: { _ in })
}
