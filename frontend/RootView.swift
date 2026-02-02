//
//  RootView.swift
//  Cue
//
//  Created by Jackson Moody on 12/14/25.
//  Manages the login/onboarding/instructions flow

import SwiftUI
import AuthenticationServices

struct RootView: View {
    @EnvironmentObject var variantManager: VariantManager
    @AppStorage("instructionsNeeded") private var instructionsNeeded = true
    @State private var watchOnboardingLoading = false
    #if os(watchOS)
    @AppStorage("phoneOnboardingCompleted") private var phoneOnboardingCompleted = false
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    #endif
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            if shouldShowApp {
                AppView(variant: variantManager.variant!)
                    .sheet(isPresented: $instructionsNeeded) {
                        InstructionsView(instructionsNeeded: $instructionsNeeded, refresher: false)
                            .toolbar(content: {
                               ToolbarItem(placement: .cancellationAction) {
                                  Text("")
                               }
                            })
                            .interactiveDismissDisabled()
                    }
            } else if variantManager.isLoading || watchOnboardingLoading {
                ProgressView()
            } else {
                #if os(watchOS)
                if variantManager.variant != nil && !phoneOnboardingCompleted {
                    IncompleteOnboarding()
                } else {
                    LoginView()
                }
                #else
                LoginView()
                #endif
            }
        }
        .task {
            await variantManager.loadVariant()
            #if os(watchOS)
            WatchDelegate.scheduleReflectionReminderIfNeeded()
            await checkOnboardingStatus()
            #endif
        }
        .onAppear {
            #if os(watchOS)
            connectivityManager.onOnboardingCompleted = {
                Task {
                    await checkOnboardingStatus()
                }
            }
            #endif
        }
        .onChange(of: variantManager.appleUserId) { _, newValue in
            #if os(watchOS)
            if newValue != nil {
                Task {
                    await checkOnboardingStatus()
                }
            }
            #endif
        }
         
    }
    
    private var shouldShowApp: Bool {
        #if os(watchOS)
        return variantManager.variant != nil && phoneOnboardingCompleted
        #else
        return variantManager.variant != nil
        #endif
    }
    
    #if os(watchOS)
    private func checkOnboardingStatus() async {
        guard let userId = variantManager.appleUserId else {
            watchOnboardingLoading = false
            return
        }
        
        if phoneOnboardingCompleted {
            return
        }
        
        watchOnboardingLoading = true

        do {
            let response = try await BackendService.shared.get(
                path: "/users/onboarded/\(userId)",
                responseType: OnboardingStatusResponse.self
            )
            phoneOnboardingCompleted = response.onboarded ?? false
        } catch {
            print("Error checking onboarding status: \(error)")
            phoneOnboardingCompleted = false
        }
        watchOnboardingLoading = false
    }
    #endif
}

struct OnboardingStatusResponse: Decodable {
    let onboarded: Bool?
}

#Preview {
    RootView()
        .environmentObject(VariantManager())
}
