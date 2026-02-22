//
//  PaddleService.swift
//  FinderHover
//
//  Paddle Billing integration for license management and purchase.
//  Uses web checkout (browser) + REST API verification.
//  Open-source builds with placeholder credentials unlock all features.
//

import AppKit
import Combine
import Foundation

// MARK: - License Status

enum LicenseStatus: Equatable {
    case trial(daysRemaining: Int)
    case expired
    case licensed
}

// MARK: - PaddleService

@MainActor
class PaddleService: ObservableObject {
    static let shared = PaddleService()

    @Published private(set) var licenseStatus: LicenseStatus = .expired
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Open-Source Build Detection

    /// Placeholder credentials = open-source build → all features unlocked
    private var isOpenSourceBuild: Bool {
        PaddleSecrets.apiKey == "YOUR_API_KEY"
    }

    var isFeatureUnlocked: Bool {
        if isOpenSourceBuild { return true }
        switch licenseStatus {
        case .trial, .licensed: return true
        case .expired: return false
        }
    }

    private init() {
        if isOpenSourceBuild {
            licenseStatus = .licensed
        } else {
            loadStoredLicenseState()
        }
    }

    // MARK: - Status

    func refreshStatus() {
        guard !isOpenSourceBuild else { return }

        if hasValidStoredLicense() {
            licenseStatus = .licensed
            maybeReverify()
            return
        }

        updateTrialStatus()
    }

    // MARK: - Purchase (Opens Browser)

    func startPurchase(window: NSWindow? = nil) {
        guard !isOpenSourceBuild else { return }

        guard PaddleSecrets.checkoutURL != "YOUR_CHECKOUT_URL",
              let url = URL(string: PaddleSecrets.checkoutURL)
        else {
            errorMessage = "license.purchase.failed".localized
            return
        }

        NSWorkspace.shared.open(url)
    }

    // MARK: - License Activation (Email-Based)

    func activateLicense(email: String, code: String) {
        guard !isOpenSourceBuild else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Verify transaction ID belongs to this email
                let transaction = try await PaddleBillingAPI.verifyTransaction(
                    transactionID: code
                )

                guard transaction.status == "completed" else {
                    throw PaddleBillingAPI.APIError.noCompletedTransaction
                }

                // Confirm the transaction belongs to the provided email
                if let customerID = transaction.customerId {
                    let customer = try await PaddleBillingAPI.findCustomer(email: email)
                    guard customer.id == customerID else {
                        throw PaddleBillingAPI.APIError.noCustomerFound
                    }
                }

                storeLicense(transactionID: code, email: email)
                licenseStatus = .licensed
            } catch {
                errorMessage = "license.activate.failed".localized
            }

            isLoading = false
        }
    }

    // MARK: - URL Scheme Activation (Auto)

    /// Handle `finderhover://activate?_ptxn=txn_xxx` callback from Paddle checkout
    func handleActivationURL(_ url: URL) {
        Logger.info("Received activation URL: \(url.absoluteString)", subsystem: .settings)

        guard !isOpenSourceBuild else { return }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Logger.error("Failed to parse URL components", subsystem: .settings)
            return
        }

        Logger.debug("URL scheme=\(components.scheme ?? "nil") host=\(components.host ?? "nil") path=\(components.path) query=\(components.queryItems?.description ?? "nil")", subsystem: .settings)

        // Try multiple parameter names Paddle might use
        let transactionID = components.queryItems?.first(where: {
            $0.name == "_ptxn" || $0.name == "ptxn" || $0.name == "transaction_id"
        })?.value

        guard components.host == "activate" || components.path == "/activate",
              let transactionID
        else {
            Logger.error("Missing activate host or transaction ID in URL", subsystem: .settings)
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let transaction = try await PaddleBillingAPI.verifyTransaction(
                    transactionID: transactionID
                )

                Logger.info("Transaction \(transactionID) status: \(transaction.status)", subsystem: .settings)

                guard transaction.status == "completed" || transaction.status == "paid" else {
                    throw PaddleBillingAPI.APIError.noCompletedTransaction
                }

                storeLicense(transactionID: transactionID, email: "")
                licenseStatus = .licensed
            } catch {
                Logger.error("Activation failed: \(error)", subsystem: .settings)
                errorMessage = "license.activate.failed".localized
            }

            isLoading = false
        }
    }

    // MARK: - Deactivation

    func deactivateLicense() {
        guard !isOpenSourceBuild else { return }
        clearStoredLicense()
        updateTrialStatus()
    }

    // MARK: - Verification

    func verifyLicense() {
        guard !isOpenSourceBuild else { return }
        guard hasValidStoredLicense() else { return }

        guard let transactionID = KeychainHelper.load(forKey: .transactionID) else { return }

        isLoading = true

        Task {
            do {
                let transaction = try await PaddleBillingAPI.verifyTransaction(
                    transactionID: transactionID
                )

                if transaction.status == "completed" {
                    KeychainHelper.saveDate(Date(), forKey: .lastVerificationDate)
                    licenseStatus = .licensed
                } else {
                    // Transaction refunded or cancelled — revoke license
                    clearStoredLicense()
                    updateTrialStatus()
                    errorMessage = "license.verify.failed".localized
                }
            } catch {
                // Network error — keep current license status (don't revoke on transient failures)
            }

            isLoading = false
        }
    }

    // MARK: - Trial Management (Private)

    private func updateTrialStatus() {
        guard let trialStart = KeychainHelper.loadDate(forKey: .trialStartDate) else {
            // First launch: start trial
            KeychainHelper.saveDate(Date(), forKey: .trialStartDate)
            licenseStatus = .trial(daysRemaining: Constants.License.trialDurationDays)
            return
        }

        let daysSinceStart = Calendar.current.dateComponents(
            [.day], from: trialStart, to: Date()
        ).day ?? 0

        let daysRemaining = Constants.License.trialDurationDays - daysSinceStart

        if daysRemaining > 0 {
            licenseStatus = .trial(daysRemaining: daysRemaining)
        } else {
            licenseStatus = .expired
        }
    }

    // MARK: - License Storage (Private)

    private func loadStoredLicenseState() {
        if hasValidStoredLicense() {
            licenseStatus = .licensed
            maybeReverify()
        } else {
            updateTrialStatus()
        }
    }

    private func hasValidStoredLicense() -> Bool {
        KeychainHelper.load(forKey: .transactionID) != nil
    }

    private func storeLicense(transactionID: String, email: String) {
        KeychainHelper.save(transactionID, forKey: .transactionID)
        KeychainHelper.save(email, forKey: .customerEmail)
        KeychainHelper.saveDate(Date(), forKey: .lastVerificationDate)
    }

    private func clearStoredLicense() {
        KeychainHelper.delete(forKey: .transactionID)
        KeychainHelper.delete(forKey: .customerEmail)
        KeychainHelper.delete(forKey: .lastVerificationDate)
    }

    /// Re-verify license if last verification was more than 7 days ago
    private func maybeReverify() {
        guard let lastVerified = KeychainHelper.loadDate(forKey: .lastVerificationDate) else {
            verifyLicense()
            return
        }

        let daysSinceVerification = Calendar.current.dateComponents(
            [.day], from: lastVerified, to: Date()
        ).day ?? 0

        if daysSinceVerification >= Constants.License.reverificationIntervalDays {
            verifyLicense()
        }
    }
}
