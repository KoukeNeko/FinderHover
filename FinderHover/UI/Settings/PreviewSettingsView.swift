//
//  PreviewSettingsView.swift
//  FinderHover
//
//  Preview settings page for Quick Look extension
//

import SwiftUI

struct PreviewSettingsView: SettingsPageView {
    @ObservedObject var settings: AppSettings

    var pageTitle: String {
        "settings.preview.title".localized
    }

    func pageContent() -> some View {
        VStack(spacing: 24) {
            // Quick Look Extension Status
            VStack(alignment: .leading, spacing: 12) {
                Text("settings.preview.quickLook".localized)
                    .font(.system(size: 13, weight: .semibold))

                Text("settings.preview.quickLook.description".localized)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("settings.preview.quickLook.supported".localized)
                            .font(.system(size: 12, weight: .medium))

                        Text("settings.preview.quickLook.formats".localized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("settings.preview.quickLook.refresh".localized) {
                        refreshQuickLook()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding(.horizontal, 20)

            Divider()

            // SQLite Preview Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("settings.preview.sqlite".localized)
                    .font(.system(size: 13, weight: .semibold))

                SettingRow(
                    title: "settings.preview.sqlite.maxRows".localized,
                    description: "settings.preview.sqlite.maxRows.description".localized
                ) {
                    Picker("", selection: $settings.previewSQLiteMaxRows) {
                        Text("50").tag(50)
                        Text("100").tag(100)
                        Text("200").tag(200)
                        Text("500").tag(500)
                    }
                    .labelsHidden()
                    .fixedSize()
                }
            }
            .padding(.horizontal, 20)

            Divider()

            // SQL Syntax Highlighting
            VStack(alignment: .leading, spacing: 12) {
                Text("settings.preview.sql".localized)
                    .font(.system(size: 13, weight: .semibold))

                SettingRow(
                    title: "settings.preview.sql.syntaxHighlight".localized,
                    description: "settings.preview.sql.syntaxHighlight.description".localized
                ) {
                    Toggle("", isOn: $settings.previewSQLSyntaxHighlight)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                SettingRow(
                    title: "settings.preview.sql.lineNumbers".localized,
                    description: "settings.preview.sql.lineNumbers.description".localized
                ) {
                    Toggle("", isOn: $settings.previewSQLLineNumbers)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
            .padding(.horizontal, 20)

            Divider()

            // Default View Mode
            VStack(alignment: .leading, spacing: 12) {
                Text("settings.preview.defaultView".localized)
                    .font(.system(size: 13, weight: .semibold))

                Text("settings.preview.defaultView.description".localized)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Picker("", selection: $settings.previewDefaultViewMode) {
                    Text("settings.preview.viewMode.schema".localized).tag("schema")
                    Text("settings.preview.viewMode.data".localized).tag("data")
                    Text("settings.preview.viewMode.source".localized).tag("source")
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
    }

    private func refreshQuickLook() {
        // Reset Quick Look daemon
        let task = Process()
        task.launchPath = "/usr/bin/qlmanage"
        task.arguments = ["-r"]
        try? task.run()
    }

    func resetAction() {
        settings.resetPreviewSettings()
    }
}
