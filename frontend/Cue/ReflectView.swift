//
//  ReflectView.swift
//  Cue
//
//  Created by Jackson Moody on 1/20/26.
//

import SwiftUI

enum ReflectionOptions {
    case breaths, taps, visualization, exercise, nature, friends
}

struct Session: Identifiable, Hashable {
    let id: UUID
    let timestamp: Date
    let duration: TimeInterval
    let reflectionType: ReflectionOptions
}

struct ReflectView: View {
    @State private var showingSettings = false
    @State private var selectedSession: Session?
    @State private var sessions: [Session] = [
        Session(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            duration: 600,
            reflectionType: .breaths
        ),
        Session(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            duration: 480,
            reflectionType: .taps
        ),
        Session(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            duration: 720,
            reflectionType: .visualization
        ),
        Session(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            duration: 540,
            reflectionType: .exercise
        ),
        Session(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            duration: 900,
            reflectionType: .nature
        ),
        Session(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            duration: 660,
            reflectionType: .friends
        ),
        Session(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
            duration: 420,
            reflectionType: .breaths
        ),
        Session(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
            duration: 780,
            reflectionType: .nature
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
                List(sessions) { session in
                    NavigationLink(value: session) {
                        HStack(spacing: 16) {
                            Image(systemName: iconName(for: session.reflectionType))
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatDate(session.timestamp))
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                Text(formatDuration(session.duration))
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
                .navigationDestination(for: Session.self) { session in
                    SessionDetailView(session: session)
                }
            }
        }
    }
    
    private func iconName(for reflectionType: ReflectionOptions) -> String {
        switch reflectionType {
        case .breaths:
            return "apple.meditate"
        case .taps:
            return "hand.tap"
        case .visualization:
            return "photo"
        case .exercise:
            return "figure.run.treadmill"
        case .nature:
            return "tree"
        case .friends:
            return "figure.2.arms.open"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d min %d sec", minutes, seconds)
    }
}

#Preview {
    ReflectView()
}
