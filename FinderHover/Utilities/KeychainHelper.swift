//
//  KeychainHelper.swift
//  FinderHover
//
//  Generic Keychain CRUD for license and trial data storage.
//  Keychain is more tamper-resistant than UserDefaults.
//

import Foundation
import Security

enum KeychainHelper {

    private static let serviceIdentifier = "dev.koukeneko.FinderHover"

    enum Key: String {
        case trialStartDate = "finderhover.trial.startDate"
        case transactionID = "finderhover.license.transactionID"
        case customerEmail = "finderhover.license.customerEmail"
        case lastVerificationDate = "finderhover.license.lastVerified"
    }

    // MARK: - String Storage

    @discardableResult
    static func save(_ value: String, forKey key: Key) -> Bool {
        delete(forKey: key)

        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func load(forKey key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return string
    }

    @discardableResult
    static func delete(forKey key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key.rawValue,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Date Convenience

    @discardableResult
    static func saveDate(_ date: Date, forKey key: Key) -> Bool {
        let string = ISO8601DateFormatter().string(from: date)
        return save(string, forKey: key)
    }

    static func loadDate(forKey key: Key) -> Date? {
        guard let string = load(forKey: key) else { return nil }
        return ISO8601DateFormatter().date(from: string)
    }
}
