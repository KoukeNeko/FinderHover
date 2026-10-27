//
//  PermissionsSettingsView.swift
//  FinderHover
//
//  Permissions settings page
//

import SwiftUI

struct PermissionsSettingsView: View {
    @State private var accessibilityEnabled = AXIsProcessTrusted()

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                status
                VStack(alignment: .leading, spacing: 0) {
                    PermissionReasonRow(icon: "cursorarrow.rays",
                                        title: "settings.permissions.reason.mouseTracking".localized,
                                        description: "settings.permissions.reason.mouseTracking.description".localized)
                    Divider()
                    PermissionReasonRow(icon: "doc.text.magnifyingglass",
                                        title: "settings.permissions.reason.fileDetection".localized,
                                        description: "settings.permissions.reason.fileDetection.description".localized)
                    Divider()
                    PermissionReasonRow(icon: "hand.raised",
                                        title: "settings.permissions.reason.noInvasion".localized,
                                        description: "settings.permissions.reason.noInvasion.description".localized)
                }
            }
            .frame(width: 520)
            .padding(.top, 48)
            .frame(maxWidth: .infinity)
        }
        .task {
            // Use async task which automatically cancels when view disappears
            while !Task.isCancelled {
                accessibilityEnabled = AXIsProcessTrusted()
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }

    private var status: some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: "accessibility")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(accessibilityEnabled ? Color.green : Color.orange, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("settings.permissions.accessibility".localized)
                        .font(.system(size: 17, weight: .bold))
                    Text(accessibilityEnabled ? "settings.permissions.granted".localized : "settings.permissions.notGranted".localized)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accessibilityEnabled ? Color.green : Color.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background((accessibilityEnabled ? Color.green : Color.orange).opacity(0.15), in: Capsule())
                }
                Text("settings.permissions.accessibility.description".localized)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !accessibilityEnabled {
                    Text("settings.permissions.accessibility.steps".localized)
                        .font(.system(size: 13))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                }
                Button("settings.permissions.openSystemSettings".localized) { openAccessibilitySettings() }
                    .buttonStyle(.borderedProminent)
                    .tint(accessibilityEnabled ? .secondary : .accentColor)
                    .padding(.top, 8)
            }
            Spacer(minLength: 0)
        }
        .padding(22)
        .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(NSColor.separatorColor)))
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
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
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }
}
