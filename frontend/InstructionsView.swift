//
//  InstructionsView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI

struct InstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    @Binding var onboardingNeeded: Bool
    let center = UNUserNotificationCenter.current()
    
    var body: some View {
        ScrollView {
            VStack(alignment:.leading, spacing: 30) {
                #if os(iOS)
                Text("Instructions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                #endif
                Text("Thank you for participating in this experiment! To get started, please accept notifications and HealthKit permissions. Then, click the start button to begin monitoring.\n\nFor best results, please keep each monitoring session running as long as possible. To unlock the survey, you will need at least 5 sessions that are at least 5 hours long each.")
                Button("Get Started") {
                    workoutManager.requestAuthorization { authorized in
                        if authorized {
                            Task {
                                do {
                                    let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                                    if granted {
                                        onboardingNeeded = false
                                        dismiss()
                                    }
                                } catch {
                                }
                            }
                        } else {
                        }
                    }
                }
                #if os(iOS)
                .padding()
                .fontWeight(.bold)
                .glassEffect(.regular.tint(.blue).interactive())
                .foregroundStyle(.white)
                #else
                .frame(maxWidth: .infinity)
                #endif
            }
            #if os(iOS)
            .padding(40)
            .font(.title2)
            #else
            .multilineTextAlignment(.center)
            .padding()
            #endif
        }
    }
}

#Preview {
    InstructionsView(onboardingNeeded: .constant(true))
}
