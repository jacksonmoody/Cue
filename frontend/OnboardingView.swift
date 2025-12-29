//
//  OnboardingView.swift
//  Cue
//
//  Created by Jackson Moody on 12/14/25.
//

import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @EnvironmentObject var variantManager: VariantManager
    @AppStorage("onboardingNeeded") private var onboardingNeeded = true
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            if let variant = variantManager.variant {
                AppView(variant: variant)
                    .sheet(isPresented: $onboardingNeeded) {
                        InstructionsView(onboardingNeeded: $onboardingNeeded, refresher: false)
                            .toolbar(content: {
                               ToolbarItem(placement: .cancellationAction) {
                                  Text("")
                               }
                            })
                            .interactiveDismissDisabled()
                    }
            } else if variantManager.isLoading {
                ProgressView()
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
        .environmentObject(VariantManager())
}
