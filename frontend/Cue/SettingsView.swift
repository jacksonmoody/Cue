//
//  SettingsView.swift
//  Cue
//
//  Created by Jackson Moody on 1/20/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var reflectionManager: ReflectionManager
    
    @State private var gear2Options: [GearOption] = []
    @State private var gear3Options: [GearOption] = []
    
    @State private var showGear2AddForm = false
    @State private var showGear3AddForm = false
    @State private var newGear2Text = ""
    @State private var newGear2Icon = "star"
    @State private var newGear3Text = ""
    @State private var newGear3Icon = "star"
    @State private var gear2EditMode: EditMode = .inactive
    @State private var gear3EditMode: EditMode = .inactive
    
    private var showingError: Binding<Bool> {
        Binding(
            get: { reflectionManager.errorMessage != nil },
            set: { if !$0 { reflectionManager.errorMessage = nil } }
        )
    }
    
    let commonPhysicalIcons = ["star", "heart", "brain", "lungs", "eye", "hand.raised", "cross", "dumbbell", "scalemass", "thermometer.variable", "blood.pressure.cuff", "questionmark", "circle.slash"]
    let commonReflectionIcons = ["star", "apple.meditate", "brain", "lungs", "hand.tap", "face.smiling", "photo", "figure.run.treadmill", "figure.walk", "basketball", "tree", "service.dog", "fork.knife.circle", "gift", "music.quarternote.3", "theatermask.and.paintbrush", "figure.2.arms.open"]
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Physical Reactions")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Spacer()
                            Button(gear2EditMode.isEditing ? "Done" : "Edit") {
                                withAnimation {
                                    if gear2EditMode.isEditing {
                                        Task {
                                            await reflectionManager.saveGear2Preferences(gear2Options)
                                        }
                                    }
                                    gear2EditMode = gear2EditMode.isEditing ? .inactive : .active
                                }
                            }
                            .foregroundStyle(.white)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        List {
                            ForEach(gear2Options) { option in
                                HStack(spacing: 12) {
                                    Image(systemName: option.icon)
                                        .foregroundStyle(.white)
                                        .frame(width: 30)
                                    Text(option.text)
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .listRowBackground(Color.white.opacity(0.15))
                                .contentShape(.dragPreview, DragPreviewInsetRect(horizontal: 50, vertical: 15))
                            }
                            .onMove { indices, newOffset in
                                gear2Options.move(fromOffsets: indices, toOffset: newOffset)
                            }
                            .onDelete { indices in
                                gear2Options.remove(atOffsets: indices)
                            }
                        }
                        .environment(\.editMode, $gear2EditMode)
                        .listStyle(.insetGrouped)
                        .padding(.top, -35)
                        .scrollContentBackground(.hidden)
                        .frame(height: CGFloat(gear2Options.count) * 52)
                        .scrollDisabled(true)
                        
                        if showGear2AddForm {
                            VStack(spacing: 12) {
                                TextField("New Physical Reaction", text: $newGear2Text)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(.white)
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(commonPhysicalIcons, id: \.self) { icon in
                                            Button {
                                                newGear2Icon = icon
                                            } label: {
                                                Image(systemName: icon)
                                                    .font(.title2)
                                                    .foregroundStyle(newGear2Icon == icon ? .blue : .white)
                                                    .frame(width: 44, height: 44)
                                                    .background(newGear2Icon == icon ? Color.white : Color.white.opacity(0.2))
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                
                                HStack(spacing: 12) {
                                    Button("Cancel") {
                                        withAnimation {
                                            showGear2AddForm = false
                                            newGear2Text = ""
                                            newGear2Icon = "star"
                                        }
                                    }
                                    .foregroundStyle(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                                    
                                    Button("Add") {
                                        if !newGear2Text.isEmpty {
                                            withAnimation {
                                                gear2Options.append(GearOption(text: newGear2Text, icon: newGear2Icon))
                                                showGear2AddForm = false
                                                newGear2Text = ""
                                                newGear2Icon = "star"
                                            }
                                            Task {
                                                await reflectionManager.saveGear2Preferences(gear2Options)
                                            }
                                        }
                                    }
                                    .foregroundStyle(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            Button {
                                withAnimation {
                                    showGear2AddForm = true
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add New Reaction")
                                }
                                .foregroundStyle(gear2EditMode == .active ? .white.opacity(0.4) : .white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(gear2EditMode == .active ? Color.gray.opacity(0.2) : Color.white.opacity(0.2))
                                .cornerRadius(20)
                            }
                            .padding(.horizontal)
                            .disabled(gear2EditMode == .active)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Reflection Options")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Spacer()
                            Button(gear3EditMode.isEditing ? "Done" : "Edit") {
                                withAnimation {
                                    if gear3EditMode.isEditing {
                                        Task {
                                            await reflectionManager.saveGear3Preferences(gear3Options)
                                        }
                                    }
                                    gear3EditMode = gear3EditMode.isEditing ? .inactive : .active
                                }
                            }
                            .foregroundStyle(.white)
                        }
                        .padding(.horizontal)
                        
                        List {
                            ForEach(gear3Options) { option in
                                HStack(spacing: 12) {
                                    Image(systemName: option.icon)
                                        .foregroundStyle(.white)
                                        .frame(width: 30)
                                    Text(option.text)
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(.dragPreview, DragPreviewInsetRect(horizontal: 50, vertical: 15))
                                .listRowBackground(Color.white.opacity(0.15))
                            }
                            .onMove { indices, newOffset in
                                gear3Options.move(fromOffsets: indices, toOffset: newOffset)
                            }
                            .onDelete { indices in
                                gear3Options.remove(atOffsets: indices)
                            }
                        }
                        .environment(\.editMode, $gear3EditMode)
                        .listStyle(.insetGrouped)
                        .padding(.top, -35)
                        .scrollContentBackground(.hidden)
                        .frame(height: CGFloat(gear3Options.count) * 52)
                        .scrollDisabled(true)
                        
                        if showGear3AddForm {
                            VStack(spacing: 12) {
                                TextField("New Reflection Option", text: $newGear3Text)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(.white)
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(commonReflectionIcons, id: \.self) { icon in
                                            Button {
                                                newGear3Icon = icon
                                            } label: {
                                                Image(systemName: icon)
                                                    .font(.title2)
                                                    .foregroundStyle(newGear3Icon == icon ? .blue : .white)
                                                    .frame(width: 44, height: 44)
                                                    .background(newGear3Icon == icon ? Color.white : Color.white.opacity(0.2))
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                
                                HStack(spacing: 12) {
                                    Button("Cancel") {
                                        withAnimation {
                                            showGear3AddForm = false
                                            newGear3Text = ""
                                            newGear3Icon = "star"
                                        }
                                    }
                                    .foregroundStyle(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                                    
                                    Button("Add") {
                                        if !newGear3Text.isEmpty {
                                            withAnimation {
                                                gear3Options.append(GearOption(text: newGear3Text, icon: newGear3Icon))
                                                showGear3AddForm = false
                                                newGear3Text = ""
                                                newGear3Icon = "star"
                                            }
                                            Task {
                                                await reflectionManager.saveGear3Preferences(gear3Options)
                                            }
                                        }
                                    }
                                    .foregroundStyle(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            Button {
                                withAnimation {
                                    showGear3AddForm = true
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add New Option")
                                }
                                .foregroundStyle(gear3EditMode == .active ? .white.opacity(0.4) : .white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(gear3EditMode == .active ? Color.gray.opacity(0.2) : Color.white.opacity(0.2))
                                .cornerRadius(20)
                            }
                            .padding(.horizontal)
                            .disabled(gear3EditMode == .active)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Customize Options")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await reflectionManager.loadPreferences()
            if let prefs = reflectionManager.preferences {
                gear2Options = prefs.gear2Options
                gear3Options = prefs.gear3Options
            }
        }
        .onChange(of: reflectionManager.preferences) { oldValue, newValue in
            if let prefs = newValue {
                gear2Options = prefs.gear2Options
                gear3Options = prefs.gear3Options
            }
        }
        .alert("Error", isPresented: showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = reflectionManager.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

struct DragPreviewInsetRect: InsettableShape {
    var horizontal: CGFloat
    var vertical: CGFloat
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let expanded = rect.insetBy(
            dx: -(horizontal - insetAmount),
            dy: -(vertical - insetAmount)
        )
        return Path(expanded)
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(ReflectionManager())
    }
}
