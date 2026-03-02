//
//  InstructionsView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI

struct InstructionsView: View {
    @EnvironmentObject var variantManager: VariantManager
    #if os(iOS)
    @EnvironmentObject var tabController: TabController
    #endif
    @Environment(\.dismiss) var dismiss
    @Binding var instructionsNeeded: Bool
    let refresher: Bool
    var variantSwitch: Bool = false
    
    #if os(iOS)
    let introText = "Thank you for participating in this experiment! To get started, please read through the following instructions carefully, then click the \"Begin Setup\" button and accept all required permissions.\n\n"
    #else
    let introText = "Thank you for participating in this experiment! To get started, please read through the following instructions carefully:\n\n"
    #endif
    
    let variantSwitchIntroText = "You've completed 8 hours in the previous variant and have been switched to a new experimental condition. Here are your updated instructions:\n\n"
    
    var instructionText: String? {
        if let variant = variantManager.variant, variant == 1 {
            return "In this phase, you will automatically receive notifications to reflect whenever a monitoring session is running. Feel free to accept or deny these notifications as you see fit, and remember that you will need to log at least 8 hours of monitoring to complete this phase. You can begin a reflection session manually by pressing the leaf icon in the upper-left corner of the Cue app on your Apple Watch. You must complete at least one reflection session during each phase of the experiment."
        } else if let variant = variantManager.variant, variant == 2 {
            return "In this phase, you will receive a reminder to reflect at a set time every day. You can adjust this time by clicking the gear icon in the bottom-right corner of the Cue app on your Apple Watch. Feel free to accept or deny these reminders as you see fit, and remember that you will need to log at least 8 hours of monitoring to complete this phase. You can also begin a reflection session manually by pressing the leaf icon in the upper-left corner of the app. You must complete at least one reflection session during each phase of the experiment."
        } else if let variant = variantManager.variant, variant == 3 {
            return "During this phase, you must complete at least one reflection session. To begin a reflection session, press the leaf icon in the upper-left corner of the Cue app on your Apple Watch. You are encouraged to begin a session whenever you are feeling stressed or anxious, and you may complete as many of these sessions as you wish. In addition to these reflective exercises, you will need to log at least 8 hours of monitoring to complete this phase."
        } else {
            return nil
        }
    }
    
    private var stackAlignment: HorizontalAlignment {
        #if os(watchOS)
        .center
        #else
        .leading
        #endif
    }
    
    private var headerText: String {
        if variantSwitch {
            return variantSwitchIntroText
        } else if !refresher {
            return introText
        } else {
            return ""
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: stackAlignment, spacing: 30) {
#if os(iOS)
                        Text(variantSwitch ? "Updated Instructions" : "Instructions")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 40)
#endif
                        Text("\(headerText)\(instructionText ?? "")")
#if os(iOS)
                        if variantSwitch {
                            Button("Continue") {
                                UserDefaults.standard.set(false, forKey: "variantSwitchPending")
                                instructionsNeeded = false
                                dismiss()
                            }
                            .padding()
                            .fontWeight(.bold)
                            .glassEffect(.regular.tint(.blue).interactive())
                            .foregroundStyle(.white)
                        } else if !refresher {
                            NavigationLink("Begin Setup") {
                                PermissionsView(instructionsNeeded: $instructionsNeeded)
                            }
                            .padding()
                            .fontWeight(.bold)
                            .glassEffect(.regular.tint(.blue).interactive())
                            .foregroundStyle(.white)
                        } else {
                            Button("Log a Session") {
                                dismiss()
                                tabController.open(.manage)
                            }
                            .padding()
                            .fontWeight(.bold)
                            .glassEffect(.regular.tint(.blue).interactive())
                            .foregroundStyle(.white)
                        }
#endif
#if os(watchOS)
                        if variantSwitch {
                            Button("Continue") {
                                UserDefaults.standard.set(false, forKey: "variantSwitchPending")
                                instructionsNeeded = false
                                dismiss()
                            }
                            .fontWeight(.bold)
                        }
#endif
                    }
                    .padding()
#if os(watchOS)
                    .multilineTextAlignment(.center)
#endif
                }
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
        InstructionsView(instructionsNeeded: .constant(false), refresher: false)
            .environmentObject(VariantManager())
        #if os(iOS)
            .environmentObject(TabController())
        #endif
    }
}
