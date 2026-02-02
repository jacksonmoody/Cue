//
//  SurveyView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI
import WebKit

struct SurveyView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var isSurveyUnlocked: Bool {
        !sessionManager.isLoading && sessionManager.sessionsRemaining == 0 && (sessionManager.reflectionCount ?? 0) >= 1
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gradientBlue, .gradientPurple], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            Group {
                if isSurveyUnlocked {
                    Survey()
                        .padding(.vertical, 20)
                        .padding(.horizontal)
                } else {
                    SurveyLocked()
                        .padding(30)
                }
            }
            .foregroundStyle(.white)
        }
    }
}

struct Survey: View {
    @EnvironmentObject var variantManager: VariantManager
    @State private var webViewOpen: Bool = false
    @AppStorage("surveyComplete") var surveyComplete: Bool?
    @Environment(\.openURL) private var openURL
    
    // TODO: Update this
    private let surveyDismissURLContains = "/thank-you"
    
    var firstName: String? {
        let components = UserDefaults.standard.string(forKey: "fullName")?.split(separator: " ")
        if let components, components.count > 0 {
            return String(components[0])
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text((firstName != nil) ? "Thank you for your participation, \(firstName!)!" : "Thank you for your participation!")
                .font(.title)
                .fontWeight(.bold)
            if !(surveyComplete ?? false) {
                Text("Before beginning, please ensure that both your iOS Cue App and watchOS Cue App report that you are in Variant \(String(variantManager.variant ?? 0)). If they do not agree, report the issue via the \"Feedback\" tab and do not open the survey.")
                    .fontWeight(.semibold)
                Button("Open Survey") {
                    webViewOpen.toggle()
                }
                .fontWeight(.bold)
                .padding()
                .glassEffect(.regular.tint(.blue).interactive())
            } else {
                Text("Thank you for your time spent completing the survey. If you have not already booked a slot for your post-experiment interview, you may do so here:")
                    .fontWeight(.semibold)
                Button("Book an Interview Time") {
                    if let url = URL(string: "https://calendly.com/jackson-moody/thesis") {
                        openURL(url)
                    }
                }
                .fontWeight(.bold)
                .padding()
                .glassEffect(.regular.tint(.blue).interactive())
            }
        }
        .fullScreenCover(isPresented: $webViewOpen) {
            SurveyWebView(
                // TODO: Update this
                url: URL(string: "https://qualtrics.org")!,
                dismissWhenURLContains: surveyDismissURLContains,
                onDismiss: {
                    surveyComplete = true
                    webViewOpen = false
                }
            )
        }
    }
}

private struct SurveyWebView: UIViewRepresentable {
    let url: URL
    var dismissWhenURLContains: String
    var onDismiss: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismissWhenURLContains: dismissWhenURLContains, onDismiss: onDismiss)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    final class Coordinator: NSObject, WKNavigationDelegate {
        let dismissWhenURLContains: String
        let onDismiss: () -> Void
        
        init(dismissWhenURLContains: String, onDismiss: @escaping () -> Void) {
            self.dismissWhenURLContains = dismissWhenURLContains
            self.onDismiss = onDismiss
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let currentURL = webView.url?.absoluteString,
                  currentURL.contains(dismissWhenURLContains) else { return }
            DispatchQueue.main.async { [onDismiss] in
                onDismiss()
            }
        }
    }
}

struct SurveyLocked: View {
    @EnvironmentObject var tabController: TabController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Survey Closed")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("In order to unlock the survey, you must log at least 5 monitoring sessions (each of which must be at least 5 hours in length), and you must complete at least one reflection on your Apple Watch. Please return to this tab once you have done so!")
            Button("Log Monitoring Session") {
                tabController.open(.manage)
            }
            .fontWeight(.bold)
            .padding()
            .glassEffect(.regular.tint(.blue).interactive())
        }
    }
}

#Preview {
    SurveyView()
        .environmentObject(VariantManager())
        .environmentObject(SessionManager())
}
