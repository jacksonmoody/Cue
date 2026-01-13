//
//  WatchConnectivityManager.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import Foundation
import WatchConnectivity
import Combine
import HealthKit

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    let healthStore = HKHealthStore()
    
    @Published var isSessionActive: Bool = false
    @Published var isReachable: Bool = false
    @Published var showError: Bool = false
    @Published var isUpdatingSession: Bool = false
    
    private var session: WCSession?
    private var cancellables = Set<AnyCancellable>()
    
    // Callback for when session state changes (used by watch to control workout)
    var onSessionStateChanged: ((Bool) -> Void)?
    
    // Callback for when a session is recorded (used by iOS to update session count)
    var onSessionRecorded: (() -> Void)?

    // Callback when iOS onboarding finishes so watch can refresh
    var onOnboardingCompleted: (() -> Void)?
    
    private override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else {
            print("Watch Connectivity is not supported on this device")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    func updateSessionState(_ active: Bool) {
        #if os(iOS)
        DispatchQueue.main.async {
            self.isUpdatingSession = true
        }
        // If trying to start the session on iOS and Watch is not reachable, open Watch app
        if let session, !session.isReachable || session.activationState != .activated {
            self.healthStore.startWatchApp(with: HKWorkoutConfiguration(), completion: { (success, error) in
                print("Starting Watch App in background: \(success), error: \(String(describing: error))")
                if !success {
                    DispatchQueue.main.async {
                        self.showError = true
                        self.isUpdatingSession = false
                        return
                    }
                }
            })
        } else {
            // Watch is reachable, send directly
            sendSessionState(active)
        }
        #else
        // Always send session state on Watch
        sendSessionState(active)
        DispatchQueue.main.async {
            let previousState = self.isSessionActive
            self.isSessionActive = active
            if previousState != active {
                self.onSessionStateChanged?(active)
            }
        }
        #endif
    }
    
    private func sendSessionState(_ active: Bool) {
        guard let session = session, session.activationState == .activated else {
            // Session not activated yet, will sync when activated
            DispatchQueue.main.async {
                self.isUpdatingSession = false
            }
            return
        }
        
        guard session.isReachable else {
            // If not reachable, use application context for background updates
            do {
                try session.updateApplicationContext(["isSessionActive": active])
            } catch {
                print("Error updating application context: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isUpdatingSession = false
                }
            }
            return
        }
        
        session.sendMessage(
            ["isSessionActive": active],
            replyHandler: nil,
            errorHandler: { error in
                print("Error sending session state: \(error.localizedDescription)")
                do {
                    try session.updateApplicationContext(["isSessionActive": active])
                } catch {
                    print("Error updating application context as fallback: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isUpdatingSession = false
                    }
                }
            }
        )
    }
    
    func notifySessionRecorded() {
        guard let session = session, session.activationState == .activated else {
            return
        }
        
        let message = ["sessionRecorded": true]
        
        guard session.isReachable else {
            do {
                try session.updateApplicationContext(message)
            } catch {
                print("Error updating application context: \(error.localizedDescription)")
            }
            return
        }
        
        session.sendMessage(
            message,
            replyHandler: nil,
            errorHandler: { error in
                print("Error sending session recorded message: \(error.localizedDescription)")
                do {
                    try session.updateApplicationContext(message)
                } catch {
                    print("Error updating application context as fallback: \(error.localizedDescription)")
                }
            }
        )
    }

    func notifyOnboardingCompleted() {
        guard let session = session, session.activationState == .activated else {
            return
        }

        let message = ["onboardingCompleted": true]

        guard session.isReachable else {
            do {
                try session.updateApplicationContext(message)
            } catch {
                print("Error updating application context: \(error.localizedDescription)")
            }
            return
        }

        session.sendMessage(
            message,
            replyHandler: nil,
            errorHandler: { error in
                print("Error sending onboarding completed message: \(error.localizedDescription)")
                do {
                    try session.updateApplicationContext(message)
                } catch {
                    print("Error updating application context as fallback: \(error.localizedDescription)")
                }
            }
        )
    }
    
    private func requestCurrentSessionState() {
        #if os(iOS)
        guard let session = session, session.activationState == .activated, session.isReachable else {
            // If watch is not reachable, default to false (session not active)
            DispatchQueue.main.async {
                if self.isSessionActive {
                    self.isSessionActive = false
                    self.onSessionStateChanged?(false)
                }
            }
            return
        }
        
        session.sendMessage(
            ["requestSessionState": true],
            replyHandler: { reply in
                if let active = reply["isSessionActive"] as? Bool {
                    DispatchQueue.main.async {
                        let previousState = self.isSessionActive
                        self.isSessionActive = active
                        if previousState != active {
                            self.onSessionStateChanged?(active)
                        }
                    }
                }
            },
            errorHandler: { error in
                print("Error requesting session state: \(error.localizedDescription)")
                // On error, default to false (session not active)
                DispatchQueue.main.async {
                    if self.isSessionActive {
                        self.isSessionActive = false
                        self.onSessionStateChanged?(false)
                    }
                }
            }
        )
        #endif
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
            return
        }
        
        let isReachable = session.isReachable
        
        DispatchQueue.main.async {
            self.isReachable = isReachable
            
            #if os(iOS)
            if isReachable {
                self.requestCurrentSessionState()
            } else {
                if self.isSessionActive {
                    self.isSessionActive = false
                    self.onSessionStateChanged?(false)
                }
            }
            #else
            let contextState = session.receivedApplicationContext["isSessionActive"] as? Bool
            if let contextState = contextState {
                let previousState = self.isSessionActive
                self.isSessionActive = contextState
                if previousState != contextState {
                    self.onSessionStateChanged?(contextState)
                }
            }
            
            if isReachable {
                self.sendSessionState(self.isSessionActive)
            }
            #endif
        }
    }
    
    #if os(iOS)
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated, reactivating...")
        session.activate()
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    #endif
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            let wasReachable = self.isReachable
            self.isReachable = session.isReachable
            
            #if os(iOS)
            if !wasReachable && session.isReachable {
                self.requestCurrentSessionState()
            }
            #endif
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let active = message["isSessionActive"] as? Bool {
            DispatchQueue.main.async {
                let previousState = self.isSessionActive
                self.isSessionActive = active
                self.isUpdatingSession = false
                if previousState != active {
                    self.onSessionStateChanged?(active)
                }
            }
        }
        
        if let _ = message["sessionRecorded"] as? Bool {
            DispatchQueue.main.async {
                self.onSessionRecorded?()
            }
        }

        if let _ = message["onboardingCompleted"] as? Bool {
            DispatchQueue.main.async {
                self.onOnboardingCompleted?()
            }
        }
    }
    
    #if os(watchOS)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let _ = message["requestSessionState"] as? Bool {
            let reply = ["isSessionActive": self.isSessionActive]
            replyHandler(reply)
            return
        }
        self.session(session, didReceiveMessage: message)
    }
    #endif
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let active = applicationContext["isSessionActive"] as? Bool {
            DispatchQueue.main.async {
                let previousState = self.isSessionActive
                self.isSessionActive = active
                self.isUpdatingSession = false
                if previousState != active {
                    self.onSessionStateChanged?(active)
                }
            }
        }
        
        if let _ = applicationContext["sessionRecorded"] as? Bool {
            DispatchQueue.main.async {
                self.onSessionRecorded?()
            }
        }

        if let _ = applicationContext["onboardingCompleted"] as? Bool {
            DispatchQueue.main.async {
                self.onOnboardingCompleted?()
            }
        }
    }
}

