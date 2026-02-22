//
//  PaddleService.swift
//  FinderHover
//
//  Paddle SDK integration for license management and purchase.
//  Uses conditional compilation so the project builds without the framework
//  (open-source builds unlock all features by default).
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

#if canImport(Paddle)
import Paddle

@MainActor
class PaddleService: NSObject, ObservableObject, PaddleDelegate, PADProductDelegate {
    static let shared = PaddleService()

    @Published private(set) var licenseStatus: LicenseStatus = .expired
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    var isFeatureUnlocked: Bool {
        switch licenseStatus {
        case .trial, .licensed: return true
        case .expired: return false
        }
    }

    private var paddle: Paddle?
    private var product: PADProduct?

    private override init() {
        super.init()
        configurePaddle()
    }

    // MARK: - SDK Setup

    private func configurePaddle() {
        let config = PADProductConfiguration()
        config.productName = "FinderHover"
        config.vendorName = "koukeneko"
        config.trialType = .timeLimited
        config.trialLength = 30
        config.currency = "USD"

        #if DEBUG
        Paddle.setEnvironmentToSandbox()
        #endif

        paddle = Paddle.sharedInstance(
            withVendorID: PaddleSecrets.vendorID,
            apiKey: PaddleSecrets.apiKey,
            productID: PaddleSecrets.productID,
            configuration: config,
            delegate: self
        )

        product = PADProduct(
            productID: PaddleSecrets.productID,
            productType: .sdkProduct,
            configuration: config
        )
        product?.delegate = self

        refreshStatus()
    }

    // MARK: - Status

    func refreshStatus() {
        guard let product else { return }

        if product.activated {
            licenseStatus = .licensed
            return
        }

        if let daysRemaining = product.trialDaysRemaining?.intValue, daysRemaining > 0 {
            licenseStatus = .trial(daysRemaining: daysRemaining)
        } else {
            licenseStatus = .expired
        }
    }

    // MARK: - Purchase

    func startPurchase(window: NSWindow? = nil) {
        guard let product, let paddle else { return }
        isLoading = true
        errorMessage = nil

        let displayConfig = PADDisplayConfiguration(
            displayType: .window,
            hideNavigationButtons: true,
            parentWindow: window
        )

        paddle.showCheckout(
            for: product,
            options: nil,
            displayConfiguration: displayConfig
        ) { [weak self] state, _ in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch state {
                case .purchased:
                    self?.licenseStatus = .licensed
                case .failed:
                    self?.errorMessage = "license.purchase.failed".localized
                case .abandoned, .flagged, .slowOrderProcessing:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    // MARK: - License Activation

    func activateLicense(email: String, code: String) {
        guard let product else { return }
        isLoading = true
        errorMessage = nil

        product.activateEmail(email, license: code) { [weak self] activated, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if activated {
                    self?.licenseStatus = .licensed
                } else {
                    self?.errorMessage = error?.localizedDescription
                        ?? "license.activate.failed".localized
                }
            }
        }
    }

    // MARK: - Deactivation

    func deactivateLicense() {
        guard let product else { return }
        isLoading = true
        errorMessage = nil

        product.deactivate { [weak self] deactivated, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if deactivated {
                    self?.refreshStatus()
                } else {
                    self?.errorMessage = error?.localizedDescription
                        ?? "license.deactivate.failed".localized
                }
            }
        }
    }

    // MARK: - Verification

    func verifyLicense() {
        guard let product, product.activated else { return }
        isLoading = true

        product.verifyActivation { [weak self] state, _ in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch state {
                case .verified:
                    self?.licenseStatus = .licensed
                case .unverified:
                    self?.licenseStatus = .expired
                    self?.errorMessage = "license.verify.failed".localized
                case .unableToVerify, .noActivation:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    // MARK: - PaddleDelegate

    nonisolated func canAutoActivate(_ product: PADProduct) -> Bool {
        true
    }

    // MARK: - PADProductDelegate

    nonisolated func productActivated() {
        Task { @MainActor in
            self.refreshStatus()
        }
    }

    nonisolated func productDeactivated() {
        Task { @MainActor in
            self.refreshStatus()
        }
    }
}

#else

// MARK: - Stub (no Paddle SDK — open-source build, all features unlocked)

@MainActor
class PaddleService: ObservableObject {
    static let shared = PaddleService()

    @Published private(set) var licenseStatus: LicenseStatus = .licensed
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    var isFeatureUnlocked: Bool { true }

    private init() {}

    func refreshStatus() {}
    func startPurchase(window: NSWindow? = nil) {}
    func activateLicense(email: String, code: String) {}
    func deactivateLicense() {}
    func verifyLicense() {}
}

#endif
