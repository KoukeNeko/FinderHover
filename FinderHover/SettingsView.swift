//
//  SettingsView.swift
//  FinderHover
//
//  Settings window UI with sidebar navigation
//

import SwiftUI
import UniformTypeIdentifiers

enum SettingsPage: String, CaseIterable, Identifiable {
    case behavior
    case appearance
    case display
    case about

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .behavior: return "settings.tab.behavior".localized
        case .appearance: return "settings.tab.appearance".localized
        case .display: return "settings.tab.display".localized
        case .about: return "settings.tab.about".localized
        }
    }

    var icon: String {
        switch self {
        case .behavior: return "hand.point.up.left.fill"
        case .appearance: return "paintbrush.fill"
        case .display: return "list.bullet"
        case .about: return "info.circle.fill"
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
                        Text(page.localizedName)
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
                case .about:
                    AboutSettingsView()
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
                Text("settings.behavior.title".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

                VStack(spacing: 24) {
                    // Hover Delay
                    SettingRow(
                        title: "settings.behavior.hoverDelay".localized,
                        description: "settings.behavior.hoverDelay.description".localized
                    ) {
                        HStack(spacing: 12) {
                            Slider(value: $settings.hoverDelay, in: 0.1...2.0, step: 0.1)
                                .frame(maxWidth: 200)
                            Text("settings.behavior.hoverDelay.seconds".localized(settings.hoverDelay))
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .trailing)
                        }
                    }

                    Divider()

                    // Auto-hide
                    SettingRow(
                        title: "settings.behavior.autoHide".localized,
                        description: "settings.behavior.autoHide.description".localized
                    ) {
                        Toggle("", isOn: $settings.autoHideEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    Divider()

                    // Launch at Login
                    SettingRow(
                        title: "settings.behavior.launchAtLogin".localized,
                        description: "settings.behavior.launchAtLogin.description".localized
                    ) {
                        Toggle("", isOn: $settings.launchAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    Divider()

                    // Language Selection
                    SettingRow(
                        title: "settings.language".localized,
                        description: "settings.language.description".localized
                    ) {
                        Picker("", selection: $settings.preferredLanguage) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 200)
                    }

                    Divider()

                    // Window Position
                    VStack(alignment: .leading, spacing: 12) {
                        Text("settings.behavior.windowPosition".localized)
                            .font(.system(size: 13, weight: .semibold))

                        Text("settings.behavior.windowPosition.description".localized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            HStack {
                                Text("settings.behavior.horizontalOffset".localized)
                                    .frame(width: 80, alignment: .trailing)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Slider(value: $settings.windowOffsetX, in: 0...50, step: 5)
                                    .frame(maxWidth: 180)
                                Text("settings.behavior.pixels".localized(Int(settings.windowOffsetX)))
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            }

                            HStack {
                                Text("settings.behavior.verticalOffset".localized)
                                    .frame(width: 80, alignment: .trailing)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Slider(value: $settings.windowOffsetY, in: 0...50, step: 5)
                                    .frame(maxWidth: 180)
                                Text("settings.behavior.pixels".localized(Int(settings.windowOffsetY)))
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
                    Button("common.reset".localized) {
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
                Text("settings.appearance.title".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

                VStack(spacing: 24) {
                    // Window Opacity
                    VStack(alignment: .leading, spacing: 8) {
                        SettingRow(
                            title: "settings.appearance.opacity".localized,
                            description: "settings.appearance.opacity.description".localized
                        ) {
                            HStack(spacing: 12) {
                                Slider(value: $settings.windowOpacity, in: 0.7...1.0, step: 0.05)
                                    .frame(maxWidth: 200)
                                    .disabled(settings.enableBlur)
                                Text("settings.appearance.opacity.percent".localized(Int(settings.windowOpacity * 100)))
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 45, alignment: .trailing)
                            }
                        }

                        if settings.enableBlur {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 11))
                                Text("settings.appearance.opacity.hint".localized)
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                        }
                    }

                    Divider()

                    // Maximum Width
                    SettingRow(
                        title: "settings.appearance.maxWidth".localized,
                        description: "settings.appearance.maxWidth.description".localized
                    ) {
                        HStack(spacing: 12) {
                            Slider(value: $settings.windowMaxWidth, in: 300...600, step: 20)
                                .frame(maxWidth: 200)
                            Text("settings.appearance.maxWidth.pixels".localized(Int(settings.windowMaxWidth)))
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .trailing)
                        }
                    }

                    Divider()

                    // Font Size
                    SettingRow(
                        title: "settings.appearance.fontSize".localized,
                        description: "settings.appearance.fontSize.description".localized
                    ) {
                        HStack(spacing: 12) {
                            Slider(value: $settings.fontSize, in: 9...14, step: 1)
                                .frame(maxWidth: 200)
                            Text("settings.appearance.fontSize.points".localized(settings.fontSize))
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .trailing)
                        }
                    }

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

                Spacer(minLength: 40)

                // Reset Button
                HStack {
                    Spacer()
                    Button("common.reset".localized) {
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
    @State private var draggingItem: DisplayItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("settings.display.title".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 16) {
                    Text("settings.display.basicInfo".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "settings.display.showIcon".localized, icon: "photo", isOn: $settings.showIcon)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showFileType".localized, icon: "doc.text", isOn: $settings.showFileType)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showFileSize".localized, icon: "archivebox", isOn: $settings.showFileSize)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showItemCount".localized, icon: "number", isOn: $settings.showItemCount)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showCreationDate".localized, icon: "calendar", isOn: $settings.showCreationDate)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showModificationDate".localized, icon: "clock", isOn: $settings.showModificationDate)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showLastAccessDate".localized, icon: "eye", isOn: $settings.showLastAccessDate)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showPermissions".localized, icon: "lock.shield", isOn: $settings.showPermissions)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showOwner".localized, icon: "person", isOn: $settings.showOwner)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showFilePath".localized, icon: "folder", isOn: $settings.showFilePath)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    // EXIF Section
                    Text("settings.display.exif".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "settings.display.exif.show".localized, icon: "camera.fill", isOn: $settings.showEXIF)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.exif.camera".localized, icon: "camera", isOn: $settings.showEXIFCamera)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.exif.lens".localized, icon: "camera.aperture", isOn: $settings.showEXIFLens)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.exif.settings".localized, icon: "slider.horizontal.3", isOn: $settings.showEXIFSettings)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.exif.dateTaken".localized, icon: "calendar.badge.clock", isOn: $settings.showEXIFDateTaken)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.exif.dimensions".localized, icon: "square.resize", isOn: $settings.showEXIFDimensions)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.exif.gps".localized, icon: "location.fill", isOn: $settings.showEXIFGPS)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.exif.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Display Order Section
                    Text("settings.display.order".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    VStack(spacing: 0) {
                        ForEach(settings.displayOrder) { item in
                            HStack(spacing: 12) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)

                                Image(systemName: item.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 20)

                                Text(item.localizedName)
                                    .font(.system(size: 13))

                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                            .background(Color(NSColor.controlBackgroundColor))
                            .opacity(draggingItem == item ? 0.5 : 1.0)
                            .onDrag {
                                self.draggingItem = item
                                return NSItemProvider(object: item.rawValue as NSString)
                            }
                            .onDrop(of: [.text], delegate: DisplayItemDropDelegate(
                                item: item,
                                items: $settings.displayOrder,
                                draggingItem: $draggingItem
                            ))

                            if item != settings.displayOrder.last {
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.order.hint".localized)
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
                    Button("common.reset".localized) {
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

// MARK: - About Settings
struct AboutSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("settings.tab.about".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

                VStack(alignment: .center, spacing: 24) {
                    // App Icon
                    Image(systemName: "eye.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)
                        .padding(.top, 20)

                    // App Name and Version
                    VStack(spacing: 8) {
                        Text("FinderHover")
                            .font(.system(size: 24, weight: .bold))
                        Text("settings.about.version".localized("1.1"))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    // Description
                    Text("settings.about.description".localized)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Divider()
                        .padding(.vertical, 8)

                    // Usage Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("settings.about.usage".localized)
                            .font(.system(size: 13, weight: .semibold))

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("1.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("settings.about.usage.step1".localized)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            HStack(alignment: .top, spacing: 8) {
                                Text("2.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("settings.about.usage.step2".localized)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            HStack(alignment: .top, spacing: 8) {
                                Text("3.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("settings.about.usage.step3".localized)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: 360)

                    Divider()
                        .padding(.vertical, 8)

                    // Credits
                    VStack(spacing: 8) {
                        Text("settings.about.copyright".localized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("settings.about.opensource".localized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - About Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.accentColor)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
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

// MARK: - Drag and Drop Delegate
struct DisplayItemDropDelegate: DropDelegate {
    let item: DisplayItem
    @Binding var items: [DisplayItem]
    @Binding var draggingItem: DisplayItem?

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggingItem = draggingItem,
              draggingItem != item,
              let fromIndex = items.firstIndex(of: draggingItem),
              let toIndex = items.firstIndex(of: item) else { return }

        if items[toIndex] != draggingItem {
            withAnimation(.default) {
                items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }

            // Manually save to UserDefaults since move() doesn't trigger didSet
            if let encoded = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(encoded, forKey: "displayOrder")
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

#Preview {
    SettingsView()
}
