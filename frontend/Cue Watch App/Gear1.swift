//
//  Gear1.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 12/22/25.

// Gear 1: Awareness of the Habit Loop
// Brewer emphasizes a highly personal/contextual prompt

import SwiftUI

struct Gear1: View {
    @Environment(NavigationRouter.self) private var router
    @EnvironmentObject var reflectionManager: ReflectionManager
    @EnvironmentObject var locationService: LocationService
    @State private var currentPhase: Int = 0
    @State private var opacity: Double = 0
    @State private var fetchedOptions: Bool = false
    @State private var showLoading: Bool = false
    @State private var readyToShowOptions: Bool = false

    var body: some View {
        ZStack {
            if currentPhase == 0 {
                Text("Let's take a moment to reflect...")
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(opacity)
                    .padding(.horizontal)
            }
            if currentPhase == 1 {
                VStack {
                    Text("What may have triggered this response?")
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .opacity(opacity)
                        .padding(.horizontal)
                    if showLoading {
                        ProgressView()
                            .frame(maxHeight: 10)
                            .padding(.top, 25)
                            .opacity(opacity)
                    }
                }
            }
            if currentPhase == 2 {
                List {
                    ForEach(reflectionManager.gear1Options) { option in
                        ListButton(option.text, image: option.icon) {
                            gear1Selection(option)
                        }
                    }
                    ListButton("Not Sure", image: "questionmark") {
                        gear1Selection(GearOption(text: "Not Sure", icon: "questionmark"))
                    }
                    ListButton("Other", image: "ellipsis.circle") {
                        gear1Selection(GearOption(text: "Other", icon: "ellipsis.circle"))
                    }
                    Text("You can edit your response in the \"Reflect\" tab of the Cue iOS app.")
                        .font(.system(size: 12))
                        .listRowBackground(Color.clear)
                }
                .opacity(opacity)
                .scrollIndicators(.hidden)
                .padding(.horizontal)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                opacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 1.5)) {
                    opacity = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                currentPhase = 1
                withAnimation(.easeInOut(duration: 1.5)) {
                    opacity = 1
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 7.5) {
                readyToShowOptions = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
                withAnimation {
                    showLoading = true
                }
            }
        }
        .task {
            await setupReflection()
        }
        .onChange(of: locationService.mostRecentLocation) { oldValue, newValue in
            if let location = newValue, !fetchedOptions {
                fetchedOptions = true
                locationService.mostRecentLocation = nil
                Task {
                    await reflectionManager.fetchGear1Options(currentLocation: location)
                }
            }
        }
        .onChange(of: reflectionManager.gear1Options) {
            oldOptions, newOptions in
            showOptions(newOptions)
        }
        .onChange(of: readyToShowOptions) {
            showOptions(reflectionManager.gear1Options)
        }
    }
    
    private func setupReflection() async {
        locationService.requestCurrentLocation()
        reflectionManager.startNewSession()
        await reflectionManager.loadPreferences()
    }
    
    private func gear1Selection(_ option: GearOption) {
        reflectionManager.logGearSelection(option, forGear: 1, atDate: .now)
        router.navigateToGear2()
    }
    
    private func showOptions(_ options: [GearOption]) {
        if !options.isEmpty && readyToShowOptions {
            withAnimation(.easeInOut(duration: 1.5)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                currentPhase = 2
                withAnimation(.easeInOut(duration: 1.5)) {
                    opacity = 1
                }
            }
        }
    }
}

struct ListButton: View {
    let text: String
    let image: String
    let action: () -> Void
    
    init(_ text: String, image: String, action: @escaping () -> Void) {
        self.text = text
        self.image = image
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: image)
                    .padding(.trailing)
                Text(text)
            }
        }
    }
}

#Preview {
    Gear1()
        .environment(NavigationRouter())
        .environmentObject(ReflectionManager())
        .environmentObject(LocationService())
}
