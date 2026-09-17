//
//  BehaviorSettingsView.swift
//  FinderHover
//
//  Behavior settings page
//

import SwiftUI

struct BehaviorSettingsView: SettingsPageView {
    @ObservedObject var settings: AppSettings

    func pageContent() -> some View {
        VStack(spacing: 16) {
            // General Behavior Card
            VStack(spacing: 0) {
                SettingRow(
                    title: "settings.behavior.autoHide".localized,
                    description: "settings.behavior.autoHide.description".localized,
                    icon: "eye.slash",
                    tint: .blue
                ) {
                    Toggle("", isOn: $settings.autoHideEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                Divider().padding(.leading, SettingsRowLayout.dividerLeading)

                SettingRow(
                    title: "settings.behavior.largeFileProtection".localized,
                    description: "settings.behavior.largeFileProtection.description".localized,
                    icon: "externaldrive.badge.exclamationmark",
                    tint: .orange
                ) {
                    Toggle("", isOn: $settings.enableLargeFileProtection)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                Divider().padding(.leading, SettingsRowLayout.dividerLeading)

                SettingRow(
                    title: "settings.behavior.launchAtLogin".localized,
                    description: "settings.behavior.launchAtLogin.description".localized,
                    icon: "power",
                    tint: .green
                ) {
                    Toggle("", isOn: $settings.launchAtLogin)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(SettingsRowLayout.cardCornerRadius)
            .padding(.horizontal, SettingsRowLayout.horizontalPadding)

            // Hover Delay
            VStack(alignment: .leading, spacing: 8) {
                SettingsSectionLabel(titleKey: "settings.behavior.hoverDelay")

                VStack(alignment: .leading, spacing: 12) {
                    Text("settings.behavior.hoverDelay.description".localized)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Slider(value: $settings.hoverDelay, in: 0.1...2.0, step: 0.1)
                            .accessibilityLabel("settings.behavior.hoverDelay".localized)
                            .frame(maxWidth: .infinity)
                        Text("settings.behavior.hoverDelay.seconds".localized(settings.hoverDelay))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(minWidth: 80, alignment: .trailing)
                            .fixedSize()
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(SettingsRowLayout.cardCornerRadius)
                .padding(.horizontal, SettingsRowLayout.horizontalPadding)
            }

            // Language
            VStack(alignment: .leading, spacing: 8) {
                SettingsSectionLabel(titleKey: "settings.language")

                HStack(alignment: .center) {
                    Text("settings.language.description".localized)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    HStack(spacing: 8) {
                        Picker("settings.language".localized, selection: $settings.preferredLanguage) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .labelsHidden()
                        .fixedSize()

                        Button("settings.language.restart".localized) {
                            AppRelauncher.relaunch()
                        }
                        .disabled(!settings.languageRestartRequired)
                        .buttonStyle(.bordered)
                        .fixedSize()
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(SettingsRowLayout.cardCornerRadius)
                .padding(.horizontal, SettingsRowLayout.horizontalPadding)
            }

            // Window Position
            VStack(alignment: .leading, spacing: 8) {
                SettingsSectionLabel(titleKey: "settings.behavior.windowPosition")

                VStack(alignment: .leading, spacing: 12) {
                    Text("settings.behavior.windowPosition.description".localized)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Text("settings.behavior.horizontalOffset".localized)
                            .frame(width: 90, alignment: .leading)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Slider(value: $settings.windowOffsetX, in: 0...50, step: 5)
                            .accessibilityLabel("settings.behavior.horizontalOffset".localized)
                            .frame(maxWidth: .infinity)
                        Text("settings.behavior.pixels".localized(Int(settings.windowOffsetX)))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(minWidth: 80, alignment: .trailing)
                            .fixedSize()
                    }

                    HStack(spacing: 12) {
                        Text("settings.behavior.verticalOffset".localized)
                            .frame(width: 90, alignment: .leading)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Slider(value: $settings.windowOffsetY, in: 0...50, step: 5)
                            .accessibilityLabel("settings.behavior.verticalOffset".localized)
                            .frame(maxWidth: .infinity)
                        Text("settings.behavior.pixels".localized(Int(settings.windowOffsetY)))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(minWidth: 80, alignment: .trailing)
                            .fixedSize()
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(SettingsRowLayout.cardCornerRadius)
                .padding(.horizontal, SettingsRowLayout.horizontalPadding)
            }
        }
    }
}
