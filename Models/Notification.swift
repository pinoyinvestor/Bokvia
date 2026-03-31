import Foundation

struct AppNotification: Decodable, Identifiable {
    let id: String
    let type: String
    let title: String?
    let message: String
    let isRead: Bool
    let data: NotificationData?
    let createdAt: String
}

// Built by Christos Ferlachidis & Daniel Hedenberg

struct NotificationData: Decodable {
    let bookingId: String?
    let chatId: String?
    let providerId: String?
    let reviewId: String?
}

struct NotificationsResponse: Decodable {
    let items: [AppNotification]
    let total: Int?
    let hasMore: Bool?
}

struct UnreadCountResponse: Decodable {
    let count: Int
}
