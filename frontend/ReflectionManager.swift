//
//  ReflectionManager.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 1/19/26.
//

import Foundation
import Combine

struct Session: Identifiable, Hashable, Codable {
    let id: UUID
    let startDate: Date
    var gear1Finished: Date?
    var gear2Finished: Date?
    var gear3Started: Date?
    var endDate: Date?
    
    var duration: TimeInterval {
        guard let endDate else { return 0 }
        return endDate.timeIntervalSince(startDate)
    }
    
    var gear1: GearOption?
    var gear2: GearOption?
    var gear3: GearOption?
    
    init(startDate: Date) {
        id = UUID()
        self.startDate = startDate
        self.gear1Finished = nil
        self.gear2Finished = nil
        self.gear3Started = nil
        self.endDate = nil
        
        self.gear1 = nil
        self.gear2 = nil
        self.gear3 = nil
    }
}

struct GearOption: Identifiable, Equatable, Hashable, Codable {
    var id: UUID
    var text: String
    var icon: String
    
    init(id: UUID = UUID(), text: String, icon: String) {
        self.id = id
        self.text = text
        self.icon = icon
    }
    
    public static func == (lhs: GearOption, rhs: GearOption) -> Bool {
        lhs.text == rhs.text
    }
}

struct Preferences: Codable, Equatable {
    var gear2Options: [GearOption]
    var gear3Options: [GearOption]
    
    enum CodingKeys: String, CodingKey {
        case gear2Options = "gear2"
        case gear3Options = "gear3"
    }
}

class ReflectionManager: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var preferences: Preferences?
    @Published var errorMessage: String?
    @Published var gear1Options: [GearOption] = []
    var currentSession: Session?
    
    private let backendService = BackendService.shared
    private let userDefaults = UserDefaults.standard
    var variantManager: VariantManager?
    
    let reflectionsKey = "reflections"
    let preferencesKey = "preferences"
    
    func startNewSession() {
        do {
            currentSession = Session(startDate: Date())
            guard let userId = variantManager?.appleUserId else {
                return
            }
            let reflectionData = try JSONEncoder().encode(currentSession)
            guard let reflectionDict = try JSONSerialization.jsonObject(with: reflectionData) as? [String: Any] else {
                print("Failed to convert reflection to dictionary")
                return
            }
            let sessionData: [String: Any] = [
                "userId": userId,
                "reflection": reflectionDict
            ]
            backendService.post(path: "/reflections", body: sessionData) { result in
                switch result {
                case .success:
                    return
                case .failure(let error):
                    print("Failed to record session: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error encoding session: \(error.localizedDescription)")
        }
    }
    
    func logGearSelection(_ gear: GearOption, forGear gearNumber: Int, atDate date: Date) {
        guard var currentSession else { return }
        switch gearNumber {
        case 1:
            currentSession.gear1 = gear
            currentSession.gear1Finished = date
        case 2:
            currentSession.gear2 = gear
            currentSession.gear2Finished = date
        case 3:
            currentSession.gear3 = gear
            currentSession.gear3Started = date
        default:
            return
        }
        self.currentSession = currentSession
    }
    
    func endCurrentSession(atDate date: Date) {
        guard var currentSession else { return }
        currentSession.endDate = date
        
        guard let userId = variantManager?.appleUserId else {
            print("Cannot record session: userId not available")
            self.currentSession = nil
            return
        }
        
        do {
            let reflectionData = try JSONEncoder().encode(currentSession)
            guard let reflectionDict = try JSONSerialization.jsonObject(with: reflectionData) as? [String: Any] else {
                print("Failed to convert reflection to dictionary")
                self.currentSession = nil
                return
            }
            
            let sessionData: [String: Any] = [
                "userId": userId,
                "reflection": reflectionDict
            ]
            backendService.post(path: "/reflections/update", body: sessionData) { result in
                switch result {
                case .success:
                    self.currentSession = nil
                case .failure(let error):
                    print("Failed to record session: \(error.localizedDescription)")
                    self.currentSession = nil
                }
            }
        } catch {
            print("Error encoding session: \(error.localizedDescription)")
            self.currentSession = nil
        }
    }
    
    func updateSession(_ session: Session) {
        guard let userId = variantManager?.appleUserId else {
            return
        }
        do {
            let reflectionData = try JSONEncoder().encode(session)
            guard let reflectionDict = try JSONSerialization.jsonObject(with: reflectionData) as? [String: Any] else {
                print("Failed to convert reflection to dictionary")
                self.currentSession = nil
                return
            }
            let sessionData: [String: Any] = [
                "userId": userId,
                "reflection": reflectionDict
            ]
            backendService.post(path: "/reflections/update", body: sessionData) { result in
                switch result {
                case .success:
                    return
                case .failure(let error):
                    print("Failed to record session: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error encoding session: \(error.localizedDescription)")
        }
    }
    
    func fetchGear1Options() async {
        guard let userId = variantManager?.appleUserId else {
            return
        }
        let userData: [String: Any] = [
            "idToken": userId,
            "location": "home" // TODO: Update this
        ]
        do {
            let response = try await backendService.post(
                path: "/gear1",
                body: userData,
                responseType: [GearOption].self
            )
            gear1Options = response
            errorMessage = nil
        } catch {
            print("Failed to fetch gear1 options: \(error.localizedDescription)")
        }
    }
    
    func loadReflections() async {
        guard let userId = variantManager?.appleUserId else {
            return
        }

        if let data = userDefaults.data(forKey: reflectionsKey),
           let cachedSessions = try? JSONDecoder().decode([Session].self, from: data) {
            sessions = cachedSessions
        }
        await fetchAndStoreReflections(userId: userId)
    }

    private func fetchAndStoreReflections(userId: String) async {
        let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userId
        do {
            let response = try await backendService.get(
                path: "/reflections/\(encodedUserId)",
                responseType: [Session].self
            )
            if let encoded = try? JSONEncoder().encode(response) {
                userDefaults.set(encoded, forKey: reflectionsKey)
            }
            sessions = response
            errorMessage = nil
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
            errorMessage = "Failed to fetch reflections."
        }
    }
    
    func loadPreferences() async {
        guard let userId = variantManager?.appleUserId else {
            return
        }
        
        if let data = userDefaults.data(forKey: preferencesKey),
           let cachedPreferences = try? JSONDecoder().decode(Preferences.self, from: data) {
            preferences = cachedPreferences
        }
        
        await fetchAndStorePreferences(userId: userId)
    }
    
    func fetchAndStorePreferences(userId: String) async {
        let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userId
        do {
            let response = try await backendService.get(
                path: "/preferences/\(encodedUserId)",
                responseType: Preferences.self
            )
            if let encoded = try? JSONEncoder().encode(response) {
                userDefaults.set(encoded, forKey: preferencesKey)
            }
            preferences = response
            errorMessage = nil
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
            errorMessage = "Failed to fetch preferences."
        }
    }
    
    func saveGear2Preferences(_ options: [GearOption]) async {
        guard let userId = variantManager?.appleUserId else {
            return
        }
        
        let gear2Preferences = options.map { option in
            [
                "id": option.id.uuidString,
                "text": option.text,
                "icon": option.icon
            ]
        }
        
        do {
            let body: [String: Any] = [
                "userId": userId,
                "gear2Preferences": gear2Preferences
            ]
            
            try await backendService.post(
                path: "/preferences/gear2",
                body: body
            )
            
            if var currentPreferences = preferences {
                currentPreferences.gear2Options = options
                preferences = currentPreferences
                if let encoded = try? JSONEncoder().encode(currentPreferences) {
                    userDefaults.set(encoded, forKey: preferencesKey)
                }
            } else {
                let newPreferences = Preferences(gear2Options: options, gear3Options: [])
                preferences = newPreferences
                if let encoded = try? JSONEncoder().encode(newPreferences) {
                    userDefaults.set(encoded, forKey: preferencesKey)
                }
            }
            errorMessage = nil
        } catch {
            print("Error saving gear2 preferences: \(error.localizedDescription)")
            errorMessage = "Failed to save preferences."
        }
    }
    
    func saveGear3Preferences(_ options: [GearOption]) async {
        guard let userId = variantManager?.appleUserId else {
            return
        }
        
        let gear3Preferences = options.map { option in
            [
                "id": option.id.uuidString,
                "text": option.text,
                "icon": option.icon
            ]
        }
        
        do {
            let body: [String: Any] = [
                "userId": userId,
                "gear3Preferences": gear3Preferences
            ]
            
            try await backendService.post(
                path: "/preferences/gear3",
                body: body
            )
            
            if var currentPreferences = preferences {
                currentPreferences.gear3Options = options
                preferences = currentPreferences
                if let encoded = try? JSONEncoder().encode(currentPreferences) {
                    userDefaults.set(encoded, forKey: preferencesKey)
                }
            } else {
                let newPreferences = Preferences(gear2Options: [], gear3Options: options)
                preferences = newPreferences
                if let encoded = try? JSONEncoder().encode(newPreferences) {
                    userDefaults.set(encoded, forKey: preferencesKey)
                }
            }
            errorMessage = nil
        } catch {
            print("Error saving gear3 preferences: \(error.localizedDescription)")
            errorMessage = "Failed to save preferences."
        }
    }
}

