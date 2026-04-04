import Foundation

enum BookingStatus: String, Decodable, CaseIterable {
    case pending = "PENDING"
    case pendingConfirmation = "PENDING_CONFIRMATION"
    case confirmed = "CONFIRMED"
    case cancelledByCustomer = "CANCELLED_BY_CUSTOMER"
    case cancelledByProvider = "CANCELLED_BY_PROVIDER"
    case noShow = "NO_SHOW"
    case completed = "COMPLETED"
    case disputed = "DISPUTED"

    var label: String {
        switch self {
        case .pending: return "Väntande"
        case .pendingConfirmation: return "Inväntar bekräftelse"
        case .confirmed: return "Bekräftad"
        case .cancelledByCustomer: return "Avbokad av dig"
        case .cancelledByProvider: return "Avbokad av frisör"
        case .noShow: return "Utebliven"
        case .completed: return "Slutförd"
        case .disputed: return "Ifrågasatt"
        }
    }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var isActive: Bool {
        self == .pending || self == .pendingConfirmation || self == .confirmed
    }

    var isPast: Bool {
        !isActive
    }
}

struct Booking: Decodable, Identifiable {
    let id: String
    let status: String
    let startTime: String
    let endTime: String?
    let date: String
    let duration: Int?
    let provider: BookingProvider?
    let service: BookingService?
    let familyProfile: BookingFamilyProfile?
    let createdAt: String?
    let notes: String?
    let workMode: String?
    let address: String?

    var statusEnum: BookingStatus {
        BookingStatus(rawValue: status) ?? .pending
    }
}

struct BookingProvider: Decodable {
    let id: String
    let displayName: String
    let slug: String?
    let avatarUrl: String?
    let cancellationHours: Int?
}

struct BookingService: Decodable {
    let id: String
    let nameSv: String
    let nameEn: String?
    let price: Double?
    let duration: Int?
}

struct BookingFamilyProfile: Decodable {
    let id: String
    let name: String
}

struct BookingsResponse: Decodable {
    let items: [Booking]
    let total: Int?
    let hasMore: Bool?
}

struct NextBookingResponse: Decodable {
    let booking: Booking?
}
