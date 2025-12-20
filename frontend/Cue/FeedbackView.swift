//
//  FeedbackView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI
import MessageUI

struct FeedbackView: View {
    @State private var isShowingMailView = false
    @Environment(\.openURL) private var openUrl
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            VStack(alignment: .leading, spacing: 30) {
                Text("Feedback")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Thank you for using Cue and for participating in this experiment! This thesis would not be possible without your help. If you are running into any issues, have any questions, or have any thoughts on how to improve the experience, please let me know.")
                Button("Submit Feedback") {
                    if (MFMailComposeViewController.canSendMail()) {
                        isShowingMailView = true
                    } else {
                        sendEmail(openUrl: openUrl)
                    }
                }
                .fontWeight(.bold)
                .padding()
                .glassEffect(.regular.tint(.blue).interactive())
            }
            .foregroundStyle(.white)
            .padding(30)
            .sheet(isPresented: $isShowingMailView) {
                MailComposerViewController(recipients: ["jacksonmoody@college.harvard.edu"], subject: "Feedback on Cue")
            }
        }
    }
}

struct MailComposerViewController: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    var recipients: [String]
    var subject: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        mailComposer.setToRecipients(recipients)
        mailComposer.setSubject(subject)
        return mailComposer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposerViewController

        init(_ parent: MailComposerViewController) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

func sendEmail(openUrl: OpenURLAction) {
    let urlString = "mailto:jacksonmoody@college.harvard.edu?subject=Feedback on Cue"
    guard let url = URL(string: urlString) else { return }
    openUrl(url)
}

#Preview {
    FeedbackView()
}
