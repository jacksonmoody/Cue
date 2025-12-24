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
                Text(connectivityManager.isSessionActive ? "Your session is running. Feel free to leave the app." : "Press Start to Begin Monitoring")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .animation(.default, value: connectivityManager.isSessionActive)
                Spacer()
                VStack {
                    Text("Variant: \(variant)")
                    if let sessionsCount = sessionManager.sessionCount, let sessionsRemaining = sessionManager.sessionsRemaining, sessionsRemaining > 0 {
                        Text("^[\(sessionsCount) Valid Sessions](inflect: true) Recorded")
                        Text("\(sessionsRemaining) More Needed to Unlock Survey")
                    }
                    if let sessionsRemaining = sessionManager.sessionsRemaining, sessionsRemaining == 0 {
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
            Text("Please open the Cue app on your Apple Watch to manage the session.")
        }
    }
}

#Preview {
    ManageView(variant: 3)
        .environmentObject(SessionManager())
        .environmentObject(TabController())
}
