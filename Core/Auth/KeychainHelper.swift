import Foundation
import Security
import os

private let kLogger = Logger(subsystem: "se.bokvia.app", category: "Keychain")

enum KeychainHelper {
    private static let service = Config.keychainService
    private static let accessTokenKey = "accessToken"
    private static let refreshTokenKey = "refreshToken"

    static func saveAccessToken(_ token: String) {
        save(key: accessTokenKey, value: token)
    }

    static func getAccessToken() -> String? {
        read(key: accessTokenKey)
    }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    static func saveRefreshToken(_ token: String) {
        save(key: refreshTokenKey, value: token)
    }

    static func getRefreshToken() -> String? {
        read(key: refreshTokenKey)
    }

    static func deleteToken() {
        delete(key: accessTokenKey)
        delete(key: refreshTokenKey)
    }

    private static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(key: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            kLogger.error("Keychain save failed: \(status) for key \(key)")
        }
    }

    private static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        if status != errSecItemNotFound {
            kLogger.error("Keychain read failed: \(status) for key \(key)")
        }
        return nil
    }

    private static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
