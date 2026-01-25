//
//  FinderInteraction.swift
//  FinderHover
//
//  Interacts with Finder using Accessibility API only (no AppleScript)
//

import Cocoa
import Foundation

class FinderInteraction {

    /// Timeout for Accessibility API operations (in seconds)
    private static let accessibilityTimeout: TimeInterval = 0.5

    /// Execute an Accessibility operation with timeout to prevent blocking
    private static func withTimeout<T>(_ timeout: TimeInterval = accessibilityTimeout, operation: @escaping () -> T?) -> T? {
        var result: T?
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.global(qos: .userInteractive).async {
            result = operation()
            semaphore.signal()
        }

        let waitResult = semaphore.wait(timeout: .now() + timeout)

        if waitResult == .timedOut {
            Logger.warning("Accessibility operation timed out after \(timeout)s", subsystem: .accessibility)
            return nil
        }

        return result
    }

    /// Checks if user is currently renaming a file in Finder
    static func isRenamingFile() -> Bool {
        return withTimeout { isRenamingFileImpl() } ?? false
    }

    private static func isRenamingFileImpl() -> Bool {
        guard let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first else {
            return false
        }

        let appElement = AXUIElementCreateApplication(finderApp.processIdentifier)

        // Get the focused UI element
        var focusedElementRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElementRef) == .success,
              let focusedElement = (focusedElementRef as! AXUIElement?) else {
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
        return withTimeout { getFileAtMousePositionImpl(position) } ?? nil
    }

    private static func getFileAtMousePositionImpl(_ position: CGPoint) -> String? {
        // Don't show hover if user is renaming
        if isRenamingFileImpl() {
            return nil
        }

        // Try to get element at mouse position first (priority)
        if let filePath = getFilePathAtPosition(position) {
            return filePath
        }

        // Fall back to selected files if we couldn't get file at position
        if let selected = getSelectedFinderFilesImpl().first {
            return selected
        }

        return nil
    }

    /// Gets currently selected files in Finder using Accessibility API
    static func getSelectedFinderFiles() -> [String] {
        return withTimeout { getSelectedFinderFilesImpl() } ?? []
    }

    private static func getSelectedFinderFilesImpl() -> [String] {
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
        // Note: focusedWindow is CFTypeRef which is bridged to AXUIElement
        // The force cast is safe here as we confirmed it exists above
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

            // Note: focusedElement is CFTypeRef bridged to AXUIElement
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

        // Convert Cocoa coordinates to Accessibility API coordinates
        // Cocoa: origin at bottom-left of primary screen, Y increases upward
        // AX/Quartz: origin at top-left of primary screen, Y increases downward
        // The conversion requires the PRIMARY screen's height, not the current screen
        let primaryScreen = NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.main
        let primaryScreenHeight = primaryScreen?.frame.height ?? 0
        let axPosition = CGPoint(x: position.x, y: primaryScreenHeight - position.y)

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

        // Check the element's role to filter out window controls and non-file elements
        var roleRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef) == .success,
           let role = roleRef as? String {
            // Ignore window controls, buttons, and other UI elements
            // Note: AXImage is NOT in this list because file icons in Finder have AXImage role
            let ignoredRoles = [
                "AXButton",
                "AXCloseButton",
                "AXMinimizeButton",
                "AXZoomButton",
                "AXToolbarButton",
                "AXWindow",
                "AXDialog",
                "AXSheet",
                "AXScrollBar",
                "AXScrollArea",
                "AXStaticText"
            ]

            if ignoredRoles.contains(role) {
                return nil
            }
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

            // Note: parent is CFTypeRef bridged to AXUIElement
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

    /// Checks if Quick Look preview is currently visible
    static func isQuickLookVisible() -> Bool {
        // Quick Look UI Service bundle identifier
        let quickLookBundleIDs = [
            "com.apple.quicklook.QuickLookUIService",
            "com.apple.QuickLookUIService",
            "com.apple.quicklook.qlmanage"
        ]

        // Method 1: Check if Quick Look process has visible windows using CGWindowList
        if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
            for window in windowList {
                if let ownerName = window[kCGWindowOwnerName as String] as? String {
                    // Quick Look windows have owner name containing "QuickLook"
                    if ownerName.contains("QuickLook") || ownerName.contains("qlmanage") {
                        // Check if window has reasonable size (not just a tiny helper window)
                        if let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                           let width = bounds["Width"],
                           let height = bounds["Height"],
                           width > 100 && height > 100 {
                            return true
                        }
                    }
                }

                // Also check by bundle identifier if available
                if let bundleID = window[kCGWindowOwnerPID as String] as? pid_t {
                    if let app = NSRunningApplication(processIdentifier: bundleID),
                       let appBundleID = app.bundleIdentifier,
                       quickLookBundleIDs.contains(appBundleID) {
                        return true
                    }
                }
            }
        }

        // Method 2: Check running applications
        for bundleID in quickLookBundleIDs {
            let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            for app in apps {
                // Check if the app is not hidden and has windows
                if !app.isHidden && !app.isTerminated {
                    // Quick Look is running - now verify it has visible windows
                    // by checking CGWindowList for this specific PID
                    if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] {
                        for window in windowList {
                            if let windowPID = window[kCGWindowOwnerPID as String] as? pid_t,
                               windowPID == app.processIdentifier {
                                // Has at least one on-screen window
                                if let layer = window[kCGWindowLayer as String] as? Int,
                                   layer >= 0 {
                                    return true
                                }
                            }
                        }
                    }
                }
            }
        }

        return false
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
        // Note: focusedWindow is CFTypeRef bridged to AXUIElement
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
