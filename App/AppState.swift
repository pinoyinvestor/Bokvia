import SwiftUI

@Observable
class AppState {
    var isAuthenticated = false
    var currentUser: UserSession?
    var familyMembers: [FamilyProfile] = []
    var familyError: String?
    var activeBookingProfile: FamilyProfile?

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
        Task {
            await AuthManager.shared.logout()
        }
    }
}
