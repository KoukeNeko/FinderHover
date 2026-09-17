//
//  AppearanceSettingsView.swift
//  FinderHover
//
//  Appearance settings page
//

import SwiftUI

struct AppearanceSettingsView: SettingsPageView {
    @ObservedObject var settings: AppSettings

    func pageContent() -> some View {
        VStack(spacing: 16) {
            // Style Options Card
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    HStack(alignment: .center, spacing: SettingsRowLayout.tileSpacing) {
                        SettingsIconTile(icon: "paintbrush", tint: .purple)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.style".localized)
                                .font(.system(size: 13, weight: .semibold))
                            Text("settings.style.description".localized)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer()
                    Picker("settings.style".localized, selection: $settings.uiStyle) {
                        ForEach(UIStyle.allCases) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                }
                .padding(.horizontal, SettingsRowLayout.horizontalPadding)
                .padding(.vertical, SettingsRowLayout.verticalPadding)

                Divider().padding(.leading, SettingsRowLayout.dividerLeading)

                if #available(macOS 26, *) {
                    SettingRow(
                        title: "settings.appearance.liquidGlass".localized,
                        description: "settings.appearance.liquidGlass.hint".localized,
                        icon: "drop.fill",
                        tint: .cyan
                    ) {
                        Toggle("", isOn: $settings.enableLiquidGlass)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .onChange(of: settings.enableLiquidGlass) { _, newValue in
                                if newValue { settings.enableBlur = false }
                            }
                    }

                    Divider().padding(.leading, SettingsRowLayout.dividerLeading)
                }

                SettingRow(
                    title: "settings.appearance.blur".localized,
                    description: "settings.appearance.blur.hint".localized,
                    icon: "sparkles",
                    tint: .purple
                ) {
                    Toggle("", isOn: $settings.enableBlur)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .onChange(of: settings.enableBlur) { _, newValue in
                            if newValue, #available(macOS 26, *) {
                                settings.enableLiquidGlass = false
                            }
                        }
                }

                Divider().padding(.leading, SettingsRowLayout.dividerLeading)

                SettingRow(
                    title: "settings.appearance.compactMode".localized,
                    description: "settings.appearance.compactMode.hint".localized,
                    icon: "arrow.down.right.and.arrow.up.left",
                    tint: .gray
                ) {
                    Toggle("", isOn: $settings.compactMode)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(SettingsRowLayout.cardCornerRadius)
            .padding(.horizontal, SettingsRowLayout.horizontalPadding)

            // Window Dimensions Card
            VStack(alignment: .leading, spacing: 16) {
                // Opacity
                VStack(alignment: .leading, spacing: 12) {
                    Text("settings.appearance.opacity".localized)
                        .font(.system(size: 13, weight: .semibold))

                    Text("settings.appearance.opacity.description".localized)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Slider(value: $settings.windowOpacity, in: 0.7...1.0, step: 0.05)
                            .accessibilityLabel("settings.appearance.opacity".localized)
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
                            .accessibilityLabel("settings.appearance.maxWidth".localized)
                            .frame(maxWidth: .infinity)
                        Text("settings.appearance.maxWidth.pixels".localized(Int(settings.windowMaxWidth)))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(minWidth: 80, alignment: .trailing)
                            .fixedSize()
                    }
                }

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
                            .accessibilityLabel("settings.appearance.fontSize".localized)
                            .frame(maxWidth: .infinity)
                        Text("settings.appearance.fontSize.points".localized(settings.fontSize))
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
