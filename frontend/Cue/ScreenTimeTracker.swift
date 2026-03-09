//
//  ScreenTimeTracker.swift
//  Cue
//
//  Created by Jackson Moody on 3/9/26.
//

import SwiftUI

struct ScreenTimeTracker: ViewModifier {
    let viewName: String
    @EnvironmentObject var variantManager: VariantManager
    @State private var appearDate: Date?

    func body(content: Content) -> some View {
        content
            .onAppear { appearDate = Date() }
            .onDisappear {
                guard let appearDate,
                      let userId = variantManager.appleUserId else { return }
                let duration = Date().timeIntervalSince(appearDate)
                let body: [String: Any] = [
                    "userId": userId,
                    "viewName": viewName,
                    "duration": duration,
                    "timestamp": ISO8601DateFormatter().string(from: appearDate),
                    "variant": variantManager.variant as Any
                ]
                Task {
                    try? await BackendService.shared.post(
                        path: "/screen-time", body: body)
                }
            }
    }
}

extension View {
    func trackScreenTime(_ viewName: String) -> some View {
        modifier(ScreenTimeTracker(viewName: viewName))
    }
}
