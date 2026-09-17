//
//  SettingsView.swift
//  FinderHover
//
//  Settings window UI with tab navigation
//

import SwiftUI

enum SettingsPage: String, CaseIterable, Identifiable {
    case behavior
    case appearance
    case display
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

    var icon: String {
        switch self {
        case .behavior: return "hand.point.up.left"
        case .appearance: return "paintbrush"
        case .display: return "list.bullet"
        case .permissions: return "lock.shield"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    // Pages observe their own settings. Navigation does not need every preference update.
    private let settings = AppSettings.shared
    @State private var selectedPage: SettingsPage = .behavior
    @State private var confirmingReset = false

    var body: some View {
        windowContent
            .frame(minWidth: 560, minHeight: 540)
            .alert("settings.resetAll".localized, isPresented: $confirmingReset) {
                Button("common.cancel".localized, role: .cancel) {}
                Button("settings.resetAll".localized, role: .destructive) { settings.resetToDefaults() }
            } message: {
                Text("settings.resetAll.message".localized)
            }
    }

    private var windowContent: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedPage) {
                ForEach(SettingsPage.allCases) { page in
                    pageContent(for: page)
                        .padding(.top, 20)
                        .tabItem {
                            Label(page.localizedName, systemImage: page.icon)
                        }
                        .tag(page)
                }
            }

            Divider()

            HStack(spacing: 10) {
                Label("settings.savedAutomatically".localized, systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("settings.resetAll".localized) { confirmingReset = true }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
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
