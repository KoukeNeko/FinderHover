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
                if isDragging {
                    self?.hideHoverWindow()
                    self?.currentFileInfo = nil
                    self?.invalidateDisplayTimer()
                    self?.invalidateMetadataRequests()
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
            if app.bundleIdentifier == "com.apple.finder" {
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

        guard PaddleService.shared.isFeatureUnlocked else {
            Logger.debug("Monitoring not started - license expired", subsystem: .mouseTracking)
            isEnabled = false
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
        invalidateMetadataRequests()
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
        // This will return nil if user is renaming
        guard let filePath = FinderInteraction.getFileAtMousePosition(location) else {
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

    deinit {
        stopMonitoring()
        removeAppSwitchObservers()
        cancellables.removeAll()
    }
}
