//
//  SurveyView.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import SwiftUI
import SwiftSoup
import WebKit

struct SurveyView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var isSurveyUnlocked: Bool {
        !sessionManager.isLoading && sessionManager.isExperimentComplete
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
    @State private var calendarWebViewOpen: Bool = false
    @AppStorage("surveyComplete") var surveyComplete: Bool?
    private let surveyDismissContains = ["Your response has been recorded", "You have either already completed the survey or your session has expired."]
    
    var firstName: String? {
        let components = UserDefaults.standard.string(forKey: "fullName")?.split(separator: " ")
        if let components, components.count > 0 {
            return String(components[0])
        }
        return nil
    }
    
    var fullName: String {
        UserDefaults.standard.string(forKey: "fullName") ?? ""
    }
    
    var userEmail: String {
        UserDefaults.standard.string(forKey: "userEmail") ?? ""
    }
    
    var orderString: String {
        guard let order = variantManager.order else { return "" }
        return order.map { String($0) }.joined()
    }
    
    var surveyURL: URL {
        let encodedName = fullName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedEmail = userEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://harvard.az1.qualtrics.com/jfe/form/SV_cLKdtPpUqkZbRGu?order=\(orderString)&name=\(encodedName)&email=\(encodedEmail)")!
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text((firstName != nil) ? "Thank you for your participation, \(firstName!)!" : "Thank you for your participation!")
                .font(.title)
                .fontWeight(.bold)
            if !(surveyComplete ?? false) {
                Text("Before beginning, please ensure that both your iOS Cue App and watchOS Cue App report that you are in Variant \(String(variantManager.variant ?? 0)) and  Phase \(String((variantManager.currentPhase ?? 0) + 1)). If they do not agree, report the issue via the \"Feedback\" tab and do not complete the survey.")
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
                    calendarWebViewOpen = true
                }
                .fontWeight(.bold)
                .padding()
                .glassEffect(.regular.tint(.blue).interactive())
            }
        }
        .fullScreenCover(isPresented: $webViewOpen) {
            SurveyWebView(
                url: surveyURL,
                dismissWhenViewContains: surveyDismissContains,
                onDismiss: {
                    surveyComplete = true
                    webViewOpen = false
                }
            )
        }
        .sheet(isPresented: $calendarWebViewOpen) {
            SimpleWebView(
                url: URL(string: "https://calendly.com/jackson-moody/thesis")!
            )
        }
    }
}

private struct SurveyWebView: UIViewRepresentable {
    let url: URL
    var dismissWhenViewContains: [String]
    var onDismiss: () -> Void

    private static let messageName = "domChanged"

    func makeCoordinator() -> Coordinator {
        Coordinator(dismissWhenViewContains: dismissWhenViewContains, onDismiss: onDismiss)
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: Self.messageName)

        let observerScript = WKUserScript(
            source: """
            new MutationObserver(() => {
                window.webkit.messageHandlers.\(Self.messageName)
                    .postMessage(document.documentElement.outerHTML);
            }).observe(document.body, { childList: true, subtree: true, characterData: true });
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(observerScript)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = false
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: messageName)
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let dismissWhenViewContains: [String]
        let onDismiss: () -> Void
        private var dismissed = false

        init(dismissWhenViewContains: [String], onDismiss: @escaping () -> Void) {
            self.dismissWhenViewContains = dismissWhenViewContains
            self.onDismiss = onDismiss
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard !dismissed, let html = message.body as? String else { return }
            do {
                let doc = try SwiftSoup.parse(html)
                let pageText = try doc.text()
                if dismissWhenViewContains.contains(where: { pageText.contains($0) }) {
                    dismissed = true
                    DispatchQueue.main.async { [onDismiss] in
                        onDismiss()
                    }
                }
            } catch {}
        }
    }
}

private struct SimpleWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct SurveyLocked: View {
    @EnvironmentObject var tabController: TabController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Survey Closed")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("In order to unlock the survey, you must experience all 3 experimental variants, logging 8 hours of monitoring in each one. You must also complete at least one reflection in each variant. Please return to this tab once you have done so!")
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
