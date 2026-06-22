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
    private let metadataQueue = DispatchQueue(label: "com.finderhover.metadataExtraction", qos: .userInitiated)
    private var metadataRequestToken: UInt64 = 0
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
            // Don't dismiss or re-evaluate while the user is editing notes
            guard !HoverWindowState.shared.isEditingNotes else { return }
            // Force hide first, then check if we need to show again
            self.hoverWindow?.hide()
            self.currentFileInfo = nil
            self.invalidateMetadataRequests()
            // Get CURRENT mouse location and check if over a file
            let currentLocation = NSEvent.mouseLocation
            self.checkAndDisplayFileInfo(at: currentLocation)
        }
    }

    private func setupSubscriptions() {
        // Always keep latest mouse location for async metadata validation
        mouseTracker.$mouseLocation
            .sink { [weak self] location in
                self?.lastMouseLocation = location
            }
            .store(in: &cancellables)

        // Monitor mouse location changes with throttled hide check
        mouseTracker.$mouseLocation
            .throttle(
                for: .milliseconds(Constants.Performance.hoverHideThrottleMs),
                scheduler: RunLoop.main,
                latest: true
            )
            .sink { [weak self] location in
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
                guard let self = self else { return }
                if isDragging {
                    // A mouseDown fired. If it occurred inside the popup, ignore it —
                    // the user is clicking to interact with the popup (e.g. notes field).
                    if self.isMouseOverHoverWindow() {
                        return
                    }
                    // Click outside popup: reset any editing state so guards don't block
                    HoverWindowState.shared.isEditingNotes = false
                    self.hideHoverWindow()
                    self.currentFileInfo = nil
                    self.invalidateDisplayTimer()
                    self.invalidateMetadataRequests()
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

            // If the activated app is NOT Finder, hide the hover window.
            // Guard: don't hide if the activation was caused by clicking inside the popup itself
            // (e.g. FinderHover activating because the user clicked in the Notes text editor).
            if app.bundleIdentifier != "com.apple.finder" {
                if self?.isMouseOverHoverWindow() ?? false {
                    return
                }
                self?.hideHoverWindow()
                self?.currentFileInfo = nil
                self?.invalidateDisplayTimer()
                self?.invalidateMetadataRequests()
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
            // Guard: don't hide if the deactivation was caused by clicking the popup itself
            if app.bundleIdentifier == "com.apple.finder" {
                if self?.isMouseOverHoverWindow() ?? false {
                    return
                }
                self?.hideHoverWindow()
                self?.currentFileInfo = nil
                self?.invalidateDisplayTimer()
                self?.invalidateMetadataRequests()
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
        // Force-hide unconditionally: we are tearing down all tracking machinery,
        // so the popup must not remain visible (even during notes editing).
        hoverWindow?.forceHide()
        invalidateDisplayTimer()
        invalidateRenamingTimer()
        invalidateMetadataRequests()
    }

    private func checkIfShouldHide(at location: CGPoint) {
        // Only auto-hide if enabled in settings
        guard settings.autoHideEnabled else { return }

        // If window is showing and we have current file info
        guard let currentInfo = currentFileInfo else { return }

        // Don't hide if mouse is over the popup window
        if isMouseOverHoverWindow(at: location) {
            return
        }

        // Don't hide if user is editing notes in the popup
        if HoverWindowState.shared.isEditingNotes {
            return
        }

        // Check if Quick Look preview is visible - hide immediately
        if FinderInteraction.isQuickLookVisible() {
            hideHoverWindow()
            currentFileInfo = nil
            invalidateDisplayTimer()
            invalidateMetadataRequests()
            return
        }

        // Check if user is renaming - hide immediately
        if FinderInteraction.isRenamingFile() {
            hideHoverWindow()
            currentFileInfo = nil
            invalidateDisplayTimer()
            invalidateMetadataRequests()
            return
        }

        // Check if mouse has moved significantly or if we can't find the same file
        if let currentPath = FinderInteraction.getFileAtMousePosition(location) {
            // If different file or no file, hide immediately
            if currentPath != currentInfo.path {
                hideHoverWindow()
                currentFileInfo = nil
                invalidateDisplayTimer()
                invalidateMetadataRequests()
            }
        } else {
            // No file under cursor, hide immediately
            hideHoverWindow()
            currentFileInfo = nil
            invalidateDisplayTimer()
            invalidateMetadataRequests()
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
        // This will return nil if user is renaming or if cursor is over the popup itself
        guard let filePath = FinderInteraction.getFileAtMousePosition(location) else {
            // Don't hide if mouse is over the popup (accessibility returns nil there)
            if isMouseOverHoverWindow(at: location) {
                return
            }
            hideHoverWindow()
            currentFileInfo = nil
            invalidateMetadataRequests()
            return
        }

        // No-op if we are already showing metadata for the same file
        guard currentFileInfo?.path != filePath else { return }

        let requestToken = beginMetadataRequest()
        let extractionPolicy = FileInfo.MetadataExtractionPolicy.from(settings: settings)

        metadataQueue.async { [weak self] in
            guard let fileInfo = FileInfo.from(path: filePath, policy: extractionPolicy) else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    guard self.isMetadataRequestCurrent(requestToken) else { return }
                    self.hideHoverWindow()
                    self.currentFileInfo = nil
                }
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard self.isMetadataRequestCurrent(requestToken) else { return }
                guard !self.mouseTracker.isDragging else { return }
                guard !FinderInteraction.isQuickLookVisible() else { return }

                // Skip stale result if cursor is no longer over the file.
                if FinderInteraction.getFileAtMousePosition(self.lastMouseLocation) != fileInfo.path {
                    return
                }

                Logger.debug("Displaying hover for file: \(fileInfo.name)", subsystem: .ui)
                self.currentFileInfo = fileInfo
                self.showHoverWindow(at: location, with: fileInfo)
            }
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
        // Don't hide if user is editing notes
        guard !HoverWindowState.shared.isEditingNotes else { return }

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
                self?.invalidateMetadataRequests()
                return
            }
            // Hide if user is renaming
            if FinderInteraction.isRenamingFile() {
                self?.hideHoverWindow()
                self?.currentFileInfo = nil
                self?.invalidateMetadataRequests()
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

    /// Creates a new token for metadata extraction and invalidates older pending results.
    private func beginMetadataRequest() -> UInt64 {
        metadataRequestToken &+= 1
        return metadataRequestToken
    }

    /// Invalidates all in-flight metadata extraction results.
    private func invalidateMetadataRequests() {
        metadataRequestToken &+= 1
    }

    /// Checks if the async metadata result still belongs to the latest request.
    private func isMetadataRequestCurrent(_ token: UInt64) -> Bool {
        token == metadataRequestToken
    }

    /// Checks if the mouse is currently over the hover window.
    /// - Parameter location: The point to check. Defaults to current mouse location if nil.
    /// - Returns: true if the window is visible and the location is within its frame, false otherwise.
    private func isMouseOverHoverWindow(at location: NSPoint? = nil) -> Bool {
        guard let window = hoverWindow?.window, window.isVisible else { return false }
        let checkLocation = location ?? NSEvent.mouseLocation
        return window.frame.contains(checkLocation)
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
