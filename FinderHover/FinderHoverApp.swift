//
//  FinderHoverApp.swift
//  FinderHover
//
//  Created by 陳德生 on 2025/11/3.
//

import SwiftUI

@main
struct FinderHoverApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var hoverManager: HoverManager?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon to make it a menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "FinderHover")
        }

        setupMenuBar()

        // Initialize and start hover manager
        hoverManager = HoverManager()
        hoverManager?.startMonitoring()
    }

    private func setupMenuBar() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem.separator())

        // Toggle enable/disable
        let toggleItem = NSMenuItem(
            title: "menu.enable".localized,
            action: #selector(toggleHover),
            keyEquivalent: "e"
        )
        toggleItem.state = .on
        toggleItem.tag = 100
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        menu.addItem(NSMenuItem(
            title: "menu.settings".localized,
            action: #selector(showSettings),
            keyEquivalent: ","
        ))

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(
            title: "menu.quit".localized,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        if let item = statusItem {
            item.menu = menu
        }
    }

    @objc func toggleHover(_ sender: NSMenuItem) {
        if sender.state == .on {
            sender.state = .off
            hoverManager?.isEnabled = false
            sender.title = "menu.enable".localized
        } else {
            sender.state = .on
            hoverManager?.isEnabled = true
            sender.title = "menu.disable".localized
        }
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "Settings"
            window.styleMask = [.titled, .closable, .resizable]
            window.minSize = NSSize(width: 650, height: 500)
            window.setContentSize(NSSize(width: 650, height: 500))
            window.center()
            window.setFrameAutosaveName("FinderHoverSettings")
            window.isReleasedWhenClosed = false

            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
