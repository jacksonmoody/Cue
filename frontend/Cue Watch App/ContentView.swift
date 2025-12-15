//
//  ContentView.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/14/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var variantManager = VariantManager()

    var body: some View {
        VStack(spacing: 8) {
            Text("Cue Variant")
                .font(.headline)

            if let variant = variantManager.variant {
                Text("Variant \(variant)")
                    .font(.title3)
            } else if variantManager.isLoading {
                ProgressView()
            } else if let message = variantManager.errorMessage {
                Text(message)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            } else {
                Text("Assigning…")
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
