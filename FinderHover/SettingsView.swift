//
//  SettingsView.swift
//  FinderHover
//
//  Settings window UI with sidebar navigation
//

import SwiftUI

enum SettingsPage: String, CaseIterable, Identifiable {
    case behavior = "Behavior"
    case appearance = "Appearance"
    case display = "Display"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .behavior: return "hand.point.up.left.fill"
        case .appearance: return "paintbrush.fill"
        case .display: return "list.bullet"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var selectedPage: SettingsPage = .behavior

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsPage.allCases, selection: $selectedPage) { page in
                NavigationLink(value: page) {
                    Label {
                        Text(page.rawValue)
                            .font(.system(size: 13))
                    } icon: {
                        Image(systemName: page.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                            .frame(width: 20)
                    }
                }
            }
            .navigationSplitViewColumnWidth(180)
            .listStyle(.sidebar)
        } detail: {
            // Detail view
            Group {
                switch selectedPage {
                case .behavior:
                    BehaviorSettingsView(settings: settings)
                case .appearance:
                    AppearanceSettingsView(settings: settings)
                case .display:
                    DisplaySettingsView(settings: settings)
                }
            }
            .frame(minWidth: 450, minHeight: 400)
        }
    }
}

// MARK: - Behavior Settings
struct BehaviorSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Behavior")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

                VStack(spacing: 24) {
                    // Hover Delay
                    SettingRow(
                        title: "Hover Delay",
                        description: "Time to wait before showing preview window"
                    ) {
                        HStack(spacing: 12) {
                            Slider(value: $settings.hoverDelay, in: 0.1...2.0, step: 0.1)
                                .frame(maxWidth: 200)
                            Text(String(format: "%.1fs", settings.hoverDelay))
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .trailing)
                        }
                    }

                    Divider()

                    // Auto-hide
                    SettingRow(
                        title: "Auto-hide",
                        description: "Immediately hide window when mouse moves away from file"
                    ) {
                        Toggle("", isOn: $settings.autoHideEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    Divider()

                    // Window Position
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Window Position")
                            .font(.system(size: 13, weight: .semibold))

                        Text("Distance from cursor to preview window")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Horizontal:")
                                    .frame(width: 80, alignment: .trailing)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Slider(value: $settings.windowOffsetX, in: 0...50, step: 5)
                                    .frame(maxWidth: 180)
                                Text("\(Int(settings.windowOffsetX))px")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            }

                            HStack {
                                Text("Vertical:")
                                    .frame(width: 80, alignment: .trailing)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Slider(value: $settings.windowOffsetY, in: 0...50, step: 5)
                                    .frame(maxWidth: 180)
                                Text("\(Int(settings.windowOffsetY))px")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)

                // Reset Button
                HStack {
                    Spacer()
                    Button("Reset to Defaults") {
                        withAnimation {
                            settings.resetToDefaults()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Appearance Settings
struct AppearanceSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Appearance")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

                VStack(spacing: 24) {
                    // Window Opacity
                    SettingRow(
                        title: "Window Opacity",
                        description: "Transparency level of the preview window"
                    ) {
                        HStack(spacing: 12) {
                            Slider(value: $settings.windowOpacity, in: 0.7...1.0, step: 0.05)
                                .frame(maxWidth: 200)
                            Text("\(Int(settings.windowOpacity * 100))%")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .trailing)
                        }
                    }

                    Divider()

                    // Maximum Width
                    SettingRow(
                        title: "Maximum Width",
                        description: "Maximum width of the preview window"
                    ) {
                        HStack(spacing: 12) {
                            Slider(value: $settings.windowMaxWidth, in: 300...600, step: 20)
                                .frame(maxWidth: 200)
                            Text("\(Int(settings.windowMaxWidth))px")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .trailing)
                        }
                    }

                    Divider()

                    // Font Size
                    SettingRow(
                        title: "Font Size",
                        description: "Size of text in the preview window"
                    ) {
                        HStack(spacing: 12) {
                            Slider(value: $settings.fontSize, in: 9...14, step: 1)
                                .frame(maxWidth: 200)
                            Text("\(Int(settings.fontSize))pt")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .trailing)
                        }
                    }

                    Divider()

                    // Blur Material
                    SettingRow(
                        title: "Blur Effect",
                        description: "Background blur style for the preview window"
                    ) {
                        Picker("", selection: $settings.blurMaterial) {
                            ForEach(BlurMaterial.allCases, id: \.self) { material in
                                Text(material.rawValue).tag(material)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 140)
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)

                // Reset Button
                HStack {
                    Spacer()
                    Button("Reset to Defaults") {
                        withAnimation {
                            settings.resetToDefaults()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Display Settings
struct DisplaySettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Display")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Show in Preview Window")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "File Icon", icon: "photo", isOn: $settings.showIcon)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "File Type", icon: "doc.text", isOn: $settings.showFileType)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "File Size", icon: "archivebox", isOn: $settings.showFileSize)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "Creation Date", icon: "calendar", isOn: $settings.showCreationDate)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "Modification Date", icon: "clock", isOn: $settings.showModificationDate)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "File Path", icon: "folder", isOn: $settings.showFilePath)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("At least one item must be enabled")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                Spacer(minLength: 40)

                // Reset Button
                HStack {
                    Spacer()
                    Button("Reset to Defaults") {
                        withAnimation {
                            settings.resetToDefaults()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Helper Views
struct SettingRow<Content: View>: View {
    let title: String
    let description: String
    let content: Content

    init(title: String, description: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.description = description
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                content
            }
        }
        .padding(.horizontal, 20)
    }
}

struct DisplayToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13))

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsView()
}
