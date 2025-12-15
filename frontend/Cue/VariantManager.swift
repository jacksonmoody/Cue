//
//  VariantManager.swift
//  Cue
//
//  Created by Jackson Moody on 12/14/25.
//

import Foundation
import SwiftUI
import Combine

struct VariantResponse: Decodable {
    let userId: String
    let variant: Int
    let assignedAt: String?
}

@MainActor
final class VariantManager: ObservableObject {
    @Published var variant: Int?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let appGroupId = "group.com.jacksonmoody.cue"
    private let userIdKey = "variantUserId"
    private let variantKey = "variantId"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    private var backendBaseURL: URL? {
        if let env = ProcessInfo.processInfo.environment["BACKEND_BASE_URL"],
           let url = URL(string: env) {
            return url
        }
        return URL(string: "http://localhost:3000")
    }

    func loadVariant() async {
        guard let defaults = userDefaults else {
            errorMessage = "Unable to access app group storage."
            return
        }

        if let cachedVariant = defaults.object(forKey: variantKey) as? Int {
            variant = cachedVariant
            return
        }

        let existingId = defaults.string(forKey: userIdKey)
        let userId = existingId ?? UUID().uuidString
        if existingId == nil {
            defaults.set(userId, forKey: userIdKey)
        }

        await fetchAndStoreVariant(userId: userId, defaults: defaults)
    }

    private func fetchAndStoreVariant(userId: String, defaults: UserDefaults) async {
        guard let baseURL = backendBaseURL else {
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
            defaults.set(decoded.variant, forKey: variantKey)
            defaults.set(decoded.userId, forKey: userIdKey)
            variant = decoded.variant
            errorMessage = nil
        } catch {
            errorMessage = "Failed to fetch variant."
        }
    }
}

