//
//  VariantManager.swift
//  Cue
//
//  Created by Jackson Moody on 12/14/25.
//

import Foundation
import SwiftUI
import AuthenticationServices
import Combine

struct VariantResponse: Decodable {
    let userId: String
    let variant: Int
    let order: [Int]?
    let currentPhase: Int?
    let assignedAt: String?
}

class VariantManager: ObservableObject {
    @Published var variant: Int?
    @Published var order: [Int]?
    @Published var currentPhase: Int?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let variantKey = "variantId"
    private let orderKey = "variantOrder"
    private let phaseKey = "variantPhase"
    private let appleUserIdKey = "appleUserId"
    private let fullNameKey = "fullName"
    private let emailKey = "userEmail"
    private let userDefaults = UserDefaults.standard
    private let backendService = BackendService.shared

    var appleUserId: String? {
        get { userDefaults.string(forKey: appleUserIdKey) }
        set { userDefaults.set(newValue, forKey: appleUserIdKey) }
    }

    func loadVariant() async {
        guard let userId = appleUserId else {
            return
        }

        let cachedVariant = userDefaults.object(forKey: variantKey) as? Int
        if let cachedVariant {
            await MainActor.run {
                variant = cachedVariant
                order = userDefaults.array(forKey: orderKey) as? [Int]
                currentPhase = userDefaults.object(forKey: phaseKey) as? Int
            }
        }
        await fetchAndStoreVariant(userId: userId, cachedVariant: cachedVariant)
    }

    private func fetchAndStoreVariant(userId: String, cachedVariant: Int? = nil) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await backendService.post(
                path: "/variant",
                body: ["userId": userId],
                responseType: VariantResponse.self
            )
            userDefaults.set(response.variant, forKey: variantKey)
            if let responseOrder = response.order {
                userDefaults.set(responseOrder, forKey: orderKey)
            }
            if let responsePhase = response.currentPhase {
                userDefaults.set(responsePhase, forKey: phaseKey)
            }

            await MainActor.run {
                if let cachedVariant, cachedVariant != response.variant {
                    userDefaults.set(true, forKey: "instructionsNeeded")
                    userDefaults.set(true, forKey: "variantSwitchPending")
                }
                variant = response.variant
                order = response.order
                currentPhase = response.currentPhase
            }
            errorMessage = nil
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
            if cachedVariant == nil {
                errorMessage = "Failed to fetch variant."
            }
        }
    }

    func switchVariant(newVariant: Int, newPhase: Int) {
        userDefaults.set(newVariant, forKey: variantKey)
        userDefaults.set(newPhase, forKey: phaseKey)
        variant = newVariant
        currentPhase = newPhase
        #if os(watchOS)
        WatchDelegate.scheduleReflectionReminderIfNeeded()
        #endif
    }

    func handleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Missing Apple ID credential."
                return
            }
            appleUserId = credential.user
            if let fullName = credential.fullName, let givenName = fullName.givenName, let familyName = fullName.familyName {
               userDefaults.set("\(givenName) \(familyName)", forKey: fullNameKey)
            }
            if let email = credential.email {
                userDefaults.set(email, forKey: emailKey)
            }
            Task { await loadVariant() }
        case .failure:
            errorMessage = "Sign in failed."
        }
    }
}
