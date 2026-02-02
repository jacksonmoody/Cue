//
//  SessionManager.swift
//  Cue
//
//  Created by Jackson Moody on 12/19/25.
//

import Foundation
import Combine

struct SessionCountResponse: Decodable {
    let sessionCount: Int
    let reflectionCount: Int
}

class SessionManager: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let backendService = BackendService.shared
    private let sessionCountKey = "sessionCount"
    var variantManager: VariantManager?
    
    @Published var sessionCount: Int?
    @Published var reflectionCount: Int?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    var sessionsRemaining: Int? {
        if let sessionCount {
            return max(5 - sessionCount, 0)
        }
        return nil
    }
    
    func loadSessionCount() async {
        guard let userId = variantManager?.appleUserId else {
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userId
            let response = try await backendService.get(
                path: "/sessions/\(encodedUserId)/count",
                responseType: SessionCountResponse.self
            )
            sessionCount = response.sessionCount
            reflectionCount = response.reflectionCount
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
