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
    case preview
    case permissions
    case about

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .behavior: return "settings.tab.behavior".localized
        case .appearance: return "settings.tab.appearance".localized
        case .display: return "settings.tab.display".localized
        case .preview: return "settings.tab.preview".localized
        case .permissions: return "settings.tab.permissions".localized
        case .about: return "settings.tab.about".localized
        }
    }

    var icon: String {
        switch self {
        case .behavior: return "hand.point.up.left.fill"
        case .appearance: return "paintbrush.fill"
        case .display: return "list.bullet"
        case .preview: return "eye.fill"
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
                            .foregroundColor(selectedPage == page ? .white : .accentColor)
                            .frame(width: 20)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
            }
            .navigationSplitViewColumnWidth(220)
            .listStyle(.sidebar)
            .frame(minWidth: 200)
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
                case .preview:
                    PreviewSettingsView(settings: settings)
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
