import Foundation

struct ScheduleResponse: Decodable {
    let schedules: [WorkModeSchedule]
}

struct WorkModeSchedule: Decodable, Identifiable {
    let id: String
    let workMode: String
    let days: [ScheduleDay]
}

// Built by Christos Ferlachidis & Daniel Hedenberg

struct ScheduleDay: Decodable, Identifiable {
    var id: String { "\(dayOfWeek)" }
    let dayOfWeek: Int
    let isActive: Bool
    let startTime: String?
    let endTime: String?
}

struct SaveScheduleBody: Encodable {
    let workMode: String
    let days: [SaveScheduleDayBody]
}

struct SaveScheduleDayBody: Encodable {
    let dayOfWeek: Int
    let isActive: Bool
    let startTime: String?
    let endTime: String?
}

struct ProviderMeResponse: Decodable {
    let id: String
    let slug: String
    let displayName: String
    let bio: String?
    let avatarUrl: String?
    let city: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let ratingAvg: Double
    let reviewCount: Int
    let isVerified: Bool
    let bookingMode: String?
    let phoneVisible: Bool?
    let phone: String?
    let acceptSalonBookings: Bool?
    let preBookingMessages: Bool?
    let workModes: [String]?
    let services: [Service]?
    let autoBookRules: [AutoBookRule]?
    let homeVisitCities: [String]?
}

struct AutoBookRule: Decodable, Identifiable {
    let id: String
    let dayOfWeek: Int
    let startTime: String
    let endTime: String
}

struct UpdateProviderBody: Encodable {
    var displayName: String?
    var bio: String?
    var bookingMode: String?
    var phoneVisible: Bool?
    var acceptSalonBookings: Bool?
    var preBookingMessages: Bool?
    var workModes: [String]?
    var homeVisitCities: [String]?
}

struct CreateAutoBookRuleBody: Encodable {
    let dayOfWeek: Int
    let startTime: String
    let endTime: String
}

struct AddServiceBody: Encodable {
    let serviceId: String
}

struct RemoveServiceBody: Encodable {
    let serviceId: String
}

struct SalonInvite: Decodable, Identifiable {
    let id: String
    let salonId: String
    let salonName: String
    let salonLogoUrl: String?
    let salonCity: String?
    let message: String?
    let chairPrice: Double?
    let commissionPercent: Double?
    let createdAt: String?
}

struct InviteActionBody: Encodable {
    let pricingChoice: String?
}
