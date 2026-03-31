import Foundation

struct Category: Decodable, Identifiable {
    let id: String
    let slug: String
    let nameSv: String
    let nameEn: String?
    let emoji: String?

    func name(locale: String) -> String {
        locale == "en" ? (nameEn ?? nameSv) : nameSv
    }
}

// Built by Christos Ferlachidis & Daniel Hedenberg

struct FamilyProfile: Decodable, Identifiable {
    let id: String
    let name: String
    let gender: String?
    let dateOfBirth: String?
    let preferredCategoryIds: [String]?

    var segment: String {
        guard let gender = gender else { return "UNSPECIFIED" }
        let age = dateOfBirth.flatMap { calculateAge($0) } ?? 30
        switch gender.uppercased() {
        case "MALE": return age < 18 ? "BOY" : "MAN"
        case "FEMALE": return age < 18 ? "GIRL" : "WOMAN"
        default: return "UNSPECIFIED"
        }
    }

    private func calculateAge(_ dob: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dob) else { return nil }
        return Calendar.current.dateComponents([.year], from: date, to: Date()).year
    }
}

struct Review: Decodable, Identifiable {
    let id: String
    let rating: Int
    let text: String?
    let createdAt: String
    let customer: ReviewCustomer?
}

struct ReviewCustomer: Decodable {
    let firstName: String
    let lastName: String
    let avatarUrl: String?
}

struct ReviewsResponse: Decodable {
    let items: [Review]
    let total: Int?
    let hasMore: Bool?
}

struct Slot: Decodable, Identifiable {
    let id: String
    let startTime: String
    let endTime: String
    let status: String?
    let isAvailable: Bool?
}

struct SlotsResponse: Decodable {
    let slots: [Slot]
}

struct AvailabilityResponse: Decodable {
    let dates: [DateAvailability]
}

struct DateAvailability: Decodable {
    let date: String
    let count: Int
}
