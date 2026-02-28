//
//  AppView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI

struct AppView: View {
    @StateObject private var tabController = TabController()
    @EnvironmentObject var sessionManager: SessionManager
    let variant: Int
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    
    var manageLabel: String {
        if connectivityManager.isSessionActive {
            "End Monitoring"
        } else {
            "Start Monitoring"
        }
    }

    var body: some View {
        TabView(selection: $tabController.activeTab) {
            Tab("Reflect", systemImage: "apple.meditate", value: TabItem.reflect) {
                ReflectView()
            }
            Tab(manageLabel, systemImage: "applewatch.side.right", value: TabItem.manage) {
                ManageView(variant: variant)
            }
            Tab("Survey", systemImage: "pencil.and.list.clipboard", value: TabItem.survey) {
                SurveyView()
            }
            Tab("Feedback", systemImage: "megaphone.fill", value: TabItem.feedback) {
                FeedbackView()
            }
        }
        .environmentObject(tabController)
        .task {
            await sessionManager.loadSessionCount()
        }
    }
}

#Preview {
    AppView(variant: 3)
        .environmentObject(SessionManager())
        .environmentObject(VariantManager())
        .environmentObject(ReflectionManager())
}
