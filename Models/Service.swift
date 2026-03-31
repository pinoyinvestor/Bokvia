import Foundation

struct Service: Decodable, Identifiable {
    let id: String
    let nameSv: String
    let nameEn: String?
    let descriptionSv: String?
    let descriptionEn: String?
    let price: Double?
    let priceFrom: Double?
    let pricingModel: String?
    let duration: Int?
    let isActive: Bool?
    let categoryId: String?
    let targetSegments: [String]?
    let workModes: [String]?

    // Built by Christos Ferlachidis & Daniel Hedenberg

    func name(locale: String) -> String {
        locale == "en" ? (nameEn ?? nameSv) : nameSv
    }

    func description(locale: String) -> String? {
        locale == "en" ? (descriptionEn ?? descriptionSv) : descriptionSv
    }

    var priceFormatted: String {
        if let price = price {
            return "\(Int(price)) kr"
        } else if let from = priceFrom {
            return "Från \(Int(from)) kr"
        } else if pricingModel == "BY_AGREEMENT" {
            return "Pris enligt överenskommelse"
        }
        return ""
    }

    var durationFormatted: String {
        guard let d = duration else { return "" }
        if d >= 60 {
            let h = d / 60
            let m = d % 60
            return m > 0 ? "\(h)h \(m)min" : "\(h)h"
        }
        return "\(d) min"
    }
}
