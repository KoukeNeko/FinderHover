//
//  SettingsView.swift
//  FinderHover
//
//  Settings window: a page switcher over live-preview pages
//

import SwiftUI

enum SettingsPage: String, CaseIterable, Identifiable {
    case display
    case behavior
    case appearance
    case permissions
    case about

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .behavior: return "settings.tab.behavior".localized
        case .appearance: return "settings.tab.appearance".localized
        case .display: return "settings.tab.display".localized
        case .permissions: return "settings.tab.permissions".localized
        case .about: return "settings.tab.about".localized
        }
    }
}

struct SettingsView: View {
    // Pages observe their own settings. Navigation does not need every preference update.
    private let settings = AppSettings.shared
    @State private var selectedPage: SettingsPage = .display
    @State private var confirmingReset = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            pageContent(for: selectedPage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 960, minHeight: 640)
        .alert("settings.resetAll".localized, isPresented: $confirmingReset) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("settings.resetAll".localized, role: .destructive) { settings.resetToDefaults() }
        } message: {
            Text("settings.resetAll.message".localized)
        }
    }

    private var header: some View {
        ZStack {
            Picker("", selection: $selectedPage) {
                ForEach(SettingsPage.allCases) { page in
                    Text(page.localizedName).tag(page)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()

            HStack {
                Spacer()
                Button("settings.resetAll".localized) { confirmingReset = true }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder
    private func pageContent(for page: SettingsPage) -> some View {
        switch page {
        case .behavior:    BehaviorSettingsView(settings: settings)
        case .appearance:  AppearanceSettingsView(settings: settings)
        case .display:     DisplaySettingsView(settings: settings)
        case .permissions: PermissionsSettingsView()
        case .about:       AboutSettingsView()
        }
    }
}

#Preview {
    SettingsView()
}
