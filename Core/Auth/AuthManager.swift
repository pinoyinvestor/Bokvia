import Foundation
import UIKit

@MainActor @Observable
class AuthManager {
    static let shared = AuthManager()

    func login(email: String, password: String) async throws -> UserSession {
        let body = LoginRequest(
            email: email.lowercased().trimmingCharacters(in: .whitespaces),
            password: password
        )
        let response = try await APIClient.shared.postAuth("/api/auth/login", body: body, as: AuthResponse.self)
        await PushManager.shared.sendPendingToken()
        return response.data.user
    }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    func loginWithGoogle(idToken: String) async throws -> UserSession {
        let body = GoogleAuthRequest(idToken: idToken)
        let response = try await APIClient.shared.postAuth("/api/auth/google", body: body, as: AuthResponse.self)
        await PushManager.shared.sendPendingToken()
        return response.data.user
    }

    func loginWithApple(identityToken: String, authorizationCode: String, fullName: PersonNameComponents?, email: String?) async throws -> UserSession {
        let name = [fullName?.givenName, fullName?.familyName].compactMap { $0 }.joined(separator: " ")
        let body = AppleAuthRequest(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            fullName: name.isEmpty ? nil : name,
            email: email
        )
        let response = try await APIClient.shared.postAuth("/api/auth/apple", body: body, as: AuthResponse.self)
        await PushManager.shared.sendPendingToken()
        return response.data.user
    }

    func register(firstName: String, lastName: String, email: String, password: String) async throws -> UserSession {
        let body = RegisterRequest(
            firstName: firstName,
            lastName: lastName,
            email: email.lowercased().trimmingCharacters(in: .whitespaces),
            password: password
        )
        let response = try await APIClient.shared.postAuth("/api/auth/register", body: body, as: AuthResponse.self)
        await PushManager.shared.sendPendingToken()
        return response.data.user
    }

    func validateSession() async throws -> UserSession {
        let user = try await APIClient.shared.get("/api/users/me", as: UserMeResponse.self)
        return user.toSession()
    }

    func refreshAccessToken() async throws {
        // Server reads refresh_token from cookie, rotates both tokens
        let _ = try await APIClient.shared.postRefresh("/api/auth/refresh", as: AuthResponse.self)
    }

    func logout() async {
        // Server reads token from cookie/header, deletes refresh tokens, clears cookies
        struct Empty: Encodable {}
        _ = try? await APIClient.shared.post("/api/auth/logout", body: Empty(), as: EmptyResponse.self)
        KeychainHelper.deleteToken()
    }
}
