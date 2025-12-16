//
//  OnboardingView.swift
//  Cue
//
//  Created by Jackson Moody on 12/14/25.
//

import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @State private var variantManager = VariantManager()
    @AppStorage("onboardingNeeded") private var onboardingNeeded = true
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            if variantManager.variant != nil {
                AppView()
                    .sheet(isPresented: $onboardingNeeded) {
                        InstructionsView(onboardingNeeded: $onboardingNeeded)
                            .toolbar(content: {
                               ToolbarItem(placement: .cancellationAction) {
                                  Text("")
                               }
                            })
                            .interactiveDismissDisabled()
                    }
            } else {
                LoginView()
            }
        }
        .task {
            await variantManager.loadVariant()
        }
         
    }
}

#Preview {
    OnboardingView()
}
