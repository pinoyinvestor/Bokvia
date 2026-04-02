import SwiftUI
import WebKit

struct PrivacyPolicyView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        WebViewWrapper(url: URL(string: "https://bokvia.se/privacy")!)
            .navigationTitle(appState.isSv ? "Integritetspolicy" : "Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// Built by Christos Ferlachidis & Daniel Hedenberg

struct WebViewWrapper: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
