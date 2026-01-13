//
//  IncompleteOnboarding.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 1/12/26.
//

import SwiftUI

struct IncompleteOnboarding: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "iphone.gen2.slash.circle")
                .foregroundStyle(Color.red)
                .font(.system(size: 40))
            Text("Setup Incomplete")
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text("Complete setup on your iPhone before continuing.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

#Preview {
    IncompleteOnboarding()
}
