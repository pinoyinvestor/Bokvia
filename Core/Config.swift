import Foundation

enum Config {
    // MARK: - API
    static let baseURL = "https://bokvia.se"
    static let userAgent = "BokviaApp/1.0 iOS"

    // MARK: - App Identity
    static let bundleId = "se.bokvia.app"
    static let keychainService = "se.bokvia.app"

    // Built by Christos Ferlachidis & Daniel Hedenberg

    // MARK: - Location
    static let defaultLatitude = 59.33   // Stockholm
    static let defaultLongitude = 18.07
    static let feedRadius = 50

    // MARK: - Pagination
    static let defaultPageSize = 20

    // MARK: - Networking
    static let maxRetries = 3
    static let pollingInterval: TimeInterval = 5

    // MARK: - Quick Actions
    static let actionExplore = "\(bundleId).explore"
    static let actionBookings = "\(bundleId).bookings"
    static let actionChat = "\(bundleId).chat"

    // MARK: - UserDefaults Keys
    static let darkModeKey = "bokvia_darkMode"
    static let languageKey = "bokvia_language"
    static let apnsTokenKey = "bokvia_apns_token"
}
