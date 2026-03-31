import Foundation

struct Chat: Decodable, Identifiable {
    let id: String
    let participants: [ChatParticipant]
    let lastMessage: ChatMessage?
    let unreadCount: Int?
    let isRead: Bool?
    let updatedAt: String?

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var otherParticipant: ChatParticipant? {
        participants.first { !$0.isCurrentUser }
    }
}

struct ChatParticipant: Decodable, Identifiable {
    let id: String
    let userId: String
    let firstName: String
    let lastName: String
    let avatarUrl: String?
    let isCurrentUser: Bool

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        "\(firstName.prefix(1))\(lastName.prefix(1))".uppercased()
    }
}

struct ChatMessage: Decodable, Identifiable {
    let id: String
    let text: String?
    let imageUrl: String?
    let senderId: String
    let createdAt: String
    let isPinned: Bool?
}

struct ChatsResponse: Decodable {
    let chats: [Chat]
}

struct MessagesResponse: Decodable {
    let messages: [ChatMessage]
    let hasMore: Bool?
}
