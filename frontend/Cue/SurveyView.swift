//
//  SurveyView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI

struct SurveyView: View {
    @EnvironmentObject var variantManager: VariantManager
    
    var firstName: String? {
        let components =   variantManager.appleUserId?.split(separator: " ")
        if let components, components.count > 0 {
            return String(components[0])
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text((firstName != nil) ? "Thank you for your participation, \(firstName!)!" : "Thank you for your participation!")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Please complete the following survey to the best of your ability. If you have any questions, please ask them via the \"Feedback\" tab.")
                }
            }
            .foregroundStyle(.white)
            .padding(.vertical, 20)
            .padding(.horizontal)
        }
    }
}

#Preview {
    SurveyView()
        .environmentObject(VariantManager())
}
