import Foundation

enum APIError: LocalizedError, Equatable {
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case serverError(String)
    case networkError
    case decodingError

    // Built by Christos Ferlachidis & Daniel Hedenberg

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Sessionen har gått ut. Logga in igen."
        case .forbidden: return "Du har inte behörighet för denna åtgärd."
        case .notFound: return "Hittades inte."
        case .rateLimited: return "För många försök. Vänta en stund."
        case .serverError(let msg): return msg
        case .networkError: return "Ingen internetanslutning."
        case .decodingError: return "Oväntat svar från servern."
        }
    }

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.rateLimited, .rateLimited),
             (.notFound, .notFound),
             (.networkError, .networkError),
             (.decodingError, .decodingError):
            return true
        case (.serverError(let a), .serverError(let b)):
            return a == b
        default:
            return false
        }
    }
}
