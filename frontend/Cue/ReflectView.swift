//
//  ReflectView.swift
//  Cue
//
//  Created by Jackson Moody on 1/20/26.
//

import SwiftUI

struct ReflectView: View {
    @EnvironmentObject var reflectionManager: ReflectionManager
    @State private var showingSettings = false
    @State private var selectedSession: Session?
    @State private var showingError = false
    
    private var sortedSessions: [Session] {
        reflectionManager.sessions.sorted { $0.startDate > $1.startDate }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
                Group {
                    if sortedSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 30) {
                            Text("No Reflections Recorded")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("Once you log a reflection session, you will be able to review it here. Press the leaf icon in the upper-left corner of the Cue app on your Apple Watch to get started.\n\nIn the meantime, feel free to customize your reflection experience here:")
                            Button("Customize Experience") {
                                showingSettings = true
                            }
                            .fontWeight(.bold)
                            .padding()
                            .glassEffect(.regular.tint(.blue).interactive())
                        }
                        .padding()
                        .padding(.top, -30)
                        .foregroundStyle(.white)
                    } else {
                        List(sortedSessions, id: \.id) { session in
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: session.gear1?.icon ?? "apple.meditate")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.gear1?.text ?? "Reflection Session")
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
                        .refreshable {
                            await reflectionManager.loadReflections()
                        }
                        .scrollContentBackground(.hidden)
                        .padding(.top, -20)
                    }
                }
                .navigationTitle(!sortedSessions.isEmpty ? "Recent Reflections" : "")
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
                .task {
                    await reflectionManager.loadReflections()
                }
                .onChange(of: reflectionManager.errorMessage) { oldValue, newValue in
                    if newValue != nil && oldValue == nil {
                        showingError = true
                    }
                }
                .alert("Error", isPresented: $showingError) {
                    Button("OK", role: .cancel) {
                        reflectionManager.errorMessage = nil
                    }
                } message: {
                    if let errorMessage = reflectionManager.errorMessage {
                        Text(errorMessage)
                    }
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
        .environmentObject(ReflectionManager())
}
