//
//  AppView.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI
import HealthKit

struct AppView: View {
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
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
                Text(workoutManager.session?.debugDescription ?? "Not Started")
            }
        }
        .onAppear {
            setupManagerCallbacks()
            if connectivityManager.isSessionActive && !workoutManager.running {
                workoutManager.startWorkout()
            }
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
    }
    
    private func toggleSession() {
        withAnimation {
            let newState = !connectivityManager.isSessionActive
            connectivityManager.updateSessionState(newState)
        }
    }
}

#Preview {
    AppView()
        .environmentObject(WorkoutManager())
}
