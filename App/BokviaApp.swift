import SwiftUI

@main
struct BokviaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    // Built by Christos Ferlachidis & Daniel Hedenberg

    init() {
        UITableView.appearance().backgroundColor = .systemBackground
        UICollectionView.appearance().backgroundColor = .systemBackground
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(appState.colorScheme)
                .environment(\.locale, appState.locale)
                .onAppear {
                    PushManager.shared.requestPermission()
                    if KeychainHelper.getAccessToken() != nil {
                        Task { await PushManager.shared.sendPendingToken() }
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                LocationManager.shared.requestLocation()
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // bokvia://provider/{slug}
        // bokvia://booking/{id}
        // https://bokvia.se/p/{slug}
        // https://bokvia.se/s/{slug}

        if url.scheme == "bokvia" {
            let host = url.host()
            let path = url.pathComponents.dropFirst()
            if host == "provider", let slug = path.first {
                appState.pendingDeepLink = .provider(slug: String(slug))
            } else if host == "booking", let id = path.first {
                appState.pendingDeepLink = .booking(id: String(id))
            }
        } else if url.host() == "bokvia.se" || url.host() == "www.bokvia.se" {
            let components = url.pathComponents.filter { $0 != "/" }
            guard components.count >= 2 else { return }
            let prefix = components[0]
            let slug = components[1]
            if prefix == "p" {
                appState.pendingDeepLink = .provider(slug: slug)
            } else if prefix == "s" {
                appState.pendingDeepLink = .salon(slug: slug)
            }
        }
    }
}
