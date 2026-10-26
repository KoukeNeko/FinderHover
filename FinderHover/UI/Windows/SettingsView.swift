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
    @SceneStorage("settings.page") private var selectedPage: SettingsPage = .display
    @State private var confirmingReset = false

    // The toolbar lives here, in the one view that does not observe AppSettings, so
    // flipping a setting re-renders the page without rebuilding the toolbar.
    var body: some View {
        pageContent(for: selectedPage)
            .frame(minWidth: 960, maxWidth: .infinity, minHeight: 640, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $selectedPage) {
                        ForEach(SettingsPage.allCases) { page in
                            Text(page.localizedName).tag(page)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("settings.resetAll".localized) { confirmingReset = true }
                }
            }
            .alert("settings.resetAll".localized, isPresented: $confirmingReset) {
                Button("common.cancel".localized, role: .cancel) {}
                Button("settings.resetAll".localized, role: .destructive) { settings.resetToDefaults() }
            } message: {
                Text("settings.resetAll.message".localized)
            }
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
