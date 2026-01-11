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
    @Environment(NavigationRouter.self) private var router
    @State private var showingInstructions = false
    let variant: Int
    
    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            ZStack {
                LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
                
                VStack {
                    ZStack {
                        if connectivityManager.isSessionActive {
                            SwirlingRing(delay: 0.0, size: 130, isWatch: true)
                            SwirlingRing(delay: 2.6, size: 130, isWatch: true)
                            SwirlingRing(delay: 5.3, size: 130, isWatch: true)
                        }
                        Button(action: {
                            toggleSession()
                        })
                        {
                            ZStack {
                                Circle()
                                    .strokeBorder(.white.opacity(0.5), lineWidth: 1)
                                    .frame(width: 120, height: 120)
                                
                                VStack(spacing: 4) {
                                    Image(systemName: connectivityManager.isSessionActive ? "stop.fill" : "play.fill")
                                        .font(.system(size: 30))
                                    Text(connectivityManager.isSessionActive ? "Stop Monitoring" : "Start Monitoring")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom)
                    if connectivityManager.isSessionActive {
                        TimelineView(MetricsTimelineSchedule(from: workoutManager.builder?.startDate ?? Date())) { context in
                            ElapsedTimeView(elapsedTime: workoutManager.builder?.elapsedTime ?? 0, showSubseconds: context.cadence == .live)
                        }
                    }
                    Text("Variant: \(variant)")
                }
                .animation(.default, value: connectivityManager.isSessionActive)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Help", systemImage: "questionmark.circle") {
                            showingInstructions = true
                        }
                    }
                    if variant == 2 {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Settings", systemImage: "gear") {
                                router.navigateToSettings()
                            }
                        }
                    }
                    if variant == 3 {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Intervention", systemImage: "apple.meditate") {
                                router.navigateToGear1()
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingInstructions) {
                    InstructionsView(onboardingNeeded: .constant(false), refresher: true)
                }
                .alert("Connectivity Error", isPresented: $connectivityManager.showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Please try again.")
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .gear1:
                        Gear1()
                    case .gear2:
                        Gear2()
                    case .gear3:
                        Gear3(bypassMute: false)
                    case .gear3Bypass:
                        Gear3(bypassMute: true)
                    case .settings:
                        SettingsView()
                    case .muted:
                        MutedView()
                            .navigationBarBackButtonHidden()
                    }
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
        .environment(NavigationRouter())
}
