//
//  HoverManager.swift
//  FinderHover
//
//  Coordinates mouse tracking and hover window display
//

import Cocoa
import Combine
import SwiftUI

class HoverManager: ObservableObject {
    @Published var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }

    @Published var currentFileInfo: FileInfo?

    private let mouseTracker = MouseTracker()
    private var hoverWindow: HoverWindowController?
    private var cancellables = Set<AnyCancellable>()
    private var displayTimer: Timer?
    private var renamingCheckTimer: Timer?
    private var lastMouseLocation: CGPoint = .zero
    private let settings = AppSettings.shared

    // Store observer tokens for cleanup
    private var appActivateObserver: NSObjectProtocol?
    private var appDeactivateObserver: NSObjectProtocol?
    private var unlockObserver: NSObjectProtocol?

    init() {
        setupSubscriptions()
        setupAppSwitchObserver()
        setupUnlockObserver()
        checkAccessibilityPermissions()
    }

    private func setupUnlockObserver() {
        // Listen for Option key release to re-check cursor position
        unlockObserver = NotificationCenter.default.addObserver(
            forName: .hoverWindowUnlocked,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // Force hide first, then check if we need to show again
            self.hoverWindow?.hide()
            self.currentFileInfo = nil
            // Get CURRENT mouse location and check if over a file
            let currentLocation = NSEvent.mouseLocation
            self.checkAndDisplayFileInfo(at: currentLocation)
        }
    }

    private func setupSubscriptions() {
        // Monitor mouse location changes with immediate hide check
        mouseTracker.$mouseLocation
            .sink { [weak self] location in
                self?.lastMouseLocation = location
                self?.checkIfShouldHide(at: location)
            }
            .store(in: &cancellables)

        // Monitor mouse location changes with debounce for showing
        mouseTracker.$mouseLocation
            .debounce(for: .milliseconds(Constants.MouseTracking.hoverDebounceDelay), scheduler: RunLoop.main)
            .sink { [weak self] location in
                self?.handleMouseLocation(location)
            }
            .store(in: &cancellables)

        // Monitor dragging state - hide window when dragging starts
        mouseTracker.$isDragging
            .sink { [weak self] isDragging in
                if isDragging {
                    self?.hideHoverWindow()
                    self?.currentFileInfo = nil
                    self?.invalidateDisplayTimer()
                }
            }
            .store(in: &cancellables)
    }

    private func setupAppSwitchObserver() {
        // Monitor when any application becomes active
        appActivateObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let app = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }

            // If the activated app is NOT Finder, hide the hover window
            if app.bundleIdentifier != "com.apple.finder" {
                self?.hideHoverWindow()
                self?.currentFileInfo = nil
                self?.invalidateDisplayTimer()
            }
        }

        // Monitor when any application is deactivated
        appDeactivateObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let app = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }

            // If Finder is deactivated, hide the hover window
            if app.bundleIdentifier == "com.apple.finder" {
                self?.hideHoverWindow()
                self?.currentFileInfo = nil
                self?.invalidateDisplayTimer()
            }
        }
    }

    private func removeAppSwitchObservers() {
        if let observer = appActivateObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            appActivateObserver = nil
        }
        if let observer = appDeactivateObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            appDeactivateObserver = nil
        }
    }

    func startMonitoring() {
        guard isEnabled else {
            Logger.debug("Monitoring not started - disabled by user", subsystem: .mouseTracking)
            return
        }
        Logger.info("Starting mouse tracking", subsystem: .mouseTracking)
        mouseTracker.startTracking()
    }

    func stopMonitoring() {
        Logger.info("Stopping mouse tracking", subsystem: .mouseTracking)
        mouseTracker.stopTracking()
        hideHoverWindow()
        invalidateDisplayTimer()
        invalidateRenamingTimer()
    }

    private func checkIfShouldHide(at location: CGPoint) {
        // Only auto-hide if enabled in settings
        guard settings.autoHideEnabled else { return }

        // If window is showing and we have current file info
        guard let currentInfo = currentFileInfo else { return }

        // Check if Quick Look preview is visible - hide immediately
        if FinderInteraction.isQuickLookVisible() {
            hideHoverWindow()
            currentFileInfo = nil
            invalidateDisplayTimer()
            return
        }

        // Check if user is renaming - hide immediately
        if FinderInteraction.isRenamingFile() {
            hideHoverWindow()
            currentFileInfo = nil
            invalidateDisplayTimer()
            return
        }

        // Check if mouse has moved significantly or if we can't find the same file
        if let currentPath = FinderInteraction.getFileAtMousePosition(location) {
            // If different file or no file, hide immediately
            if currentPath != currentInfo.path {
                hideHoverWindow()
                currentFileInfo = nil
                invalidateDisplayTimer()
            }
        } else {
            // No file under cursor, hide immediately
            hideHoverWindow()
            currentFileInfo = nil
            invalidateDisplayTimer()
        }
    }

    private func handleMouseLocation(_ location: CGPoint) {
        guard isEnabled else { return }

        // Don't show hover window while dragging
        guard !mouseTracker.isDragging else { return }

        // Check if hovering over Finder and get file info
        invalidateDisplayTimer()
        displayTimer = Timer.scheduledTimer(withTimeInterval: settings.hoverDelay, repeats: false) { [weak self] _ in
            self?.checkAndDisplayFileInfo(at: location)
        }
    }

    private func checkAndDisplayFileInfo(at location: CGPoint) {
        // Don't show hover window while dragging
        guard !mouseTracker.isDragging else { return }

        // Don't show hover window if Quick Look preview is visible
        guard !FinderInteraction.isQuickLookVisible() else { return }

        // Try to get file path at current location
        // This will return nil if user is renaming
        if let filePath = FinderInteraction.getFileAtMousePosition(location),
           let fileInfo = FileInfo.from(path: filePath) {

            // Only update if it's a different file
            if currentFileInfo?.path != fileInfo.path {
                Logger.debug("Displaying hover for file: \(fileInfo.name)", subsystem: .ui)
                currentFileInfo = fileInfo
                showHoverWindow(at: location, with: fileInfo)
            }
        } else {
            hideHoverWindow()
            currentFileInfo = nil
        }
    }

    private func showHoverWindow(at position: CGPoint, with fileInfo: FileInfo) {
        if hoverWindow == nil {
            hoverWindow = HoverWindowController()
        }

        hoverWindow?.show(at: position, with: fileInfo)

        // Start periodic check for renaming
        startRenamingCheck()
    }

    private func hideHoverWindow() {
        // Don't hide if window is locked (Option key pressed)
        guard hoverWindow?.isLocked != true else { return }

        hoverWindow?.hide()

        // Stop periodic check
        stopRenamingCheck()
    }

    private func startRenamingCheck() {
        // Stop existing timer
        invalidateRenamingTimer()

        // Check periodically if user is renaming or Quick Look is visible
        renamingCheckTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.MouseTracking.renamingCheckInterval,
            repeats: true
        ) { [weak self] _ in
            // Hide if Quick Look preview is shown
            if FinderInteraction.isQuickLookVisible() {
                self?.hideHoverWindow()
                self?.currentFileInfo = nil
                return
            }
            // Hide if user is renaming
            if FinderInteraction.isRenamingFile() {
                self?.hideHoverWindow()
                self?.currentFileInfo = nil
            }
        }
    }

    private func stopRenamingCheck() {
        invalidateRenamingTimer()
    }

    // MARK: - Timer Management Helpers

    /// Safely invalidate and nil the display timer
    private func invalidateDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    /// Safely invalidate and nil the renaming check timer
    private func invalidateRenamingTimer() {
        renamingCheckTimer?.invalidate()
        renamingCheckTimer = nil
    }

    private func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            Logger.warning("Accessibility permissions not granted", subsystem: .accessibility)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAccessibilityAlert()
            }
        } else {
            Logger.info("Accessibility permissions granted", subsystem: .accessibility)
        }
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "FinderHover needs accessibility permissions to detect files under your cursor. Please grant access in System Settings > Privacy & Security > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    deinit {
        stopMonitoring()
        removeAppSwitchObservers()
        cancellables.removeAll()
    }
}
