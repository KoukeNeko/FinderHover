//
//  FinderHoverApp.swift
//  FinderHover
//
//  Created by 陳德生 on 2025/11/3.
//

import SwiftUI

@main
struct FinderHoverApp: App {
    @StateObject private var hoverManager = HoverManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(hoverManager: hoverManager)
        } label: {
            Image(systemName: hoverManager.isEnabled
                  ? "appwindow.swipe.rectangle"
                  : "appwindow.swipe.rectangle")
                .opacity(hoverManager.isEnabled ? 1.0 : 0.5)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
        .defaultSize(width: 780, height: 540)
    }
}

private struct MenuBarContentView: View {
    @ObservedObject var hoverManager: HoverManager
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task { hoverManager.startMonitoring() }

        Button(hoverManager.isEnabled ? "menu.disable".localized : "menu.enable".localized) {
            hoverManager.isEnabled.toggle()
        }
        .keyboardShortcut("e")

        Divider()

        Button("menu.settings".localized) {
            openSettings()
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",")

        Divider()

        Button("menu.quit".localized) {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
