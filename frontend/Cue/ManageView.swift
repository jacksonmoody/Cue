//
//  ManageView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI

struct ManageView: View {
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var tabController: TabController
    let variant: Int

    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            
            VStack {
                Spacer()
                
                ZStack {
                    if connectivityManager.isSessionActive {
                        SwirlingRing(delay: 0.0, size: 120, isWatch: false)
                        SwirlingRing(delay: 2.6, size: 120, isWatch: false)
                        SwirlingRing(delay: 5.3, size: 120, isWatch: false)
                    }
                    Button(action: {
                        let newState = !connectivityManager.isSessionActive
                        connectivityManager.updateSessionState(newState)
                    }) {
                        ZStack {
                            Circle()
                                .frame(width: 120, height: 120)
                                .glassEffect(.regular.interactive())
                            
                            if connectivityManager.isUpdatingSession {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            } else {
                                VStack(spacing: 4) {
                                    Image(systemName: connectivityManager.isSessionActive ? "stop.fill" : "play.fill")
                                        .font(.system(size: 30))
                                    Text(connectivityManager.isSessionActive ? "Stop" : "Start")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(connectivityManager.isUpdatingSession)
                    .animation(.default, value: connectivityManager.isSessionActive)
                    .animation(.default, value: connectivityManager.isUpdatingSession)
                }
                Text(connectivityManager.isSessionActive ? "Monitoring is now running. Feel free to leave the app." : "Press Start to Begin Monitoring")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .animation(.default, value: connectivityManager.isSessionActive)
                Spacer()
                VStack {
                    if let phase = sessionManager.currentPhase {
                        Text("Phase \(phase + 1) of 3")
                    }
                    if sessionManager.secondsLogged != nil {
                        Text(String(format: "%.2f / %.2f hours logged", sessionManager.hoursLoggedDisplay, sessionManager.hoursRequiredDisplay))
                    }
                    if sessionManager.currentPhase != nil &&  !sessionManager.hasCurrentPhaseReflection {
                        Text("1 more reflection needed in this phase.")
                    }
                    if sessionManager.isExperimentComplete {
                        Button("Take Survey") {
                            tabController.open(.survey)
                        }
                        .fontWeight(.bold)
                        .padding()
                        .glassEffect(.regular.tint(.blue).interactive())
                    }
                }
                .animation(.default, value: sessionManager.isLoading)
                .padding(.bottom, 45)
                .foregroundStyle(.white)
                .font(.callout.bold())
            }
        }
        .alert("Apple Watch Not Reachable", isPresented: $connectivityManager.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Open the Cue app on your Apple Watch to manage monitoring.")
        }
    }
}

#Preview {
    ManageView(variant: 3)
        .environmentObject(SessionManager())
        .environmentObject(TabController())
}
