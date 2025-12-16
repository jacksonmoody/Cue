//
//  ManageView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI
struct ManageView: View {
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    
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
                        withAnimation {
                            connectivityManager.updateSessionState(!connectivityManager.isSessionActive)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Material.ultraThinMaterial)
                                .frame(width: 120, height: 120)
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                            
                            Circle()
                                .strokeBorder(.white.opacity(0.5), lineWidth: 1)
                                .frame(width: 120, height: 120)
                            
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
                Text(connectivityManager.isSessionActive ? "Your session is running. Feel free to close the app." : "Press Start to Begin Monitoring")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
                Group {
                    Text("x 5 Hour Sessions Recorded")
                    Text("x More Needed to Unlock Survey")
                        .padding(.bottom, 45)
                }
                .foregroundStyle(.white)
                .font(.callout.bold())
            }
        }
    }
}

#Preview {
    ManageView()
}
