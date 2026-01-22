//
//  PermissionsView.swift
//  Cue
//
//  Created by Jackson Moody on 12/28/25.
//

import SwiftUI
import GoogleSignInSwift
import GoogleSignIn
internal import CoreLocation

struct PermissionsView: View {
    @AppStorage("occupation") var occupation: String = ""
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var variantManager: VariantManager
    @Environment(\.dismiss) private var dismiss
    @Binding var instructionsNeeded: Bool
    
    @State private var isHealthAuthorized: Bool = false
    @State private var isNotificationAuthorized: Bool = false
    @State private var isCalendarAuthorized: Bool = false
    @State private var isLocationAuthorized: Bool = false
    
    @State private var showError: Bool = false
    
    var canContinue: Bool {
        isHealthAuthorized && isNotificationAuthorized && isCalendarAuthorized && isLocationAuthorized
    }
    
    let center = UNUserNotificationCenter.current()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .center, spacing: 12) {
                    Text("What is your current occupation?")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("e.g. Student, Software Engineer, Retired", text: $occupation)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Required Permissions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("The following permissions are required in order to participate in this experiment. If you have any questions about your data or how it will be used, please reach out via the app's \"Feedback\" tab.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, -5)
                    
                    PermissionCard(
                        title: "Health Permissions",
                        icon: "heart.fill",
                        description: "Access to health data for biometric tracking.",
                        isAuthorized: isHealthAuthorized,
                        action: handleHealthPermissions
                    )
                    
                    PermissionCard(
                        title: "Notification Permissions",
                        icon: "bell.fill",
                        description: "Used to send reminders to reflect.",
                        isAuthorized: isNotificationAuthorized,
                        action: handleNotificationPermissions
                    )
                    
                    PermissionCard(
                        title: "Location Permissions",
                        icon: "location.fill",
                        description: "Used to personalize your reflection experience.",
                        isAuthorized: isLocationAuthorized,
                        action: handleLocationPermissions
                    )
                    
                    VStack(spacing: 20) {
                        Text("Sign in with Google to personalize your reflection experience with events from your Google Calendar:")
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                        GoogleSignInButton {
                            handleGoogleSignIn()
                        }
                    }
                    .padding(.horizontal)
                    
//                    PermissionCard(
//                        title: "Google Calendar",
//                        icon: "calendar",
//                        description: "Used to personalize your reflection experience. Please sign in with your most-used account for calendar events.",
//                        isAuthorized: isCalendarAuthorized,
//                        action: handleGoogleSignIn
//                    )
                }
                
                Button(action: handleNext) {
                    HStack {
                        Text("Get Started")
                            .fontWeight(.semibold)
                        if canContinue {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canContinue ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(canContinue ? .white : .gray)
                    .cornerRadius(12)
                }
                .disabled(!canContinue)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("App Setup")
        .alert("Unable to Set Up Cue", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Ensure that you are connected to the Internet and try again.")
        }
        .onAppear {
            checkLocationStatus()
            locationService.onAuthorizationChange = { status in
                DispatchQueue.main.async {
                    checkLocationStatus()
                }
            }
        }
    }
    
    func checkLocationStatus() {
        let status = locationService.locationManager.authorizationStatus
        isLocationAuthorized = (status == .authorizedAlways)
    }
    
    func handleHealthPermissions() {
        workoutManager.requestAuthorization { authorized in
            isHealthAuthorized = authorized
        }
    }
    
    func handleLocationPermissions() {
        locationService.start()
    }
    
    func handleNotificationPermissions() {
        Task {
            let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isNotificationAuthorized = granted ?? false
            }
        }
    }
    
    func handleGoogleSignIn() {
        let additionalScopes = [
            "https://www.googleapis.com/auth/calendar.readonly",
            "https://www.googleapis.com/auth/userinfo.email",
            "https://www.googleapis.com/auth/userinfo.profile",
        ]
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("There is no active window scene")
            return
        }
        guard let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("There is no key window or root view controller")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: "",
            additionalScopes: additionalScopes
        ) { result1, error in
            guard let result1 = result1 else {
                print("Error signing in: \(error?.localizedDescription ?? "")")
                isCalendarAuthorized = false
                return
            }
            result1.user.refreshTokensIfNeeded { user, error in
                guard error == nil else {
                    isCalendarAuthorized = false
                    return
                }
                guard let user = user else {
                    isCalendarAuthorized = false
                    return
                }
                let authCode = result1.serverAuthCode
                let idToken = user.idToken?.tokenString
                
                guard let idToken = idToken, let authCode = authCode, let appleIdToken = variantManager.appleUserId else {
                    isCalendarAuthorized = false
                    return
                }
                
                Task {
                    do {
                        let response = try await BackendService.shared.post(
                            path: "/users/sign-in",
                            body: [
                                "idToken": idToken,
                                "authCode": authCode,
                                "appleIdToken": appleIdToken
                            ],
                            responseType: Bool.self
                        )
                        await MainActor.run {
                            isCalendarAuthorized = response
                        }
                    } catch {
                        await MainActor.run {
                            isCalendarAuthorized = false
                        }
                    }
                }
                
            }
        }
    }
    
    func handleNext() {
        if let userId = variantManager.appleUserId {
            Task {
                do {
                    let response = try await BackendService.shared.post(
                        path: "/users/finish-onboarding",
                        body: [
                            "userId": userId,
                            "occupation": occupation
                        ],
                        responseType: Bool.self
                    )
                    if (response) {
                        WatchConnectivityManager.shared.notifyOnboardingCompleted()
                        instructionsNeeded = false
                        dismiss()
                    } else {
                        print("Failed to finish onboarding")
                        showError = true
                    }
                } catch {
                    print("Failed to finish onboarding: \(error.localizedDescription)")
                    showError = true
                }
            }
        }
    }
}

struct PermissionCard: View {
    let title: String
    let icon: String
    let description: String
    let isAuthorized: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: statusIcon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(statusColor)
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(cardBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusIcon: String {
        isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    private var statusColor: Color {
        isAuthorized ? .green : .orange
    }
    
    private var iconBackgroundColor: Color {
        isAuthorized ? Color.green.opacity(0.2) : Color.orange.opacity(0.2)
    }
    
    private var iconColor: Color {
        isAuthorized ? .green : .orange
    }
    
    private var cardBackgroundColor: Color {
        isAuthorized ? Color.green.opacity(0.05) : Color.orange.opacity(0.05)
    }
    
    private var borderColor: Color {
        isAuthorized ? Color.green.opacity(0.3) : Color.orange.opacity(0.3)
    }
}

#Preview {
    PermissionsView(instructionsNeeded: .constant(false))
        .environmentObject(WorkoutManager())
        .environmentObject(LocationService())
        .environmentObject(VariantManager())
}
