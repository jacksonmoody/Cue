//
//  SwirlingRing.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI

struct SwirlingRing: View {
    let delay: Double
    let size: CGFloat
    let isWatch: Bool
    @State private var startTime: Date?
    @State private var fadeInOpacity: Double = 0
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.01)) { context in
            let progress = calculateProgress(from: context.date)
            
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.white.opacity(1), .white.opacity(1), .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(progress * 360))
                .scaleEffect(1 + progress * (isWatch ? 1.8 : 2.5))
                .opacity(isWatch ? progress : progress == 0 ? 0 : 1 - progress)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                startTime = Date()
            }
        }
        .onDisappear {
            startTime = nil
        }
    }
    
    private func calculateProgress(from date: Date) -> Double {
        guard let startTime = startTime else { return 0 }
        let elapsed = date.timeIntervalSince(startTime)
        let duration: Double = 8.0
        let cycleTime = elapsed.truncatingRemainder(dividingBy: duration)
        return cycleTime / duration
    }
}

#Preview {
    SwirlingRing(delay: 0, size: 120, isWatch: false)
}
