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
    @StateObject private var trialManager = TrialManager.shared
    @StateObject private var storeKitService = StoreKitService.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(hoverManager: hoverManager, trialManager: trialManager)
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
    @ObservedObject var trialManager: TrialManager
    @Environment(\.openSettings) private var openSettings

    private var isUnlocked: Bool {
        trialManager.isFeatureUnlocked
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task { hoverManager.startMonitoring() }

        // Trial status indicator
        switch trialManager.licenseStatus {
        case .trial(let daysRemaining):
            Text(String(format: "menu.trial.daysRemaining".localized, daysRemaining))
                .foregroundColor(.secondary)
        case .expired:
            Text("menu.trial.expired".localized)
                .foregroundColor(.red)
        case .purchased:
            EmptyView()
        }

        if isUnlocked {
            Button(hoverManager.isEnabled ? "menu.disable".localized : "menu.enable".localized) {
                hoverManager.isEnabled.toggle()
            }
            .keyboardShortcut("e")
        } else {
            Button("menu.trial.purchase".localized) {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            }
        }

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
