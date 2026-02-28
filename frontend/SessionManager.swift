//
//  SessionManager.swift
//  Cue
//
//  Created by Jackson Moody on 12/19/25.
//

import Foundation
import Combine

struct SessionCountResponse: Decodable {
    let currentPhase: Int
    let secondsLogged: Double
    let hoursRequired: Double
    let experimentComplete: Bool
    let reflectionCount: Int
    let reflectionsComplete: Bool?
}

class SessionManager: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let backendService = BackendService.shared
    var variantManager: VariantManager?
    
    @Published var currentPhase: Int?
    @Published var secondsLogged: Double?
    @Published var hoursRequired: Double?
    @Published var experimentComplete: Bool?
    @Published var reflectionCount: Int?
    @Published var reflectionsComplete: Bool?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    var hoursLoggedDisplay: Double {
        guard let secondsLogged else { return 0 }
        return secondsLogged / 3600.0
    }
    
    var hoursRequiredDisplay: Double {
        guard let hoursRequired else { return 8.0 }
        return hoursRequired / 3600.0
    }
    
    var hoursRemaining: Double {
        guard let secondsLogged, let hoursRequired else { return 8.0 }
        return max(0, (hoursRequired - secondsLogged) / 3600.0)
    }
    
    var isExperimentComplete: Bool {
        experimentComplete ?? false
    }
    
    var hasCurrentPhaseReflection: Bool {
        (reflectionCount ?? 0) >= 1
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
            currentPhase = response.currentPhase
            secondsLogged = response.secondsLogged
            hoursRequired = response.hoursRequired
            experimentComplete = response.experimentComplete
            reflectionCount = response.reflectionCount
            reflectionsComplete = response.reflectionsComplete
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
