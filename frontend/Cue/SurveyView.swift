//
//  SurveyView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI

struct SurveyView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var isSurveyUnlocked: Bool {
        !sessionManager.isLoading && sessionManager.sessionsRemaining == 0
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            Group {
                if isSurveyUnlocked {
                    Survey()
                        .padding(.vertical, 20)
                        .padding(.horizontal)
                } else {
                    Survey()
                        .padding(30)
                }
            }
            .foregroundStyle(.white)
        }
    }
}

struct Survey: View {
    @EnvironmentObject var variantManager: VariantManager
    
    var firstName: String? {
        let components =   variantManager.appleUserId?.split(separator: " ")
        if let components, components.count > 0 {
            return String(components[0])
        }
        return nil
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text((firstName != nil) ? "Thank you for your participation, \(firstName!)!" : "Thank you for your participation!")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Before beginning, please ensure that both your iOS Cue App and watchOS Cue App report that you are in Variant \(String(variantManager.variant ?? -1)). If they do not agree, report the issue via the \"Feedback\" tab and do not submit the survey.")
                    .fontWeight(.bold)
//                Text("Please complete the following survey to the best of your ability. If you have any questions, please ask them via the \"Feedback\" tab.")
            }
        }
    }
}

struct SurveyLocked: View {
    @EnvironmentObject var tabController: TabController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Survey Closed")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("In order to unlock the survey, you must log at least 5 sessions, each of which must be at least 5 hours in length. Please return to this tab once you have done so!")
            Button("Log a Session") {
                tabController.open(.manage)
            }
            .fontWeight(.bold)
            .padding()
            .glassEffect(.regular.tint(.blue).interactive())
        }
    }
}

#Preview {
    SurveyView()
        .environmentObject(VariantManager())
        .environmentObject(SessionManager())
}
