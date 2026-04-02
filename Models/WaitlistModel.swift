import Foundation

struct WaitlistEntry: Decodable, Identifiable {
    let id: String
    let customerId: String?
    let providerId: String?
    let serviceId: String?
    let desiredDate: String?
    let timePreference: String?
    let notifiedAt: String?
    let isActive: Bool?
    let createdAt: String?
}

// Built by Christos Ferlachidis & Daniel Hedenberg

struct WaitlistRequest: Encodable {
    let providerId: String
    let serviceId: String
    let desiredDate: String
    let timePreference: String
}

struct WaitlistResponse: Decodable {
    let success: Bool?
    let message: String?
    let waitlistEntry: WaitlistEntry?
}

enum TimePreference: String, CaseIterable, Identifiable {
    case morning = "MORNING"
    case afternoon = "AFTERNOON"
    case evening = "EVENING"
    case any = "ANY"

    var id: String { rawValue }

    var labelSv: String {
        switch self {
        case .morning: return "Förmiddag"
        case .afternoon: return "Eftermiddag"
        case .evening: return "Kväll"
        case .any: return "När som helst"
        }
    }

    var labelEn: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .any: return "Any time"
        }
    }

    func label(isSv: Bool) -> String {
        isSv ? labelSv : labelEn
    }
}
