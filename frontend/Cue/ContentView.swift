//
//  ContentView.swift
//  Cue
//
//  Created by Jackson Moody on 12/14/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var variantManager = VariantManager()

    var body: some View {
        VStack(spacing: 12) {
            Text("Cue Variant")
                .font(.title)
                .bold()

            if let variant = variantManager.variant {
                Text("Assigned variant: \(variant)")
                    .font(.title2)
            } else if variantManager.isLoading {
                ProgressView("Assigning variant…")
            } else if let message = variantManager.errorMessage {
                Text(message)
                    .foregroundStyle(.red)
            } else {
                Text("Preparing assignment…")
            }
        }
        .padding()
        .task {
            await variantManager.loadVariant()
        }
    }
}

#Preview {
    ContentView()
}
