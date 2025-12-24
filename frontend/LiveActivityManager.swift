//
//  LiveActivityManager.swift
//  Cue
//
//  Created by Jackson Moody on 12/19/25.
//

#if os(iOS)
import Foundation
import ActivityKit
import Combine

class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    private var liveActivity: Activity<CueWidgetAttributes>?
    private var workoutStartDate: Date?
    
    private init() {
        recoverExistingActivity()
    }
    
    private func recoverExistingActivity() {
        let existingActivities = Activity<CueWidgetAttributes>.activities
        if let existingActivity = existingActivities.first {
            liveActivity = existingActivity
            workoutStartDate = existingActivity.content.state.workoutStartDate
        }
    }
    
    func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }
        
        if liveActivity == nil {
            recoverExistingActivity()
        }
        
        // Don't start if live activity already running
        guard liveActivity == nil else {
            return
        }
        
        let startDate = Date()
        workoutStartDate = startDate
        
        let attributes = CueWidgetAttributes(workoutType: "Cue Session")
        let contentState = CueWidgetAttributes.ContentState(workoutStartDate: startDate)
        
        do {
            liveActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    func endLiveActivity() {
        Task {
            guard let activity = liveActivity else { return }
            
            let finalState = CueWidgetAttributes.ContentState(
                workoutStartDate: activity.content.state.workoutStartDate
            )
            
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            
            await MainActor.run {
                self.liveActivity = nil
                self.workoutStartDate = nil
            }
        }
    }
    
    func handleSessionStateChange(_ isActive: Bool) {
        if isActive {
            startLiveActivity()
        } else {
            endLiveActivity()
        }
    }
}
#endif

