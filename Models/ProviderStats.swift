import Foundation

struct ProviderStatsResponse: Decodable {
    let totalBookings: Int
    let completedBookings: Int
    let revenue: Double
    let completionRate: Double
    let averageRating: Double
    let reviewCount: Int
    let newClientsThisMonth: Int
    let returningClients: Int
    let noShows: Int
    let cancelledByCustomer: Int
    let cancelledByProvider: Int
    let revenueBreakdown: RevenueBreakdown?
}

// Built by Christos Ferlachidis & Daniel Hedenberg

struct RevenueBreakdown: Decodable {
    let labels: [String]
    let values: [Double]
}

struct ProviderBooking: Decodable, Identifiable {
    let id: String
    let status: String
    let startTime: String
    let endTime: String?
    let date: String
    let duration: Int?
    let notes: String?
    let workMode: String?
    let address: String?
    let createdAt: String?
    let customer: ProviderBookingCustomer?
    let service: BookingService?

    var statusEnum: BookingStatus {
        BookingStatus(rawValue: status) ?? .pending
    }
}

struct ProviderBookingCustomer: Decodable {
    let id: String
    let firstName: String
    let lastName: String
    let avatarUrl: String?
    let phone: String?
    let email: String?

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String { "\(firstName.prefix(1))\(lastName.prefix(1))".uppercased() }
}

struct ProviderTodayResponse: Decodable {
    let items: [ProviderBooking]
    let total: Int?
}

struct ProviderBookingsResponse: Decodable {
    let items: [ProviderBooking]
    let total: Int?
    let hasMore: Bool?
}
