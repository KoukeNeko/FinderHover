//
//  FinderInteraction.swift
//  FinderHover
//
//  Interacts with Finder using Accessibility API only (no AppleScript)
//

import Cocoa
import Foundation

class FinderInteraction {

    /// Checks if user is currently renaming a file in Finder
    static func isRenamingFile() -> Bool {
        guard let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first else {
            return false
        }

        let appElement = AXUIElementCreateApplication(finderApp.processIdentifier)

        // Get the focused UI element
        var focusedElementRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElementRef) == .success,
              let focusedElement = focusedElementRef as! AXUIElement? else {
            return false
        }

        // Check if the focused element is a text field
        var roleRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(focusedElement, kAXRoleAttribute as CFString, &roleRef) == .success,
           let role = roleRef as? String {
            // Text fields in Finder indicate renaming
            return role == "AXTextField" || role == kAXTextFieldRole as String
        }

        return false
    }

    /// Gets file at specific position using accessibility API
    static func getFileAtMousePosition(_ position: CGPoint) -> String? {
        // Don't show hover if user is renaming
        if isRenamingFile() {
            return nil
        }

        // Try to get selected files from Finder using Accessibility API
        if let selected = getSelectedFinderFiles().first {
            return selected
        }

        // Try to get element at mouse position
        return getFilePathAtPosition(position)
    }

    /// Gets currently selected files in Finder using Accessibility API
    static func getSelectedFinderFiles() -> [String] {
        guard let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first else {
            return []
        }

        let appElement = AXUIElementCreateApplication(finderApp.processIdentifier)

        // Try to get the focused window
        var focusedWindowRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowRef) == .success else {
            return []
        }

        guard let focusedWindow = focusedWindowRef else {
            return []
        }

        // Get the selected rows/items
        var selectedChildrenRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(focusedWindow as! AXUIElement, kAXSelectedChildrenAttribute as CFString, &selectedChildrenRef) == .success,
           let selectedChildren = selectedChildrenRef as? [AXUIElement] {

            var filePaths: [String] = []

            for child in selectedChildren {
                if let path = getFilePathFromElement(child) {
                    filePaths.append(path)
                }
            }

            return filePaths
        }

        // Alternative: try to get from focused UI element
        var focusedElementRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElementRef) == .success,
           let focusedElement = focusedElementRef {

            var selectedRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXSelectedChildrenAttribute as CFString, &selectedRef) == .success,
               let selected = selectedRef as? [AXUIElement] {

                return selected.compactMap { getFilePathFromElement($0) }
            }
        }

        return []
    }

    /// Gets file path at a specific screen position
    private static func getFilePathAtPosition(_ position: CGPoint) -> String? {
        let systemWideElement = AXUIElementCreateSystemWide()

        // Convert screen coordinates
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let axPosition = CGPoint(x: position.x, y: screenHeight - position.y)

        var elementRef: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(
            systemWideElement,
            Float(axPosition.x),
            Float(axPosition.y),
            &elementRef
        )

        guard result == .success, let element = elementRef else {
            return nil
        }

        // Check if we're in Finder
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)

        guard let app = NSRunningApplication(processIdentifier: pid),
              app.bundleIdentifier == "com.apple.finder" else {
            return nil
        }

        return getFilePathFromElement(element)
    }

    /// Extracts file path from an accessibility element
    private static func getFilePathFromElement(_ element: AXUIElement) -> String? {
        // Try different attributes that might contain file information
        let attributes: [String] = [
            kAXURLAttribute as String,
            kAXDescriptionAttribute as String,
            kAXTitleAttribute as String,
            kAXValueAttribute as String,
            "AXFilename",
        ]

        for attribute in attributes {
            var valueRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &valueRef)

            if result == .success, let value = valueRef {
                if let urlString = value as? String {
                    // Handle file:// URLs
                    if urlString.hasPrefix("file://") {
                        if let url = URL(string: urlString) {
                            return url.path
                        }
                    }

                    // Handle regular paths
                    if urlString.hasPrefix("/") {
                        return urlString
                    }

                    // Try to resolve filename
                    if let resolved = resolveFilename(urlString) {
                        return resolved
                    }
                } else if let url = value as? URL {
                    return url.path
                }
            }
        }

        // Try to get parent element and check that
        var parentRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &parentRef) == .success,
           let parent = parentRef {

            // Check parent's URL attribute
            var urlRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(parent as! AXUIElement, kAXURLAttribute as CFString, &urlRef) == .success,
               let urlValue = urlRef {

                if let urlString = urlValue as? String, urlString.hasPrefix("file://") {
                    if let url = URL(string: urlString) {
                        return url.path
                    }
                } else if let url = urlValue as? URL {
                    return url.path
                }
            }
        }

        return nil
    }

    /// Tries to resolve a filename to a full path
    private static func resolveFilename(_ filename: String) -> String? {
        // If already a full path
        if filename.hasPrefix("/") {
            return filename
        }

        // Try to get current Finder window path via Accessibility
        if let windowPath = getCurrentFinderWindowPath() {
            let url = URL(fileURLWithPath: windowPath).appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: url.path) {
                return url.path
            }
        }

        // Try common locations
        let commonPaths = [
            FileManager.default.homeDirectoryForCurrentUser.path,
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").path,
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents").path,
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").path,
        ]

        for basePath in commonPaths {
            let url = URL(fileURLWithPath: basePath).appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: url.path) {
                return url.path
            }
        }

        return nil
    }

    /// Gets the path of the current Finder window using Accessibility API
    private static func getCurrentFinderWindowPath() -> String? {
        guard let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(finderApp.processIdentifier)

        // Get focused window
        var focusedWindowRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowRef) == .success,
              let focusedWindow = focusedWindowRef else {
            return nil
        }

        // Try to get document/URL attribute
        var documentRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(focusedWindow as! AXUIElement, kAXDocumentAttribute as CFString, &documentRef) == .success,
           let document = documentRef {

            if let urlString = document as? String {
                if urlString.hasPrefix("file://") {
                    return URL(string: urlString)?.path
                }
                return urlString
            } else if let url = document as? URL {
                return url.path
            }
        }

        return nil
    }
}
