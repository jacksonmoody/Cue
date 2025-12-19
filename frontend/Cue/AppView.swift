//
//  AppView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI

struct AppView: View {
    @StateObject private var tabController = TabController()
    
    var body: some View {
        TabView(selection: $tabController.activeTab) {
            ManageView()
                .tabItem {
                    Label("Manage", systemImage: "applewatch.side.right")
                }
                .tag(Tab.manage)
            
            SurveyView()
                .tabItem {
                    Label("Survey", systemImage: "pencil.and.list.clipboard")
                }
                .tag(Tab.survey)
            
            FeedbackView()
                .tabItem {
                    Label("Help", systemImage: "questionmark.circle")
                }
                .tag(Tab.help)
        }
        .environmentObject(tabController)
    }
}

#Preview {
    AppView()
}
