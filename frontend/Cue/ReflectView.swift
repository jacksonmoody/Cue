//
//  ReflectView.swift
//  Cue
//
//  Created by Jackson Moody on 1/20/26.
//

import SwiftUI

struct ReflectView: View {
    @State private var showingSettings = false
    @State private var selectedSession: Session?
    @State private var sessions: [Session] = [
        Session(id: UUID(), startDate: .now, gear1Finished: .distantPast, gear2Finished: .distantPast, endDate: .distantFuture, gear1: .init(text: "11am Thesis Meeting", icon: "calendar"), gear2: .init(text:"Heart Racing", icon: "heart"), gear3: .init(text:"Mindful Breaths", icon: "lungs"))
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
                List(sessions, id: \.id) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: session.gear3.icon)
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.gear1.text)
                                    .foregroundStyle(.white)
                                    .font(.headline)
                                Text(formatDate(session.startDate))
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                }
                .scrollContentBackground(.hidden)
                .padding(.top, -20)
                .navigationTitle("Recent Reflections")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Settings", systemImage: "gear") {
                            showingSettings = true
                        }
                    }
                }
                .navigationDestination(isPresented: $showingSettings) {
                    SettingsView()
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ReflectView()
}
