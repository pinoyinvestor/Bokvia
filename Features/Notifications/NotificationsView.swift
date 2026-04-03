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
        Group {
            if hasNavigationTarget(notif) {
                NavigationLink {
                    destinationForNotification(notif)
                } label: {
                    notificationContent(notif)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    markAsRead(notif)
                })
            } else {
                notificationContent(notif)
                    .onTapGesture {
                        markAsRead(notif)
                    }
            }
        }
    }

    private func notificationContent(_ notif: AppNotification) -> some View {
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
    }

    private func markAsRead(_ notif: AppNotification) {
        guard !notif.isRead else { return }
        Task {
            struct Empty: Encodable {}
            _ = try? await APIClient.shared.patch("/api/notifications/\(notif.id)/read", body: Empty(), as: EmptyResponse.self)
            await load()
        }
    }

    private func hasNavigationTarget(_ notif: AppNotification) -> Bool {
        if notif.data?.bookingId != nil && notif.type.hasPrefix("booking") { return true }
        if notif.data?.chatId != nil && notif.type == "new_message" { return true }
        if notif.data?.providerId != nil { return true }
        return false
    }

    @ViewBuilder
    private func destinationForNotification(_ notif: AppNotification) -> some View {
        if let bookingId = notif.data?.bookingId,
           notif.type.hasPrefix("booking") {
            BookingLoaderView(bookingId: bookingId)
        } else if let chatId = notif.data?.chatId,
                  notif.type == "new_message" {
            ChatDetailView(chatId: chatId)
        } else if let providerId = notif.data?.providerId {
            ProviderProfileView(slug: providerId)
        } else {
            EmptyView()
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

/// Fetches a booking by ID then shows BookingDetailView
struct BookingLoaderView: View {
    let bookingId: String
    @State private var booking: Booking?
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let booking = booking {
                BookingDetailView(booking: booking)
            } else {
                ContentUnavailableView(
                    "Booking not found",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text(errorMessage ?? "")
                )
            }
        }
        .task {
            do {
                booking = try await APIClient.shared.get("/api/bookings/\(bookingId)", as: Booking.self)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
