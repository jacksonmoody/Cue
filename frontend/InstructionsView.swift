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
    @Binding var onboardingNeeded: Bool
    let refresher: Bool
    
    #if os(iOS)
    let introText = "Thank you for participating in this experiment! To get started, please read through the following instructions carefully, then click the \"Begin Setup\" button and accept all required permissions.\n\n"
    #else
    let introText = "Thank you for participating in this experiment! To get started, please read through the following instructions carefully:\n\n"
    #endif
    
    var instructionText: String? {
        if let variant = variantManager.variant, variant == 1 {
            return "You are in Variant 1, meaning that you will automatically receive notifications to reflect whenever a monitoring session is running. Feel free to accept or deny these notifications as you see fit, and remember that you will need to log at least 5 monitoring sessions of at least 5 hours each to complete the experiment."
        } else if let variant = variantManager.variant, variant == 2 {
            return "You are in Variant 2, meaning that you will receive a reminder to reflect at a set time every day. You can adjust this time by clicking the gear icon in the upper-left corner of the Cue app on your Apple Watch. Feel free to accept or deny these reminders as you see fit, and remember that you will need to log at least 5 monitoring sessions of at least 5 hours each to complete the experiment."
        } else if let variant = variantManager.variant, variant == 3 {
            return "You are in Variant 3. To begin a reflection session, press the leaf icon in the upper-left corner of the Cue app on your Apple Watch. You are encouraged to begin a session whenever you are feeling stressed or anxious, and you may complete as many or as few of these sessions as you wish. In addition to these reflective exercises, you will need to log at least 5 monitoring sessions of at least 5 hours each to complete the experiment."
        } else {
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
#if os(iOS)
                if refresher {
                    LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
                }
#endif
                ScrollView {
                    VStack(alignment:.leading, spacing: 30) {
#if os(iOS)
                        Text("Instructions")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 40)
#endif
                        Text("\(!refresher ? introText : "")\(instructionText ?? "")")
#if os(iOS)
                        if !refresher {
                            NavigationLink("Begin Setup") {
                                PermissionsView(onboardingNeeded: $onboardingNeeded)
                            }
                            .padding()
                            .fontWeight(.bold)
                            .glassEffect(.regular.tint(.blue).interactive())
                            .foregroundStyle(.white)
                        } else {
                            Button("Log a Session") {
                                tabController.open(.manage)
                            }
                            .padding()
                            .fontWeight(.bold)
                            .glassEffect(.regular.tint(.blue).interactive())
                            .foregroundStyle(.white)
                        }
#endif
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
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
        InstructionsView(onboardingNeeded: .constant(false), refresher: false)
            .environmentObject(VariantManager())
        #if os(iOS)
            .environmentObject(TabController())
        #endif
    }
}
