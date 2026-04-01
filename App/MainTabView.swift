import os
import SwiftUI

enum AppTab: Int, CaseIterable {
    case home, explore, bookings, chat, profile
    // Provider tabs
    case providerDashboard, providerExplore, providerCalendar, providerClients, providerProfile
    // Salon tabs
    case salonDashboard, salonTeam, salonBookings, salonSettings, salonProfile
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: AppTab = .home
    @State private var unreadMessages = 0
    @State private var unreadNotifications = 0

    var body: some View {
        Group {
            switch appState.activeProfileType {
            case "PROVIDER":
                providerTabView
            case "SALON":
                salonTabView
            default:
                customerTabView
            }
        }
        .tint(BokviaTheme.accent)
        .task {
            resetTabForProfile()
            await loadUnreadCounts()
            connectWebSocket()
            if let tab = QuickActionManager.shared.consumeAction() {
                selectedTab = tab
            }
        }
        .onChange(of: appState.activeProfileType) { _, _ in
            resetTabForProfile()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if let tab = QuickActionManager.shared.consumeAction() {
                selectedTab = tab
            }
            Task { await loadUnreadCounts() }
        }
    }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    // MARK: - Customer Tabs

    private var customerTabView: some View {
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

    // MARK: - Provider Tabs

    private var providerTabView: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { ProviderDashboardView() }
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                .tag(AppTab.providerDashboard)

            NavigationStack { ExploreView() }
                .tabItem { Label(appState.isSv ? "Salonger" : "Salons", systemImage: "building.2") }
                .tag(AppTab.providerExplore)

            NavigationStack { ProviderCalendarView() }
                .tabItem { Label(appState.isSv ? "Kalender" : "Calendar", systemImage: "calendar") }
                .tag(AppTab.providerCalendar)

            NavigationStack { ProviderClientsView() }
                .tabItem { Label(appState.isSv ? "Kunder" : "Clients", systemImage: "person.2.fill") }
                .tag(AppTab.providerClients)

            NavigationStack { ProfileView() }
                .tabItem { Label(appState.isSv ? "Profil" : "Profile", systemImage: "person.fill") }
                .tag(AppTab.providerProfile)
                .badge(unreadNotifications)
        }
    }

    // MARK: - Salon Tabs

    private var salonTabView: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { SalonDashboardView() }
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                .tag(AppTab.salonDashboard)

            NavigationStack { SalonTeamView() }
                .tabItem { Label("Team", systemImage: "person.3.fill") }
                .tag(AppTab.salonTeam)

            NavigationStack { SalonBookingsView() }
                .tabItem { Label(appState.isSv ? "Bokningar" : "Bookings", systemImage: "calendar") }
                .tag(AppTab.salonBookings)

            NavigationStack { SalonSettingsView() }
                .tabItem { Label(appState.isSv ? "Inställningar" : "Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.salonSettings)

            NavigationStack { ProfileView() }
                .tabItem { Label(appState.isSv ? "Profil" : "Profile", systemImage: "person.fill") }
                .tag(AppTab.salonProfile)
                .badge(unreadNotifications)
        }
    }

    // MARK: - Helpers

    private func resetTabForProfile() {
        switch appState.activeProfileType {
        case "PROVIDER":
            selectedTab = .providerDashboard
        case "SALON":
            selectedTab = .salonDashboard
        default:
            selectedTab = .home
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

