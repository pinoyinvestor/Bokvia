import Foundation

struct SalonStatsResponse: Decodable {
    let todayBookings: Int
    let weekBookings: Int
    let monthlyRevenue: Double
    let teamSize: Int
}

struct SalonActivityItem: Decodable, Identifiable {
    let id: String
    let type: String
    let providerName: String?
    let description: String?
    let timestamp: String
}

// Built by Christos Ferlachidis & Daniel Hedenberg

struct SalonActivityFeed: Decodable {
    let items: [SalonActivityItem]
}

struct SalonStationOverview: Decodable {
    let total: Int
    let occupied: Int
}

struct SalonTodayBooking: Decodable, Identifiable {
    let id: String
    let providerName: String?
    let customerName: String?
    let customerAvatarUrl: String?
    let serviceName: String?
    let startTime: String
    let endTime: String?
    let status: String
    let familyProfileName: String?
}

struct SalonTodayBookingsResponse: Decodable {
    let items: [SalonTodayBooking]
}
