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
    
    var body: some View {
        TabView(selection: $tabController.activeTab) {
            Tab("Manage", systemImage: "applewatch.side.right", value: TabItem.manage) {
                ManageView(variant: variant)
            }
            Tab("Survey", systemImage: "pencil.and.list.clipboard", value: TabItem.survey) {
                SurveyView()
            }
            Tab("Feedback", systemImage: "megaphone.fill", value: TabItem.feedback) {
                FeedbackView()
            }
            Tab("Help", systemImage: "questionmark.circle", value: TabItem.help, role: .search) {
                InstructionsView(onboardingNeeded: .constant(false), refresher: true)
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
}
