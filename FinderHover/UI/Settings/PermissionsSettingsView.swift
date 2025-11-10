//
//  PermissionsSettingsView.swift
//  FinderHover
//
//  Permissions settings page
//

import SwiftUI

struct PermissionsSettingsView: View {
    @State private var accessibilityEnabled = AXIsProcessTrusted()
    @State private var refreshTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("settings.permissions.title".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

                VStack(spacing: 24) {
                    // Accessibility Permission
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "hand.point.up.left.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(accessibilityEnabled ? .green : .orange)

                                    Text("settings.permissions.accessibility".localized)
                                        .font(.system(size: 14, weight: .semibold))
                                }

                                Text("settings.permissions.accessibility.description".localized)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: accessibilityEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(accessibilityEnabled ? .green : .red)

                                    Text(accessibilityEnabled ? "settings.permissions.granted".localized : "settings.permissions.notGranted".localized)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(accessibilityEnabled ? .green : .red)
                                }

                                if !accessibilityEnabled {
                                    Button("settings.permissions.openSystemSettings".localized) {
                                        openAccessibilitySettings()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                            }
                        }

                        // Additional info box
                        if !accessibilityEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                    Text("settings.permissions.accessibility.required".localized)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.primary)
                                }

                                Text("settings.permissions.accessibility.steps".localized)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.leading, 18)
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)

                    Divider()
                        .padding(.horizontal, 20)

                    // Why These Permissions Are Needed
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.accentColor)

                            Text("settings.permissions.whyNeeded".localized)
                                .font(.system(size: 14, weight: .semibold))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            PermissionReasonRow(
                                icon: "cursorarrow.rays",
                                title: "settings.permissions.reason.mouseTracking".localized,
                                description: "settings.permissions.reason.mouseTracking.description".localized
                            )

                            PermissionReasonRow(
                                icon: "doc.text.magnifyingglass",
                                title: "settings.permissions.reason.fileDetection".localized,
                                description: "settings.permissions.reason.fileDetection.description".localized
                            )

                            PermissionReasonRow(
                                icon: "hand.raised.fill",
                                title: "settings.permissions.reason.noInvasion".localized,
                                description: "settings.permissions.reason.noInvasion.description".localized
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    Divider()
                        .padding(.horizontal, 20)

                    // Privacy Notice
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)

                            Text("settings.permissions.privacy".localized)
                                .font(.system(size: 14, weight: .semibold))
                        }

                        Text("settings.permissions.privacy.description".localized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            accessibilityEnabled = AXIsProcessTrusted()
        }
    }

    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Permission Reason Row
struct PermissionReasonRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
