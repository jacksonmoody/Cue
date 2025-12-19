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
    let assignedAt: String?
}

class VariantManager: ObservableObject {
    @Published var variant: Int?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let variantKey = "variantId"
    private let appleUserIdKey = "appleUserId"
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

        if let cachedVariant = userDefaults.object(forKey: variantKey) as? Int {
            variant = cachedVariant
            return
        }
        await fetchAndStoreVariant(userId: userId)
    }

    private func fetchAndStoreVariant(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await backendService.post(
                path: "/api/variant",
                body: ["userId": userId],
                responseType: VariantResponse.self
            )
            userDefaults.set(response.variant, forKey: variantKey)
            variant = response.variant
            errorMessage = nil
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
            errorMessage = "Failed to fetch variant."
        }
    }


    func handleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Missing Apple ID credential."
                return
            }
            if let fullName = credential.fullName, let givenName = fullName.givenName, let familyName = fullName.familyName {
                appleUserId = "\(givenName) \(familyName)"
            } else if let email = credential.email {
                appleUserId = email
            } else {
                appleUserId = credential.user
            }
            Task { await loadVariant() }
        case .failure:
            errorMessage = "Sign in failed."
        }
    }
}

