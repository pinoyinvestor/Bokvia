import SwiftUI

@Observable
class AppState {
    var isAuthenticated = false
    var currentUser: UserSession?
    var familyMembers: [FamilyProfile] = []
    var familyError: String?
    var activeBookingProfile: FamilyProfile?
    var activeProfileType: String = "CUSTOMER"
    var profiles: [UserProfile] = []

    var darkMode: Bool {
        didSet { UserDefaults.standard.set(darkMode, forKey: Config.darkModeKey) }
    }
    var language: String {
        didSet { UserDefaults.standard.set(language, forKey: Config.languageKey) }
    }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var colorScheme: ColorScheme? {
        darkMode ? .dark : nil
    }

    var locale: Locale {
        Locale(identifier: language)
    }

    var isSv: Bool {
        language == "sv"
    }

    init() {
        self.darkMode = UserDefaults.standard.bool(forKey: Config.darkModeKey)
        self.language = UserDefaults.standard.string(forKey: Config.languageKey) ?? "sv"
    }

    func setUser(_ session: UserSession) {
        currentUser = session
        isAuthenticated = true
        activeProfileType = session.activeProfileType ?? "CUSTOMER"
        profiles = session.profiles ?? []
    }

    func switchProfile(_ profileId: String) async {
        struct SwitchBody: Encodable { let profileId: String }
        do {
            let response = try await APIClient.shared.postAuth(
                "/api/auth/switch-profile",
                body: SwitchBody(profileId: profileId),
                as: AuthResponse.self
            )
            let user = response.data.user
            currentUser = user
            activeProfileType = user.activeProfileType ?? "CUSTOMER"
            profiles = user.profiles ?? []
        } catch {
            // Switch failed — keep current state
        }
    }

    func loadFamilyMembers() async {
        do {
            let members = try await APIClient.shared.get("/api/users/me/family", as: [FamilyProfile].self)
            familyMembers = members
        } catch {
            familyError = error.localizedDescription
        }
    }

    func switchBookingProfile(_ profile: FamilyProfile?) {
        activeBookingProfile = profile
    }

    func logout() {
        isAuthenticated = false
        currentUser = nil
        familyMembers = []
        activeBookingProfile = nil
        activeProfileType = "CUSTOMER"
        profiles = []
        Task {
            await AuthManager.shared.logout()
        }
    }
}
