//
//  SettingsView.swift
//  FinderHover
//
//  Settings window UI with sidebar navigation
//

import SwiftUI
import UniformTypeIdentifiers

enum SettingsPage: String, CaseIterable, Identifiable {
    case behavior = "Behavior"
    case appearance = "Appearance"
    case display = "Display"
    case about = "About"

    var id: String { rawValue }

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

                    // Launch at Login
                    SettingRow(
                        title: "Launch at Login",
                        description: "Automatically start FinderHover when you log in"
                    ) {
                        Toggle("", isOn: $settings.launchAtLogin)
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
                    VStack(alignment: .leading, spacing: 8) {
                        SettingRow(
                            title: "Window Opacity",
                            description: "Transparency level of the preview window"
                        ) {
                            HStack(spacing: 12) {
                                Slider(value: $settings.windowOpacity, in: 0.7...1.0, step: 0.05)
                                    .frame(maxWidth: 200)
                                    .disabled(settings.enableBlur)
                                Text("\(Int(settings.windowOpacity * 100))%")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 45, alignment: .trailing)
                            }
                        }

                        if settings.enableBlur {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 11))
                                Text("Only available when Blur Effect is disabled")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
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

                    // Blur Effect
                    SettingRow(
                        title: "Blur Effect",
                        description: "Enable background blur for the preview window"
                    ) {
                        Toggle("", isOn: $settings.enableBlur)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    Divider()

                    // Compact Mode
                    SettingRow(
                        title: "Compact Mode",
                        description: "Reduce spacing and padding for a more compact layout"
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
                        DisplayToggleRow(title: "Item Count (folders)", icon: "number", isOn: $settings.showItemCount)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "Creation Date", icon: "calendar", isOn: $settings.showCreationDate)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "Modification Date", icon: "clock", isOn: $settings.showModificationDate)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "Last Access Date", icon: "eye", isOn: $settings.showLastAccessDate)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "Permissions", icon: "lock.shield", isOn: $settings.showPermissions)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "Owner", icon: "person", isOn: $settings.showOwner)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "File Path", icon: "folder", isOn: $settings.showFilePath)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    // EXIF Section
                    Text("Photo Information (EXIF)")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "Show EXIF Data", icon: "camera.fill", isOn: $settings.showEXIF)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "Camera Model", icon: "camera", isOn: $settings.showEXIFCamera)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "Lens Model", icon: "camera.aperture", isOn: $settings.showEXIFLens)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "Camera Settings", icon: "slider.horizontal.3", isOn: $settings.showEXIFSettings)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "Date Taken", icon: "calendar.badge.clock", isOn: $settings.showEXIFDateTaken)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "Image Dimensions", icon: "square.resize", isOn: $settings.showEXIFDimensions)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "GPS Location", icon: "location.fill", isOn: $settings.showEXIFGPS)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("EXIF data only appears for image files with metadata")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Display Order Section
                    Text("Display Order")
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

                                Text(item.rawValue)
                                    .font(.system(size: 13))

                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                            .background(Color(NSColor.controlBackgroundColor))
                            .onDrag {
                                NSItemProvider(object: item.rawValue as NSString)
                            }
                            .onDrop(of: [.text], delegate: DisplayItemDropDelegate(
                                item: item,
                                items: $settings.displayOrder
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
                        Text("Drag items to reorder. EXIF moves as a group.")
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

// MARK: - About Settings
struct AboutSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("About")
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
                        Text("Version 1.0")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    // Description
                    Text("Displays file information when hovering over files in Finder.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Divider()
                        .padding(.vertical, 8)

                    // Usage Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("To use:")
                            .font(.system(size: 13, weight: .semibold))

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("1.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("Grant Accessibility permissions in System Settings")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            HStack(alignment: .top, spacing: 8) {
                                Text("2.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("Hover over any file in Finder to see its details")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: 360)

                    Divider()
                        .padding(.vertical, 8)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features:")
                            .font(.system(size: 13, weight: .semibold))

                        VStack(alignment: .leading, spacing: 6) {
                            FeatureRow(icon: "timer", text: "Customizable hover delay")
                            FeatureRow(icon: "paintbrush", text: "Adjustable window appearance")
                            FeatureRow(icon: "eye.slash", text: "Toggle information display")
                            FeatureRow(icon: "location", text: "Smart positioning")
                        }
                    }
                    .frame(maxWidth: 360)

                    Divider()
                        .padding(.vertical, 8)

                    // Credits
                    Text("Created with SwiftUI")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
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

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let fromIndex = items.firstIndex(of: item) else { return }

        // Get the dragged item from pasteboard
        if let itemProviders = info.itemProviders(for: [.text]).first {
            itemProviders.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                if let data = data as? Data,
                   let string = String(data: data, encoding: .utf8),
                   let draggedItem = DisplayItem.allCases.first(where: { $0.rawValue == string }),
                   let toIndex = items.firstIndex(of: draggedItem) {

                    if fromIndex != toIndex {
                        DispatchQueue.main.async {
                            withAnimation {
                                items.move(fromOffsets: IndexSet(integer: toIndex), toOffset: fromIndex > toIndex ? fromIndex + 1 : fromIndex)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
