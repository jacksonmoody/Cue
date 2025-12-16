//
//  AppView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI

struct AppView: View {
    var body: some View {
        TabView {
            Tab("Manage", systemImage: "applewatch.side.right") {
                ManageView()
            }
            Tab("Survey", systemImage: "pencil.and.list.clipboard") {
                SurveyView()
            }
            Tab("Help", systemImage: "questionmark.circle", role: .search) {
                FeedbackView()
            }
        }
    }
}

#Preview {
    AppView()
}
