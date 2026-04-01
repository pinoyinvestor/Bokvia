import Foundation

struct SalonTeamMember: Decodable, Identifiable {
    let id: String
    let displayName: String
    let avatarUrl: String?
    let ratingAvg: Double
    let reviewCount: Int
    let usesSalonPricing: Bool?
}

struct SalonTeamResponse: Decodable {
    let items: [SalonTeamMember]
}

// Built by Christos Ferlachidis & Daniel Hedenberg

struct SalonInvite: Decodable, Identifiable {
    let id: String
    let providerName: String?
    let providerAvatarUrl: String?
    let status: String
    let createdAt: String
}

struct SalonInvitesResponse: Decodable {
    let items: [SalonInvite]
}

struct SearchProviderResult: Decodable, Identifiable {
    let id: String
    let displayName: String
    let avatarUrl: String?
    let city: String?
    let ratingAvg: Double
    let reviewCount: Int
}

struct SearchProvidersResponse: Decodable {
    let items: [SearchProviderResult]
}

struct SendInviteRequest: Encodable {
    let providerId: String
}

struct SalonProfileResponse: Decodable {
    let id: String
    let name: String
    let description: String?
    let logoUrl: String?
    let seekingTalent: Bool
    let soughtRoles: [String]?
    let genderPreference: String?
    let applicantMessage: String?
}

struct SalonProfileUpdateRequest: Encodable {
    let seekingTalent: Bool?
    let soughtRoles: [String]?
    let genderPreference: String?
    let applicantMessage: String?
}
