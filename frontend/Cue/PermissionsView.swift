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

enum Occupation: String, CaseIterable, Identifiable {
    case student, employed, unemployed, retired
    var id: Self { self }
}

struct PermissionsView: View {
    @AppStorage("occupation") var selectedOccupation: Occupation = .student
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var variantManager: VariantManager
    @Environment(\.dismiss) private var dismiss
    @Binding var onboardingNeeded: Bool
    
    @State private var isHealthAuthorized: Bool = false
    @State private var isNotificationAuthorized: Bool = false
    @State private var isCalendarAuthorized: Bool = false
    @State private var isLocationAuthorized: Bool = false
    
    var canContinue: Bool {
        isHealthAuthorized && isNotificationAuthorized && isCalendarAuthorized && isLocationAuthorized
    }
    
    let center = UNUserNotificationCenter.current()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .center, spacing: 12) {
                    Text("What is your current occupational status?")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker("Occupation Status:", selection: $selectedOccupation) {
                        Text("Student").tag(Occupation.student)
                        Text("Employed").tag(Occupation.employed)
                        Text("Unemployed").tag(Occupation.unemployed)
                        Text("Retired").tag(Occupation.retired)
                    }
                    .pickerStyle(.segmented)
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
                    
                    PermissionCard(
                        title: "Google Calendar",
                        icon: "calendar",
                        description: "Used to personalize your reflection experience. Please sign in with your most-used account for calendar events.",
                        isAuthorized: isCalendarAuthorized,
                        action: handleGoogleSignIn
                    )
                }
                
                Button(action: handleNext) {
                    HStack {
                        Text("Continue")
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
        .onAppear {
            checkLocationStatus()
            locationManager.onAuthorizationChange = { status in
                DispatchQueue.main.async {
                    checkLocationStatus()
                }
            }
        }
    }
    
    func checkLocationStatus() {
        let status = locationManager.manager.authorizationStatus
        isLocationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways) && locationManager.lastKnownLocation != nil
    }
    
    func handleHealthPermissions() {
        workoutManager.requestAuthorization { authorized in
            isHealthAuthorized = authorized
        }
    }
    
    func handleLocationPermissions() {
        locationManager.checkLocationAuthorization()
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
                
                guard let authData = try? JSONEncoder().encode(["idToken": idToken, "authCode": authCode, "appleIdToken": variantManager.appleUserId]) else {
                    return
                }
                let url = URL(string: "https://cue-api.vercel.app/api/users/sign-in")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let task = URLSession.shared.uploadTask(with: request, from: authData) { data, response, error in
                    guard let data = data else {
                        return
                    }
                    do {
                        let response = try JSONDecoder().decode(Bool.self, from: data)
                        isCalendarAuthorized = response
                    } catch {
                        isCalendarAuthorized = false
                    }
                }
                task.resume()
                
            }
        }
    }
    
    func handleNext() {
        onboardingNeeded = false
        dismiss()
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
    PermissionsView(onboardingNeeded: .constant(false))
        .environmentObject(WorkoutManager())
        .environmentObject(LocationManager())
        .environmentObject(VariantManager())
}
