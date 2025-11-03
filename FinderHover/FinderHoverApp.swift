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

        // Status display
        let statusMenuItem = NSMenuItem(title: "FinderHover Active", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Toggle enable/disable
        let toggleItem = NSMenuItem(
            title: "Enable Hover Preview",
            action: #selector(toggleHover),
            keyEquivalent: "e"
        )
        toggleItem.state = .on
        toggleItem.tag = 100
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // About
        menu.addItem(NSMenuItem(
            title: "About FinderHover",
            action: #selector(showAbout),
            keyEquivalent: "a"
        ))

        // Quit
        menu.addItem(NSMenuItem(
            title: "Quit",
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
            sender.title = "Enable Hover Preview"
        } else {
            sender.state = .on
            hoverManager?.isEnabled = true
            sender.title = "Disable Hover Preview"
        }
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "FinderHover"
        alert.informativeText = """
        Version 1.0

        Displays file information when hovering over files in Finder.

        To use:
        1. Grant Accessibility permissions in System Settings
        2. Hover over any file in Finder to see its details

        Created with SwiftUI
        """
        alert.alertStyle = .informational
        alert.runModal()
    }
}
