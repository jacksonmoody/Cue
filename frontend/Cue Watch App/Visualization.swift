//
//  Visualization.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 1/30/26.
//

import SwiftUI
import AVFoundation
import Combine

private final class VisualizationAudioDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

struct Visualization: View {
    let completeReflection: (Bool) -> Void
    private static let symbols = ["tree.circle", "eye", "ear", "wind", "apple.meditate.circle"]
    private static let audioFiles = ["part1", "part2", "part3", "part4", "part5"]
    private static let fadeDuration: Double = 1

    @State private var startDate = Date()
    @State private var currentSectionIndex = 0
    @State private var symbolOpacity: Double = 1.0
    @State private var opacity: Double = 1.0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioDelegate: VisualizationAudioDelegate?
    @State private var breathePlayer: AVAudioPlayer?

    var body: some View {
        TimelineView(ReflectTimelineSchedule(from: startDate)) { _ in
            ZStack {
                Color.black.ignoresSafeArea(.all)
                ReflectBackground(videoTitle: "orb")
                Image(systemName: Self.symbols[currentSectionIndex])
                    .font(.system(size: 64, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .opacity(symbolOpacity)
            }
            .opacity(opacity)
        }
        .onAppear {
            playBreathe()
            playSection(0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 128) {
                withAnimation(.easeInOut(duration: 2.5)) {
                    opacity = 0
                }
                completeReflection(false)
            }
        }
        .onDisappear {
            breathePlayer?.stop()
            breathePlayer = nil
            audioPlayer?.stop()
            audioPlayer = nil
            audioDelegate = nil
        }
    }

    private func playBreathe() {
        guard let url = Bundle.main.url(forResource: "breathe", withExtension: "mp3") else { return }
        do {
            breathePlayer = try AVAudioPlayer(contentsOf: url)
            breathePlayer?.volume = 0.1
            breathePlayer?.numberOfLoops = -1
            breathePlayer?.play()
        } catch {}
    }

    private func playSection(_ index: Int) {
        guard index < Self.audioFiles.count else { return }

        if index != currentSectionIndex {
            withAnimation(.easeInOut(duration: Self.fadeDuration)) {
                symbolOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.fadeDuration) {
                currentSectionIndex = index
                withAnimation(.easeInOut(duration: Self.fadeDuration)) {
                    symbolOpacity = 1
                }
                startAudio(for: index)
            }
        } else {
            symbolOpacity = 1
            startAudio(for: index)
        }
    }

    private func startAudio(for index: Int) {
        let name = Self.audioFiles[index]
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            return
        }
        do {
            let delegate = VisualizationAudioDelegate {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    if index + 1 < Self.audioFiles.count {
                        playSection(index + 1)
                    }
                }
            }
            audioDelegate = delegate
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.enableRate = true
            audioPlayer?.rate = 0.95
            audioPlayer?.delegate = delegate
            audioPlayer?.play()
        } catch {}
    }
}

#Preview {
    Visualization(completeReflection: { _ in })
}
