import SwiftUI

struct NotificationsView: View {
    @Environment(AppState.self) private var appState
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if notifications.isEmpty {
                ContentUnavailableView(
                    appState.isSv ? "Inga notiser" : "No notifications",
                    systemImage: "bell.slash"
                )
            } else {
                List(notifications) { notif in
                    notificationRow(notif)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(appState.isSv ? "Notiser" : "Notifications")
        // Built by Christos Ferlachidis & Daniel Hedenberg
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if notifications.contains(where: { !$0.isRead }) {
                    Button(appState.isSv ? "Markera alla" : "Mark all") {
                        Task { await markAllRead() }
                    }
                    .font(.caption)
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func notificationRow(_ notif: AppNotification) -> some View {
        HStack(spacing: 12) {
            Text(notifEmoji(notif.type))
                .font(.title2)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                if let title = notif.title {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                }
                Text(notif.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(timeAgo(notif.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if !notif.isRead {
                Circle()
                    .fill(BokviaTheme.accent)
                    .frame(width: 8, height: 8)
                    .accessibilityLabel(appState.isSv ? "Oläst" : "Unread")
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            Task {
                struct Empty: Encodable {}
                _ = try? await APIClient.shared.patch("/api/notifications/\(notif.id)/read", body: Empty(), as: EmptyResponse.self)
            }
        }
    }

    private func notifEmoji(_ type: String) -> String {
        switch type {
        case "booking_confirmed": return "✅"
        case "booking_cancelled": return "❌"
        case "booking_reminder": return "⏰"
        case "new_message": return "💬"
        case "new_review": return "⭐"
        case "new_follower": return "❤️"
        default: return "🔔"
        }
    }

    private func timeAgo(_ iso: String) -> String {
        guard let date = DateFormatter.apiDateTime.date(from: iso) else { return "" }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Nu" }
        if interval < 3600 { return "\(Int(interval / 60)) min" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        return "\(Int(interval / 86400))d"
    }

    private func load() async {
        if let result = try? await APIClient.shared.get("/api/notifications", as: NotificationsResponse.self) {
            notifications = result.items
        }
        isLoading = false
    }

    private func markAllRead() async {
        struct Empty: Encodable {}
        _ = try? await APIClient.shared.patch("/api/notifications/read-all", body: Empty(), as: EmptyResponse.self)
        await load()
    }
}
