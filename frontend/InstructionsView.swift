//
//  InstructionsView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI

struct InstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var variantManager: VariantManager
    #if os(iOS)
    @EnvironmentObject var tabController: TabController
    #endif
    @Binding var onboardingNeeded: Bool
    @State private var selectedOccupation: Occupation = .student
    let refresher: Bool
    let center = UNUserNotificationCenter.current()
    
    enum Occupation: String, CaseIterable, Identifiable {
        case student, employed, unemployed, notworking, retired
        var id: Self { self }
    }
    
    var instructionText: String? {
        if let variant = variantManager.variant, variant == 1 {
            return "You are in Variant 1, meaning that you will automatically receive notifications to reflect whenever a monitoring session is running. Feel free to accept or deny these notifications as you see fit, and remember that you will need to log at least 5 monitoring sessions of at least 5 hours each to complete the experiment."
        } else if let variant = variantManager.variant, variant == 2 {
            return "You are in Variant 2, meaning that you will receive a reminder to reflect at a set time every day. You can adjust this time by clicking the gear icon in the upper-left corner of the Cue app on your Apple Watch. Feel free to accept or deny these reminders as you see fit, and remember that you will need to log at least 5 monitoring sessions of at least 5 hours each to complete the experiment."
        } else if let variant = variantManager.variant, variant == 3 {
            return "You are in Variant 3. To begin a reflection session, press the leaf icon in the upper-left corner of the Cue app on your Apple Watch. You are encouraged to begin a session whenever you are feeling stressed or anxious, and you may complete as many or as few of these sessions as you wish. In addition to these reflective exercises, you will need to log at least 5 sessions of at least 5 hours each to complete the experiment."
        } else {
            return nil
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment:.leading, spacing: 30) {
                #if os(iOS)
                Text("Instructions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                #endif
                Text("\(!refresher ? "Thank you for participating in this experiment! To get started, please click the \"Get Started\" button and accept all  requested permissions.\n\n" : "")\(instructionText ?? "")")
                Picker("Occupation", selection: $selectedOccupation) {
                    Text("Student").tag(Occupation.student)
                    Text("Employed").tag(Occupation.employed)
                    Text("Unemployed / Seeking Work").tag(Occupation.unemployed)
                    Text("Not Working").tag(Occupation.notworking)
                    Text("Retired").tag(Occupation.retired)
                }
                if !refresher {
                    Button("Get Started") {
                        workoutManager.requestAuthorization { authorized in
                            if authorized {
                                Task {
                                    do {
                                        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                                        if granted {
                                            onboardingNeeded = false
                                            dismiss()
                                        }
                                    } catch {
                                    }
                                }
                            } else {
                            }
                        }
                    }
                #if os(iOS)
                .padding()
                .fontWeight(.bold)
                .glassEffect(.regular.tint(.blue).interactive())
                .foregroundStyle(.white)
                #else
                .frame(maxWidth: .infinity)
                #endif
                } else {
                    #if os(iOS)
                    Button("Log a Session") {
                        tabController.open(.manage)
                    }
                    .padding()
                    .fontWeight(.bold)
                    .glassEffect(.regular.tint(.blue).interactive())
                    .foregroundStyle(.white)
                    #endif
                }
            }
            #if os(iOS)
            .padding(refresher ? 30 : 40)
            .font(!refresher ? .title2 : .default)
            .foregroundStyle(refresher ? .white : .primary)
            #else
            .multilineTextAlignment(.center)
            .padding()
            #endif
        }
    }
}
