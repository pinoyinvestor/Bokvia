import Foundation

struct ProviderProfile: Decodable, Identifiable {
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
    let isSponsored: Bool
    let bookingMode: String?
    let phoneVisible: Bool?
    let phone: String?

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var ratingFormatted: String {
        String(format: "%.1f", ratingAvg)
    }
}

struct DiscoverProvider: Decodable, Identifiable {
    let id: String
    let slug: String
    let displayName: String
    let avatarUrl: String?
    let city: String?
    let latitude: Double?
    let longitude: Double?
    let ratingAvg: Double
    let reviewCount: Int
    let isVerified: Bool
    let isSponsored: Bool
    let distance: Double?
    let startingPrice: Double?
    let isOpenNow: Bool?
    let bookingsCount: Int?
    let services: [ProviderServiceSummary]?
    let workModes: [String]?
    let subcategoryTags: [SubcategoryTag]?
}

struct ProviderServiceSummary: Decodable {
    let nameSv: String
    let nameEn: String?
}

struct SubcategoryTag: Decodable {
    let nameSv: String
    let nameEn: String
}

struct DiscoverSections: Decodable {
    let topSalons: [DiscoverSalon]?
    let sponsored: [DiscoverProvider]?
    let topRated: [DiscoverProvider]?
    let openNow: [DiscoverProvider]?
}

struct PaginatedProviders: Decodable {
    let items: [DiscoverProvider]
    let total: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool
}
