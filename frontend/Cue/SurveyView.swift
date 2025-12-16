//
//  SurveyView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI

struct SurveyView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Survey")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
            }
            .foregroundStyle(.white)
            .padding()
        }
    }
}

#Preview {
    SurveyView()
}
