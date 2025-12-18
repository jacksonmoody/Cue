//
//  WatchConnectivityManager.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isSessionActive: Bool = false
    @Published var isReachable: Bool = false
    @Published var showError: Bool = false
    
    private var session: WCSession?
    private var cancellables = Set<AnyCancellable>()
    
    // Callback for when session state changes (used by watch to control workout)
    var onSessionStateChanged: ((Bool) -> Void)?
    
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
        // If trying to start the session on iOS and Watch is not reachable, prevent it
        guard let session = session, session.activationState == .activated else {
            return
        }
        
        if active && !session.isReachable {
            print("Not starting session because Watch is unreachable.")
            DispatchQueue.main.async {
                self.showError = true            }
            return
        }
        #endif

        DispatchQueue.main.async {
            self.showError = false
        }
        
        sendSessionState(active)
        
        DispatchQueue.main.async {
            let previousState = self.isSessionActive
            self.isSessionActive = active
            if previousState != active {
                self.onSessionStateChanged?(active)
            }
        }
    }
    
    private func sendSessionState(_ active: Bool) {
        guard let session = session, session.activationState == .activated else {
            // Session not activated yet, will sync when activated
            return
        }
        
        guard session.isReachable else {
            // If not reachable, use application context for background updates
            do {
                try session.updateApplicationContext(["isSessionActive": active])
            } catch {
                print("Error updating application context: \(error.localizedDescription)")
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
                }
            }
        )
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
            return
        }
        
        // Load from application context if available (to sync with other device)
        let contextState = session.receivedApplicationContext["isSessionActive"] as? Bool
        let isReachable = session.isReachable
        
        DispatchQueue.main.async {
            self.isReachable = isReachable
            
            if let contextState = contextState {
                let previousState = self.isSessionActive
                self.isSessionActive = contextState
                if previousState != contextState {
                    self.onSessionStateChanged?(contextState)
                }
            }
            
            // Sync current state on activation if reachable
            if isReachable {
                self.sendSessionState(self.isSessionActive)
            }
        }
    }
    
    #if os(iOS)
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated, reactivating...")
        // Reactivate session (iOS only)
        session.activate()
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    #endif
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            
            if session.isReachable {
                // Clear any error messages when watch becomes reachable
                self.showError = false
                self.sendSessionState(self.isSessionActive)
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let active = message["isSessionActive"] as? Bool {
            DispatchQueue.main.async {
                let previousState = self.isSessionActive
                self.isSessionActive = active
                if previousState != active {
                    self.onSessionStateChanged?(active)
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let active = applicationContext["isSessionActive"] as? Bool {
            DispatchQueue.main.async {
                let previousState = self.isSessionActive
                self.isSessionActive = active
                if previousState != active {
                    self.onSessionStateChanged?(active)
                }
            }
        }
    }
}

