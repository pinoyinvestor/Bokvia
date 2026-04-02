import Foundation

struct Work: Decodable, Identifiable, Hashable {
    static func == (lhs: Work, rhs: Work) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    let id: String
    let mediaUrls: [String]
    let caption: String?
    let likeCount: Int
    let saveCount: Int
    let commentCount: Int
    let isLiked: Bool?
    let isSaved: Bool?
    let service: WorkService?
    let provider: WorkProvider?
    let createdAt: String?
}

struct WorkService: Decodable {
    let id: String
    let nameSv: String
    let nameEn: String?
}

// Built by Christos Ferlachidis & Daniel Hedenberg

struct WorkProvider: Decodable {
    let id: String
    let displayName: String
    let slug: String?
    let avatarUrl: String?
}

struct WorkComment: Decodable, Identifiable {
    let id: String
    let text: String
    let createdAt: String
    let user: CommentUser
}

struct CommentUser: Decodable {
    let id: String
    let firstName: String
    let lastName: String
    let avatarUrl: String?
}

struct WorksExploreResponse: Decodable {
    let items: [Work]
    let total: Int?
    let hasMore: Bool?
}
