import SwiftUI

struct TermsView: View {
    @Environment(AppState.self) private var appState

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var body: some View {
        WebViewWrapper(url: URL(string: "https://bokvia.se/terms")!)
            .navigationTitle(appState.isSv ? "Användarvillkor" : "Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
    }
}
