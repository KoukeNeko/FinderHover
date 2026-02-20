//
//  BehaviorSettingsView.swift
//  FinderHover
//
//  Behavior settings page
//

import SwiftUI

struct BehaviorSettingsView: SettingsPageView {
    @ObservedObject var settings: AppSettings
    @State private var initialLanguage: AppLanguage? = nil

    var pageTitle: String { "settings.behavior.title".localized }
    var pageIcon: String { "hand.point.up.left" }
    var pageDescription: String { "settings.page.description.behavior".localized }

    func pageContent() -> some View {
        VStack(spacing: 16) {
            // General Behavior Card
            VStack(spacing: 0) {
                SettingRow(
                    title: "settings.behavior.autoHide".localized,
                    description: "settings.behavior.autoHide.description".localized
                ) {
                    Toggle("", isOn: $settings.autoHideEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                Divider().padding(.leading, 20)

                SettingRow(
                    title: "settings.behavior.largeFileProtection".localized,
                    description: "settings.behavior.largeFileProtection.description".localized
                ) {
                    Toggle("", isOn: $settings.enableLargeFileProtection)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                Divider().padding(.leading, 20)

                SettingRow(
                    title: "settings.behavior.launchAtLogin".localized,
                    description: "settings.behavior.launchAtLogin.description".localized
                ) {
                    Toggle("", isOn: $settings.launchAtLogin)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .padding(.horizontal, 20)

            // Hover Delay Card
            VStack(alignment: .leading, spacing: 12) {
                Text("settings.behavior.hoverDelay".localized)
                    .font(.system(size: 13, weight: .semibold))

                Text("settings.behavior.hoverDelay.description".localized)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Slider(value: $settings.hoverDelay, in: 0.1...2.0, step: 0.1)
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
            .cornerRadius(10)
            .padding(.horizontal, 20)

            // Language Card
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("settings.language".localized)
                        .font(.system(size: 13, weight: .semibold))
                    Text("settings.language.description".localized)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                HStack(spacing: 8) {
                    Picker("", selection: $settings.preferredLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()

                    Button("settings.language.restart".localized) {
                        NSApplication.shared.terminate(nil)
                    }
                    .disabled(settings.preferredLanguage == initialLanguage)
                    .buttonStyle(.bordered)
                    .fixedSize()
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .onAppear {
                if initialLanguage == nil {
                    initialLanguage = settings.preferredLanguage
                }
            }

            // Window Position Card
            VStack(alignment: .leading, spacing: 12) {
                Text("settings.behavior.windowPosition".localized)
                    .font(.system(size: 13, weight: .semibold))

                Text("settings.behavior.windowPosition.description".localized)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Text("settings.behavior.horizontalOffset".localized)
                            .frame(width: 90, alignment: .leading)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Slider(value: $settings.windowOffsetX, in: 0...50, step: 5)
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
                            .frame(maxWidth: .infinity)
                        Text("settings.behavior.pixels".localized(Int(settings.windowOffsetY)))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(minWidth: 80, alignment: .trailing)
                            .fixedSize()
                    }
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .padding(.horizontal, 20)
        }
    }
}
