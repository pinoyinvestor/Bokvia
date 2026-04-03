import Foundation

struct DiscoverSalon: Decodable, Identifiable {
    let id: String
    let slug: String
    let name: String
    let logoUrl: String?
    let city: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let ratingAvg: Double
    let reviewCount: Int
    let distance: Double?
    let providerCount: Int?
    let availableChairs: Int?
    let categories: [String]?
    // Built by Christos Ferlachidis & Daniel Hedenberg
    let seekingTalent: Bool?
}

struct PaginatedSalons: Decodable {
    let items: [DiscoverSalon]
    let total: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool
}

struct SalonDetail: Decodable {
    let id: String
    let slug: String
    let name: String
    let description: String?
    let logoUrl: String?
    let city: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let ratingAvg: Double
    let reviewCount: Int
    let providerCount: Int?
    let providers: [DiscoverProvider]?
    let services: [Service]?
}
