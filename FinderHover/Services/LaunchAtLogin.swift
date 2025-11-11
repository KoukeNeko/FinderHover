//
//  LaunchAtLogin.swift
//  FinderHover
//
//  Manages login item registration for launching at startup
//

import Foundation
import ServiceManagement

class LaunchAtLogin {
    static func setEnabled(_ enabled: Bool) {
        if enabled {
            enable()
        } else {
            disable()
        }
    }

    static func enable() {
        // Register the app as a login item
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
            } catch {
                print("Failed to register login item: \(error)")
            }
        } else {
            // Fallback for macOS 12 and earlier
            let success = SMLoginItemSetEnabled("dev.koukeneko.FinderHover" as CFString, true)
            if !success {
                print("Failed to enable login item")
            }
        }
    }

    static func disable() {
        // Unregister the app as a login item
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
            } catch {
                print("Failed to unregister login item: \(error)")
            }
        } else {
            // Fallback for macOS 12 and earlier
            let success = SMLoginItemSetEnabled("dev.koukeneko.FinderHover" as CFString, false)
            if !success {
                print("Failed to disable login item")
            }
        }
    }

    static func isEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // For macOS 12 and earlier, we need to check differently
            // Since we're targeting macOS 14.0+, this shouldn't be reached
            return false
        }
    }
}
