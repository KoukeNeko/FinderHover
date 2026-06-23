//
//  AppRelauncher.swift
//  FinderHover
//
//  Relaunches the app so a new language preference takes effect.
//

import AppKit

/// Restarts the running app by spawning a detached `open -n` that re-launches the
/// bundle once this process exits. Valid for non-sandboxed, hardened-runtime apps.
enum AppRelauncher {
    static func relaunch() {
        let bundlePath = Bundle.main.bundlePath
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        // -n forces a fresh instance once the current one has terminated.
        task.arguments = ["-n", bundlePath]
        do {
            try task.run()
        } catch {
            Logger.error("Relaunch failed", error: error, subsystem: .settings)
            return
        }
        NSApp.terminate(nil)
    }
}
