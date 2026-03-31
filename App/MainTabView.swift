import os
import SwiftUI

enum AppTab: Int, CaseIterable {
    case home, explore, bookings, chat, profile
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: AppTab = .home
    @State private var unreadMessages = 0
    @State private var unreadNotifications = 0

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                modernTabView
            } else {
                legacyTabView
            }
        }
        .tint(BokviaTheme.accent)
        .task {
            await loadUnreadCounts()
            connectWebSocket()
            if let tab = QuickActionManager.shared.consumeAction() {
                selectedTab = tab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if let tab = QuickActionManager.shared.consumeAction() {
                selectedTab = tab
            }
            Task { await loadUnreadCounts() }
        }
    }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    @available(iOS 18.0, *)
    private var modernTabView: some View {
        TabView(selection: $selectedTab) {
            Tab(appState.isSv ? "Hem" : "Home", systemImage: "house.fill", value: .home) {
                NavigationStack { HomeView() }
            }

            Tab(appState.isSv ? "Utforska" : "Explore", systemImage: "magnifyingglass", value: .explore) {
                NavigationStack { ExploreView() }
            }

            Tab(appState.isSv ? "Bokningar" : "Bookings", systemImage: "calendar", value: .bookings) {
                NavigationStack { BookingsView() }
            }

            Tab(appState.isSv ? "Chatt" : "Chat", systemImage: "bubble.left.and.bubble.right.fill", value: .chat) {
                NavigationStack { ChatsView() }
            }
            .badge(unreadMessages)

            Tab(appState.isSv ? "Profil" : "Profile", systemImage: "person.fill", value: .profile) {
                NavigationStack { ProfileView() }
            }
            .badge(unreadNotifications)
        }
    }

    private var legacyTabView: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView() }
                .tabItem { Label(appState.isSv ? "Hem" : "Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            NavigationStack { ExploreView() }
                .tabItem { Label(appState.isSv ? "Utforska" : "Explore", systemImage: "magnifyingglass") }
                .tag(AppTab.explore)

            NavigationStack { BookingsView() }
                .tabItem { Label(appState.isSv ? "Bokningar" : "Bookings", systemImage: "calendar") }
                .tag(AppTab.bookings)

            NavigationStack { ChatsView() }
                .tabItem { Label(appState.isSv ? "Chatt" : "Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(AppTab.chat)
                .badge(unreadMessages)

            NavigationStack { ProfileView() }
                .tabItem { Label(appState.isSv ? "Profil" : "Profile", systemImage: "person.fill") }
                .tag(AppTab.profile)
                .badge(unreadNotifications)
        }
    }

    private func connectWebSocket() {
        guard let userId = appState.currentUser?.id else { return }
        let ws = WebSocketClient.shared
        ws.onNewMessage = { _ in
            Task { await loadUnreadCounts() }
        }
        ws.onBookingUpdate = {
            HapticManager.medium()
        }
        ws.connect(userId: userId)
    }

    private func loadUnreadCounts() async {
        if let response = try? await APIClient.shared.get("/api/notifications/unread-count", as: UnreadCountResponse.self) {
            unreadNotifications = response.count
        }
    }
}
