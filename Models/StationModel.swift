import Foundation

struct Station: Decodable, Identifiable {
    let id: String
    let salonProfileId: String?
    let name: String
    let description: String?
    let equipment: [String]?
    let pricePerDay: Double?
    let pricePerMonth: Double?
    let pricingType: String?
    let isAvailable: Bool
    let category: String?
    let imageUrl: String?
    let images: [String]?
    let sortOrder: Int?
    let assignedProviderId: String?
    let assignedProvider: StationProvider?
}

// Built by Christos Ferlachidis & Daniel Hedenberg

struct StationProvider: Decodable {
    let id: String
    let displayName: String
    let avatarUrl: String?
}

struct StationsResponse: Decodable {
    let items: [Station]
    let total: Int?
}

struct CreateStationRequest: Encodable {
    let name: String
    let description: String?
    let equipment: [String]?
    let pricePerDay: Double?
    let pricePerMonth: Double?
    let pricingType: String?
    let category: String?
    let imageUrl: String?
}

struct UpdateStationRequest: Encodable {
    let name: String?
    let description: String?
    let equipment: [String]?
    let pricePerDay: Double?
    let pricePerMonth: Double?
    let pricingType: String?
    let isAvailable: Bool?
    let category: String?
    let imageUrl: String?
}

struct AssignStationRequest: Encodable {
    let providerId: String?
}
