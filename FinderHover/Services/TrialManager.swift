//
//  TrialManager.swift
//  FinderHover
//
//  Manages 30-day trial period and license validation
//

import Combine
import Foundation
import Security

enum LicenseStatus: Equatable {
    case trial(daysRemaining: Int)
    case expired
    case purchased
}

@MainActor
class TrialManager: ObservableObject {
    static let shared = TrialManager()

    @Published private(set) var licenseStatus: LicenseStatus = .expired

    var isFeatureUnlocked: Bool {
        switch licenseStatus {
        case .trial: return true
        case .purchased: return true
        case .expired: return false
        }
    }

    private let keychainKey = "dev.koukeneko.FinderHover.trialStartDate"

    private init() {
        validateLicense()
    }

    // MARK: - License Validation

    func validateLicense() {
        // Check purchase status first
        if StoreKitService.shared.isPurchased {
            licenseStatus = .purchased
            return
        }

        // Check trial
        guard let startDate = readTrialStartDate() else {
            // First launch — activate trial
            activateTrial()
            return
        }

        let daysElapsed = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let daysRemaining = max(Constants.Trial.durationDays - daysElapsed, 0)

        if daysRemaining > 0 {
            licenseStatus = .trial(daysRemaining: daysRemaining)
        } else {
            licenseStatus = .expired
        }
    }

    func markAsPurchased() {
        licenseStatus = .purchased
    }

    // MARK: - Trial Activation

    private func activateTrial() {
        let now = Date()
        saveTrialStartDate(now)
        licenseStatus = .trial(daysRemaining: Constants.Trial.durationDays)
    }

    // MARK: - Keychain Storage (persists across app reinstalls)

    private func readTrialStartDate() -> Date? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "dev.koukeneko.FinderHover",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let timestamp = String(data: data, encoding: .utf8),
              let interval = TimeInterval(timestamp) else {
            return nil
        }

        return Date(timeIntervalSince1970: interval)
    }

    private func saveTrialStartDate(_ date: Date) {
        let timestamp = String(date.timeIntervalSince1970)
        guard let data = timestamp.data(using: .utf8) else { return }

        // Delete existing entry
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "dev.koukeneko.FinderHover"
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new entry
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "dev.koukeneko.FinderHover",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
