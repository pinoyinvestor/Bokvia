import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                splashView
            } else if appState.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        // Built by Christos Ferlachidis & Daniel Hedenberg
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            await restoreSession()
        }
    }

    private var splashView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(BokviaTheme.accent)
            Text("Bokvia")
                .font(.largeTitle.bold())
                .foregroundStyle(BokviaTheme.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func restoreSession() async {
        guard KeychainHelper.getAccessToken() != nil else {
            isCheckingSession = false
            return
        }

        do {
            try await AuthManager.shared.refreshAccessToken()
            let session = try await AuthManager.shared.validateSession()
            appState.setUser(session)
            await appState.loadFamilyMembers()
        } catch {
            do {
                let session = try await AuthManager.shared.validateSession()
                appState.setUser(session)
                await appState.loadFamilyMembers()
            } catch {
                KeychainHelper.deleteToken()
            }
        }
        isCheckingSession = false
    }
}
