//
//  LoginView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var variantManager = VariantManager()
    var body: some View {
        #if os(iOS)
        VStack(spacing: 5) {
            Spacer()
            Text("Welcome to Cue!")
                .font(.title)
                .fontWeight(.bold)
            Text("Micro-reflections, right on your wrist.")
                .font(.title2)
                .multilineTextAlignment(.center)
            signInButton
                .padding(.vertical)
            Spacer()
            Text("By clicking Sign up with Apple, you agree to share your name and email address as part of a research study conducted for an undergraduate thesis. All results of this study will be anonymized and analyzed in the aggregate. Participation in this study may significantly degrade the battery life and performance of your Apple Watch. If you have any questions, please contact jacksonmoody@college.harvard.edu.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .tint(.white)
        }
        .foregroundStyle(.white)
        .padding()
        #endif

        #if os(watchOS)
            ScrollView {
                VStack(spacing: 5) {
                    Text("Welcome to Cue!")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("By clicking Sign In, you agree to participate in a research study conducted by Jackson Moody as part of an undergraduate thesis. Participation in this study may significantly degrade the battery life and performance of your Apple Watch. If you have any questions, please contact jacksonmoody@college.harvard.edu")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .tint(.white)
                    signInButton
                }
            }
            .foregroundStyle(.white)
            .padding()
        #endif
    }
    
    private var signInButton: some View {
        SignInWithAppleButton(.signUp) { request in
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            variantManager.handleSignInCompletion(result)
        }
        .frame(height: 44)
        .padding(.top, 8)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
        LoginView()
    }
}
