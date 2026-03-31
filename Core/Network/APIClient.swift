import Foundation
import os

private let apiLogger = Logger(subsystem: "se.bokvia.app", category: "API")

actor APIClient {
    static let shared = APIClient()
    private let baseURL = Config.baseURL
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private var refreshTask: Task<Void, Error>?

    func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        do {
            return try await performRequest(path: path, method: "GET", body: nil as String?, authenticated: true, as: type)
        } catch APIError.unauthorized {
            try await refreshAndRetry()
            return try await performRequest(path: path, method: "GET", body: nil as String?, authenticated: true, as: type)
        }
    }

    func getOptionalAuth<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        try await performRequest(path: path, method: "GET", body: nil as String?, authenticated: KeychainHelper.getAccessToken() != nil, as: type)
    }

    func getNoAuth<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        try await performRequest(path: path, method: "GET", body: nil as String?, authenticated: false, as: type)
    }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    func post<B: Encodable, T: Decodable>(_ path: String, body: B, as type: T.Type) async throws -> T {
        do {
            return try await performRequest(path: path, method: "POST", body: body, authenticated: true, as: type)
        } catch APIError.unauthorized {
            try await refreshAndRetry()
            return try await performRequest(path: path, method: "POST", body: body, authenticated: true, as: type)
        }
    }

    func postNoAuth<B: Encodable, T: Decodable>(_ path: String, body: B, as type: T.Type) async throws -> T {
        try await performRequest(path: path, method: "POST", body: body, authenticated: false, as: type)
    }

    /// POST for auth endpoints — extracts tokens from Set-Cookie headers and stores in Keychain
    func postAuth<B: Encodable, T: Decodable>(_ path: String, body: B, as type: T.Type) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.serverError("Invalid URL: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try encoder.encode(body)

        apiLogger.debug("AUTH POST \(path)")
        let (data, response) = try await session.data(for: request)
        let http = response as? HTTPURLResponse
        apiLogger.debug("AUTH RES \(path) status=\(http?.statusCode ?? -1)")
        try validateResponse(response)

        // Extract tokens from Set-Cookie headers
        extractAndStoreTokens(from: http)

        return try decoder.decode(T.self, from: data)
    }

    /// POST for refresh — sends refresh_token as cookie, extracts new tokens
    func postRefresh<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.serverError("Invalid URL: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.userAgent, forHTTPHeaderField: "User-Agent")

        // Send tokens as cookies (server refresh guard reads from cookie)
        var cookies: [String] = []
        if let at = KeychainHelper.getAccessToken() {
            cookies.append("access_token=\(at)")
        }
        if let rt = KeychainHelper.getRefreshToken() {
            cookies.append("refresh_token=\(rt)")
        }
        if !cookies.isEmpty {
            request.setValue(cookies.joined(separator: "; "), forHTTPHeaderField: "Cookie")
        }

        // Also send as Bearer for guards that check Authorization header
        if let at = KeychainHelper.getAccessToken() {
            request.setValue("Bearer \(at)", forHTTPHeaderField: "Authorization")
        }

        apiLogger.debug("REFRESH POST \(path)")
        let (data, response) = try await session.data(for: request)
        let http = response as? HTTPURLResponse
        apiLogger.debug("REFRESH RES \(path) status=\(http?.statusCode ?? -1)")
        try validateResponse(response)

        extractAndStoreTokens(from: http)

        return try decoder.decode(T.self, from: data)
    }

    func patch<B: Encodable, T: Decodable>(_ path: String, body: B, as type: T.Type) async throws -> T {
        do {
            return try await performRequest(path: path, method: "PATCH", body: body, authenticated: true, as: type)
        } catch APIError.unauthorized {
            try await refreshAndRetry()
            return try await performRequest(path: path, method: "PATCH", body: body, authenticated: true, as: type)
        }
    }

    func delete(_ path: String) async throws {
        do {
            let _: EmptyResponse = try await performRequest(path: path, method: "DELETE", body: nil as String?, authenticated: true, as: EmptyResponse.self)
        } catch APIError.unauthorized {
            try await refreshAndRetry()
            let _: EmptyResponse = try await performRequest(path: path, method: "DELETE", body: nil as String?, authenticated: true, as: EmptyResponse.self)
        }
    }

    func delete<B: Encodable>(_ path: String, body: B) async throws {
        do {
            let _: EmptyResponse = try await performRequest(path: path, method: "DELETE", body: body, authenticated: true, as: EmptyResponse.self)
        } catch APIError.unauthorized {
            try await refreshAndRetry()
            let _: EmptyResponse = try await performRequest(path: path, method: "DELETE", body: body, authenticated: true, as: EmptyResponse.self)
        }
    }

    func uploadImage<T: Decodable>(_ path: String, imageData: Data, filename: String, fields: [String: String] = [:], as type: T.Type) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.serverError("Invalid URL: \(path)")
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.userAgent, forHTTPHeaderField: "User-Agent")
        if let token = KeychainHelper.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        var body = Data()
        for (key, value) in fields {
            body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\nContent-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }

    private func performRequest<B: Encodable, T: Decodable>(path: String, method: String, body: B?, authenticated: Bool, as type: T.Type, maxRetries: Int = Config.maxRetries) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.serverError("Invalid URL: \(path)")
        }

        var lastError: Error = APIError.networkError
        for attempt in 0..<maxRetries {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = method
                request.setValue(Config.userAgent, forHTTPHeaderField: "User-Agent")
                if authenticated, let token = KeychainHelper.getAccessToken() {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    // Also send as cookie for endpoints that read from cookies
                    request.setValue("access_token=\(token)", forHTTPHeaderField: "Cookie")
                }
                if let body = body {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try encoder.encode(body)
                }
                apiLogger.debug("REQ \(method) \(path) attempt=\(attempt + 1)")
                let (data, response) = try await session.data(for: request)
                let http = response as? HTTPURLResponse
                apiLogger.debug("RES \(method) \(path) status=\(http?.statusCode ?? -1)")
                try validateResponse(response)
                return try decoder.decode(T.self, from: data)
            } catch let error as APIError where error == .unauthorized || error == .forbidden || error == .notFound {
                throw error
            } catch let error as APIError where error == .rateLimited {
                lastError = error
                let delay = Double(1 << attempt)
                apiLogger.warning("Rate limited on \(path), retrying in \(delay)s")
                try await Task.sleep(for: .seconds(delay))
            } catch {
                lastError = error
                if attempt < maxRetries - 1 {
                    let delay = Double(1 << attempt) * 0.5
                    apiLogger.warning("Request failed \(path): \(error.localizedDescription), retrying in \(delay)s")
                    try await Task.sleep(for: .seconds(delay))
                }
            }
        }
        throw lastError
    }

    private func refreshAndRetry() async throws {
        if let existing = refreshTask {
            try await existing.value
            return
        }
        let task = Task {
            defer { refreshTask = nil }
            try await AuthManager.shared.refreshAccessToken()
        }
        refreshTask = task
        try await task.value
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        switch http.statusCode {
        case 200...299: return
        case 401: throw APIError.unauthorized
        case 403: throw APIError.forbidden
        case 404: throw APIError.notFound
        case 429: throw APIError.rateLimited
        default: throw APIError.serverError("Server error (\(http.statusCode))")
        }
    }

    /// Extract access_token and refresh_token from Set-Cookie response headers
    private func extractAndStoreTokens(from response: HTTPURLResponse?) {
        guard let headers = response?.allHeaderFields as? [String: String],
              let url = response?.url else { return }

        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
        for cookie in cookies {
            if cookie.name == "access_token" {
                KeychainHelper.saveAccessToken(cookie.value)
                apiLogger.debug("Stored access_token from cookie")
            } else if cookie.name == "refresh_token" {
                KeychainHelper.saveRefreshToken(cookie.value)
                apiLogger.debug("Stored refresh_token from cookie")
            }
        }
    }
}

struct EmptyResponse: Decodable {}
