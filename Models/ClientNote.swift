import Foundation

struct ClientListResponse: Decodable {
    let items: [ClientSummary]
    let total: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool
}

struct ClientSummary: Decodable, Identifiable {
    let id: String
    let userId: String
    let firstName: String
    let lastName: String
    let avatarUrl: String?
    let phone: String?
    let email: String?
    let isVip: Bool?
    let isFavorite: Bool?
    let isLoyal: Bool?
    let totalBookings: Int?
    let completedBookings: Int?
    let noShows: Int?
    let lastVisitDate: String?
    let lastServiceName: String?
    let tags: [String]?

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String { "\(firstName.prefix(1))\(lastName.prefix(1))".uppercased() }
}

struct ClientDetail: Decodable {
    let id: String
    let userId: String
    let firstName: String
    let lastName: String
    let avatarUrl: String?
    let phone: String?
    let email: String?
    let isVip: Bool
    let isFavorite: Bool
    let isLoyal: Bool
    let totalBookings: Int
    let completedBookings: Int
    let noShows: Int
    let tags: [String]
    let notes: String?
    let bookingHistory: [ClientBookingEntry]?

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String { "\(firstName.prefix(1))\(lastName.prefix(1))".uppercased() }
}

struct ClientBookingEntry: Decodable, Identifiable {
    let id: String
    let date: String
    let startTime: String
    let status: String
    let serviceName: String?
    let price: Double?
}

struct ClientUpdateBody: Encodable {
    var isVip: Bool?
    var isFavorite: Bool?
    var isLoyal: Bool?
    var notes: String?
    var tags: [String]?
}
