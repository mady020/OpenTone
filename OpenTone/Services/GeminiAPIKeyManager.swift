import Foundation
import Security

/// Manages Gemini API key storage using Keychain for security.
final class GeminiAPIKeyManager {

    static let shared = GeminiAPIKeyManager()

    private let keychainKey = "com.opentone.gemini-api-key"

    private init() {}

    // MARK: - Public API

    /// Whether a Gemini API key has been saved.
    var hasAPIKey: Bool {
        getAPIKey() != nil
    }

    /// Retrieve the stored API key, or nil.
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else {
            return nil
        }
        return key
    }

    /// Save or update the API key in the Keychain.
    @discardableResult
    func setAPIKey(_ key: String) -> Bool {
        // Delete existing first
        deleteAPIKey()

        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String:   data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Remove the stored API key.
    @discardableResult
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Returns a masked version of the key for display (e.g. "AIza•••••xyz")
    var maskedKey: String? {
        guard let key = getAPIKey(), key.count > 8 else { return nil }
        let prefix = String(key.prefix(4))
        let suffix = String(key.suffix(4))
        return "\(prefix)••••••\(suffix)"
    }
}
