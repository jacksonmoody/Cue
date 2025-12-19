//
//  ManageView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI

struct ManageView: View {
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    @EnvironmentObject var variantManager: VariantManager
    @State private var sessionCount: Int = 0
    @State private var isLoadingCount: Bool = false
    let backendService = BackendService.shared
    
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
                        withAnimation {
                            connectivityManager.updateSessionState(newState)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .frame(width: 120, height: 120)
                                .glassEffect(.regular.interactive())
                            
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
                    if isLoadingCount {
                        Text("Loading...")
                    } else {
                        Text("\(sessionCount) Sessions Recorded")
                        if sessionCount == 0 {
                            Text("1 More Needed to Unlock Survey")
                        } else {
                            Text("Survey Unlocked!")
                        }
                    }
                    Text("Variant: \(String(variantManager.variant ?? 0))")
                        .padding(.bottom, 45)
                }
                .foregroundStyle(.white)
                .font(.callout.bold())
            }
        }
        .task {
            await loadSessionCount()
        }
        .onChange(of: connectivityManager.isSessionActive) { oldValue, newValue in
            if !newValue {
                Task {
                    await loadSessionCount()
                }
            }
        }
        .alert("Apple Watch Not Reachable", isPresented: $connectivityManager.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please open the Cue app on your Apple Watch to start the session.")
        }
    }
    
    private func loadSessionCount() async {
        guard let userId = variantManager.appleUserId else {
            return
        }
        
        isLoadingCount = true
        defer { isLoadingCount = false }
        
        do {
            let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userId
            let response = try await backendService.get(
                path: "/api/sessions/\(encodedUserId)/count",
                responseType: SessionCountResponse.self
            )
            await MainActor.run {
                sessionCount = response.count
            }
        } catch {
            print("Failed to load session count: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ManageView()
        .environmentObject(VariantManager())
}
