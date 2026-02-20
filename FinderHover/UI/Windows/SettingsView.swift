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
        case .behavior: return "hand.point.up.left"
        case .appearance: return "paintbrush"
        case .display: return "list.bullet"
        case .permissions: return "lock.shield"
        case .about: return "info.circle"
        }
    }
}

private struct FullHeightSidebarWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            // window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.toolbarStyle = .unified
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var selectedPage: SettingsPage = .behavior

    var body: some View {
        NavigationSplitView {
            List(SettingsPage.allCases, id: \.self, selection: $selectedPage) { page in
                Label(page.localizedName, systemImage: page.icon)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 240)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .toolbar(removing: .sidebarToggle)
        .background(FullHeightSidebarWindowConfigurator())
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedPage {
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
