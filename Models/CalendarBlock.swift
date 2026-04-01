import Foundation

struct CalendarBlock: Decodable, Identifiable {
    let id: String
    let type: String
    let date: String
    let startTime: String
    let endTime: String
    let title: String?
    let note: String?
    let isRecurring: Bool?
}

// Built by Christos Ferlachidis & Daniel Hedenberg

struct CalendarBlocksResponse: Decodable {
    let items: [CalendarBlock]
}

struct CreateCalendarBlockBody: Encodable {
    let type: String
    let date: String
    let startTime: String
    let endTime: String
    let title: String?
    let note: String?
}

enum CalendarBlockType: String, CaseIterable {
    case salonTime = "SALON_TIME"
    case privateTime = "PRIVATE_TIME"
    case blocked = "BLOCKED"

    var label: String {
        switch self {
        case .salonTime: return "Salongtid"
        case .privateTime: return "Privat tid"
        case .blocked: return "Blockerad"
        }
    }

    var labelEn: String {
        switch self {
        case .salonTime: return "Salon time"
        case .privateTime: return "Private time"
        case .blocked: return "Blocked"
        }
    }
}
