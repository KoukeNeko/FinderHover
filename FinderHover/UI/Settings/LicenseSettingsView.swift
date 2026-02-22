//
//  LicenseSettingsView.swift
//  FinderHover
//
//  License management and purchase UI
//

import SwiftUI

struct LicenseSettingsView: View {
    @ObservedObject private var paddleService = PaddleService.shared
    @State private var email = ""
    @State private var transactionID = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SettingsPageHeader(
                    icon: "checkmark.seal",
                    title: "settings.tab.license".localized,
                    description: "settings.page.description.license".localized
                )

                VStack(spacing: 16) {
                    statusCard

                    if case .licensed = paddleService.licenseStatus {
                        deactivateSection
                    } else {
                        purchaseSection
                        activateSection
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
            switch paddleService.licenseStatus {
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

            case .licensed:
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("license.status.licensed".localized)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.green)
                        Text("license.status.licensed.description".localized)
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
            Button(action: { paddleService.startPurchase() }) {
                HStack {
                    Spacer()
                    if paddleService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "safari")
                        Text("license.purchase.button".localized)
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(paddleService.isLoading)

            Text("license.purchase.hint".localized)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            if let error = paddleService.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - Email Activation

    @ViewBuilder
    private var activateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("license.activate.title".localized)
                .font(.system(size: 13, weight: .semibold))

            TextField("license.activate.email.placeholder".localized, text: $email)
                .textFieldStyle(.roundedBorder)

            TextField("license.activate.transactionID.placeholder".localized, text: $transactionID)
                .textFieldStyle(.roundedBorder)

            Button(action: {
                paddleService.activateLicense(email: email, code: transactionID)
            }) {
                Text("license.activate.button".localized)
            }
            .disabled(email.isEmpty || transactionID.isEmpty || paddleService.isLoading)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - Deactivate Section

    @ViewBuilder
    private var deactivateSection: some View {
        VStack(spacing: 12) {
            Button(action: { paddleService.deactivateLicense() }) {
                Text("license.deactivate.button".localized)
                    .font(.system(size: 12))
            }
            .buttonStyle(.link)
            .disabled(paddleService.isLoading)

            Text("license.deactivate.description".localized)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}
