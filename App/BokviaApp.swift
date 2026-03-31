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
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                LocationManager.shared.requestLocation()
            }
        }
    }
}
