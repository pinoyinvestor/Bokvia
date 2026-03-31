import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
}

struct GoogleAuthRequest: Encodable {
    let idToken: String
}

struct AppleAuthRequest: Encodable {
    let identityToken: String
    let authorizationCode: String
    let fullName: String?
    let email: String?
}

// Built by Christos Ferlachidis & Daniel Hedenberg

/// Server returns `{ success: true, data: { user, needsOnboarding? } }`
/// Tokens come via Set-Cookie headers (access_token, refresh_token)
struct AuthResponse: Decodable {
    let success: Bool
    let data: AuthResponseData
}

struct AuthResponseData: Decodable {
    let user: UserSession
    let needsOnboarding: Bool?
}

struct UserSession: Decodable, Equatable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let avatarUrl: String?
    let phone: String?
    let gender: String?
    let dateOfBirth: String?
    let locale: String?
    let roles: [String]
    let activeProfileId: String?
    let activeProfileType: String?
    let needsOnboarding: Bool?
    let profiles: [UserProfile]?

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let f = firstName.prefix(1)
        let l = lastName.prefix(1)
        return "\(f)\(l)".uppercased()
    }
}

struct UserProfile: Decodable, Equatable {
    let id: String
    let type: String
}

/// GET /api/users/me returns { success: true, data: { user } } or just the user object
struct UserMeResponse: Decodable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let avatarUrl: String?
    let phone: String?
    let gender: String?
    let dateOfBirth: String?
    let locale: String?
    let roles: [String]
    let activeProfileId: String?
    let activeProfileType: String?
    let needsOnboarding: Bool?

    func toSession() -> UserSession {
        UserSession(
            id: id, email: email, firstName: firstName, lastName: lastName,
            avatarUrl: avatarUrl, phone: phone, gender: gender, dateOfBirth: dateOfBirth,
            locale: locale, roles: roles, activeProfileId: activeProfileId,
            activeProfileType: activeProfileType, needsOnboarding: needsOnboarding,
            profiles: nil
        )
    }
}
