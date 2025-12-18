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

    private let baseURL = URL(string: "https://cue-api.vercel.app")
    private let variantKey = "variantId"
    private let appleUserIdKey = "appleUserId"
    private let userDefaults = UserDefaults.standard

    private var appleUserId: String? {
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
        guard let baseURL = baseURL else {
            errorMessage = "Backend URL is not configured."
            return
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("/api/variant"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["userId": userId])
        isLoading = true
        defer { isLoading = false }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                errorMessage = "Server error."
                return
            }
            let decoded = try JSONDecoder().decode(VariantResponse.self, from: data)
            userDefaults.set(decoded.variant, forKey: variantKey)
            variant = decoded.variant
            errorMessage = nil
        } catch let error {
            print(error.localizedDescription)
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
            let userId = credential.email ?? credential.user
            appleUserId = userId
            Task { await loadVariant() }
        case .failure:
            errorMessage = "Sign in failed."
        }
    }
}

