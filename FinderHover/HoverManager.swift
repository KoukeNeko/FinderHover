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
    private var lastMouseLocation: CGPoint = .zero
    private let settings = AppSettings.shared

    init() {
        setupSubscriptions()
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
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] location in
                self?.handleMouseLocation(location)
            }
            .store(in: &cancellables)
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
    }

    private func checkIfShouldHide(at location: CGPoint) {
        // Only auto-hide if enabled in settings
        guard settings.autoHideEnabled else { return }

        // If window is showing and we have current file info
        guard let currentInfo = currentFileInfo else { return }

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

        // Check if hovering over Finder and get file info
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: settings.hoverDelay, repeats: false) { [weak self] _ in
            self?.checkAndDisplayFileInfo(at: location)
        }
    }

    private func checkAndDisplayFileInfo(at location: CGPoint) {
        // Try to get file path at current location
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
    }

    private func hideHoverWindow() {
        hoverWindow?.hide()
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
