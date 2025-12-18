//
//  AppView.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI
import HealthKit
import Combine

struct AppView: View {
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingInstructions = false
    let variant: Int
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
                
                VStack {
                    ZStack {
                        if connectivityManager.isSessionActive {
                            SwirlingRing(delay: 0.0, size: 110, isWatch: true)
                            SwirlingRing(delay: 2.6, size: 110, isWatch: true)
                            SwirlingRing(delay: 5.3, size: 110, isWatch: true)
                        }
                        Button(action: {
                            toggleSession()
                        })
                        {
                            ZStack {
                                Circle()
                                    .strokeBorder(.white.opacity(0.5), lineWidth: 1)
                                    .frame(width: 100, height: 100)
                                
                                VStack(spacing: 4) {
                                    Image(systemName: connectivityManager.isSessionActive ? "stop.fill" : "play.fill")
                                        .font(.system(size: 30))
                                    Text(connectivityManager.isSessionActive ? "Stop" : "Start")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom)
                    TimelineView(MetricsTimelineSchedule(from: workoutManager.builder?.startDate ?? Date())) { context in
                        ElapsedTimeView(elapsedTime: workoutManager.builder?.elapsedTime ?? 0, showSubseconds: context.cadence == .live)
                    }
                    Text("Variant: \(variant)")
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Help", systemImage: "questionmark.circle") {
                            showingInstructions = true
                        }
                    }
                }
                .sheet(isPresented: $showingInstructions) {
                    InstructionsView(onboardingNeeded: .constant(false))
                }
                .alert("Connectivity Error", isPresented: $connectivityManager.showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Please try again.")
                }
            }
        }
        .onAppear {
            setupManagerCallbacks()
        }
    }
    
    private func setupManagerCallbacks() {
        connectivityManager.onSessionStateChanged = { isActive in
            if isActive {
                workoutManager.startWorkout()
            } else {
                workoutManager.stopWorkout()
            }
        }
        
        if connectivityManager.isSessionActive && !workoutManager.running {
            workoutManager.startWorkout()
        }
    }
    
    private func toggleSession() {
        withAnimation {
            let newState = !connectivityManager.isSessionActive
            connectivityManager.updateSessionState(newState)
        }
    }
}

#Preview {
    AppView(variant: 3)
        .environmentObject(WorkoutManager())
}
