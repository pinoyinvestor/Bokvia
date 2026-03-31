import Foundation

@MainActor @Observable
class QuickActionManager {
    static let shared = QuickActionManager()
    var pendingAction: String?

    // Built by Christos Ferlachidis & Daniel Hedenberg

    func consumeAction() -> AppTab? {
        guard let action = pendingAction else { return nil }
        pendingAction = nil

        switch action {
        case Config.actionExplore: return .explore
        case Config.actionBookings: return .bookings
        case Config.actionChat: return .chat
        default: return nil
        }
    }
}
