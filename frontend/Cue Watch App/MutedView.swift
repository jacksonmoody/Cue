//
//  MutedView.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 1/10/26.
//

import SwiftUI

struct MutedView: View {
    @Environment(NavigationRouter.self) private var router
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 10) {
                Image(systemName: "bell.slash")
                    .foregroundStyle(Color.red)
                    .font(.system(size: 30))
                Text("For best results, take your Apple Watch off silent mode and increase the volume.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Done") {
                    router.navigateToGear3(bypass: true)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    MutedView()
        .environment(NavigationRouter())
}
