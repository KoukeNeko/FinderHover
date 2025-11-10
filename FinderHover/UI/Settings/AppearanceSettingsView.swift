//
//  AppearanceSettingsView.swift
//  FinderHover
//
//  Appearance settings page
//

import SwiftUI

struct AppearanceSettingsView: SettingsPageView {
    @ObservedObject var settings: AppSettings

    var pageTitle: String {
        "settings.appearance.title".localized
    }

    func pageContent() -> some View {
        VStack(spacing: 24) {
            // UI Style Selection
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("settings.style".localized)
                            .font(.system(size: 13, weight: .semibold))
                        Text("settings.style.description".localized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Picker("", selection: $settings.uiStyle) {
                        ForEach(UIStyle.allCases) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                }
            }
            .padding(.horizontal, 20)

            Divider()

            // Window Opacity
            VStack(alignment: .leading, spacing: 12) {
                Text("settings.appearance.opacity".localized)
                    .font(.system(size: 13, weight: .semibold))

                Text("settings.appearance.opacity.description".localized)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Slider(value: $settings.windowOpacity, in: 0.7...1.0, step: 0.05)
                        .frame(maxWidth: .infinity)
                        .disabled(settings.enableBlur)
                    Text("settings.appearance.opacity.percent".localized(Int(settings.windowOpacity * 100)))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(minWidth: 80, alignment: .trailing)
                        .fixedSize()
                }

                if settings.enableBlur {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.appearance.opacity.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)

            Divider()

            // Maximum Width
            VStack(alignment: .leading, spacing: 12) {
                Text("settings.appearance.maxWidth".localized)
                    .font(.system(size: 13, weight: .semibold))

                Text("settings.appearance.maxWidth.description".localized)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Slider(value: $settings.windowMaxWidth, in: 300...600, step: 20)
                        .frame(maxWidth: .infinity)
                    Text("settings.appearance.maxWidth.pixels".localized(Int(settings.windowMaxWidth)))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(minWidth: 80, alignment: .trailing)
                        .fixedSize()
                }
            }
            .padding(.horizontal, 20)

            Divider()

            // Font Size
            VStack(alignment: .leading, spacing: 12) {
                Text("settings.appearance.fontSize".localized)
                    .font(.system(size: 13, weight: .semibold))

                Text("settings.appearance.fontSize.description".localized)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Slider(value: $settings.fontSize, in: 9...14, step: 1)
                        .frame(maxWidth: .infinity)
                    Text("settings.appearance.fontSize.points".localized(settings.fontSize))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(minWidth: 80, alignment: .trailing)
                        .fixedSize()
                }
            }
            .padding(.horizontal, 20)

            Divider()

            // Blur Effect
            SettingRow(
                title: "settings.appearance.blur".localized,
                description: "settings.appearance.blur.hint".localized
            ) {
                Toggle("", isOn: $settings.enableBlur)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            Divider()

            // Compact Mode
            SettingRow(
                title: "settings.appearance.compactMode".localized,
                description: "settings.appearance.compactMode.hint".localized
            ) {
                Toggle("", isOn: $settings.compactMode)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
        }
        .padding(.horizontal, 20)
    }
}
