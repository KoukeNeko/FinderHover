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

    var iconBackgroundColor: Color {
        switch self {
        case .behavior: return .blue
        case .appearance: return .purple
        case .display: return .orange
        case .permissions: return .green
        case .about: return Color(NSColor.systemGray)
        }
    }
}

private struct SidebarItemLabel: View {
    let page: SettingsPage

    var body: some View {
        Label {
            Text(page.localizedName)
                .font(.system(size: 13))
        } icon: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(page.iconBackgroundColor)
                    .frame(width: 28, height: 28)
                Image(systemName: page.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            }
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
                    SidebarItemLabel(page: page)
                }
            }
            .navigationSplitViewColumnWidth(220)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

#Preview {
    SettingsView()
}
