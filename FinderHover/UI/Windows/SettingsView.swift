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
        case .behavior: return "hand.point.up.left.fill"
        case .appearance: return "paintbrush.fill"
        case .display: return "list.bullet"
        case .permissions: return "lock.shield.fill"
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
            // Detail view using factory pattern
            Group {
                switch selectedPage {
                case .behavior:
                    BehaviorSettingsView(settings: settings)
                case .appearance:
                    AppearanceSettingsView(settings: settings)
                case .display:
                    DisplaySettingsView(settings: settings)
                case .permissions:
                    PermissionsSettingsView()
                case .about:
                    AboutSettingsView()
                }
            }
            .frame(minWidth: 450, minHeight: 400)
        }
    }
}

#Preview {
    SettingsView()
}
