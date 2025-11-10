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
    private var hideCheckTimer: Timer?
    private var renamingCheckTimer: Timer?
    private var lastMouseLocation: CGPoint = .zero
    private let settings = AppSettings.shared

    init() {
        setupSubscriptions()
        setupAppSwitchObserver()
        checkAccessibilityPermissions()
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
                    self?.displayTimer?.invalidate()
                }
            }
            .store(in: &cancellables)
    }

    private func setupAppSwitchObserver() {
        // Monitor when any application becomes active
        NSWorkspace.shared.notificationCenter.addObserver(
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
                self?.displayTimer?.invalidate()
            }
        }

        // Monitor when any application is deactivated
        NSWorkspace.shared.notificationCenter.addObserver(
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
                self?.displayTimer?.invalidate()
            }
        }
    }

    func startMonitoring() {
        guard isEnabled else { return }
        mouseTracker.startTracking()
    }

    func stopMonitoring() {
        mouseTracker.stopTracking()
        hideHoverWindow()
        hideCheckTimer?.invalidate()
        displayTimer?.invalidate()
        renamingCheckTimer?.invalidate()
    }

    private func checkIfShouldHide(at location: CGPoint) {
        // Only auto-hide if enabled in settings
        guard settings.autoHideEnabled else { return }

        // If window is showing and we have current file info
        guard let currentInfo = currentFileInfo else { return }

        // Check if user is renaming - hide immediately
        if FinderInteraction.isRenamingFile() {
            hideHoverWindow()
            currentFileInfo = nil
            displayTimer?.invalidate()
            return
        }

        // Check if mouse has moved significantly or if we can't find the same file
        if let currentPath = FinderInteraction.getFileAtMousePosition(location) {
            // If different file or no file, hide immediately
            if currentPath != currentInfo.path {
                hideHoverWindow()
                currentFileInfo = nil
                displayTimer?.invalidate()
            }
        } else {
            // No file under cursor, hide immediately
            hideHoverWindow()
            currentFileInfo = nil
            displayTimer?.invalidate()
        }
    }

    private func handleMouseLocation(_ location: CGPoint) {
        guard isEnabled else { return }

        // Don't show hover window while dragging
        guard !mouseTracker.isDragging else { return }

        // Check if hovering over Finder and get file info
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: settings.hoverDelay, repeats: false) { [weak self] _ in
            self?.checkAndDisplayFileInfo(at: location)
        }
    }

    private func checkAndDisplayFileInfo(at location: CGPoint) {
        // Don't show hover window while dragging
        guard !mouseTracker.isDragging else { return }

        // Try to get file path at current location
        // This will return nil if user is renaming
        if let filePath = FinderInteraction.getFileAtMousePosition(location),
           let fileInfo = FileInfo.from(path: filePath) {

            // Only update if it's a different file
            if currentFileInfo?.path != fileInfo.path {
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
        hoverWindow?.hide()

        // Stop periodic check
        stopRenamingCheck()
    }

    private func startRenamingCheck() {
        // Stop existing timer
        renamingCheckTimer?.invalidate()

        // Check every 0.1 seconds if user is renaming
        renamingCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            if FinderInteraction.isRenamingFile() {
                self?.hideHoverWindow()
                self?.currentFileInfo = nil
            }
        }
    }

    private func stopRenamingCheck() {
        renamingCheckTimer?.invalidate()
        renamingCheckTimer = nil
    }

    private func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAccessibilityAlert()
            }
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
        cancellables.removeAll()
    }
}
