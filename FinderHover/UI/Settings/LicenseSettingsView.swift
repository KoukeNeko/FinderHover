//
//  LicenseSettingsView.swift
//  FinderHover
//
//  License management and purchase UI
//

import SwiftUI
import StoreKit

struct LicenseSettingsView: View {
    @ObservedObject private var trialManager = TrialManager.shared
    @ObservedObject private var storeService = StoreKitService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SettingsPageHeader(
                    icon: "checkmark.seal",
                    title: "settings.tab.license".localized,
                    description: "settings.page.description.license".localized
                )

                VStack(spacing: 16) {
                    // License Status Card
                    statusCard

                    // Purchase Section
                    if case .purchased = trialManager.licenseStatus {
                        // Already purchased — no action needed
                    } else {
                        purchaseSection
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Status Card

    @ViewBuilder
    private var statusCard: some View {
        VStack(spacing: 12) {
            switch trialManager.licenseStatus {
            case .trial(let daysRemaining):
                HStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("license.status.trial".localized)
                            .font(.system(size: 15, weight: .semibold))
                        Text(String(format: "license.status.trial.daysRemaining".localized, daysRemaining))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

            case .expired:
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 28))
                        .foregroundColor(.red)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("license.status.expired".localized)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.red)
                        Text("license.status.expired.description".localized)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

            case .purchased:
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("license.status.purchased".localized)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.green)
                        Text("license.status.purchased.description".localized)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - Purchase Section

    @ViewBuilder
    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if let product = storeService.unlockProduct {
                Button(action: {
                    Task {
                        await storeService.purchase(product)
                    }
                }) {
                    HStack {
                        Spacer()
                        if storeService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "cart")
                            Text(String(format: "license.purchase.button".localized, product.displayPrice))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(storeService.isLoading)
            } else if storeService.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            } else {
                Text("license.purchase.unavailable".localized)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }

            // Error message
            if let error = storeService.purchaseError {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }

            // Restore purchases
            Button(action: {
                Task {
                    await storeService.restorePurchases()
                }
            }) {
                Text("license.restore".localized)
                    .font(.system(size: 12))
            }
            .buttonStyle(.link)
            .disabled(storeService.isLoading)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}
