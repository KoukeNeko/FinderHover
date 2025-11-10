//
//  MouseTracker.swift
//  FinderHover
//
//  Tracks mouse position and detects hover events
//

import Cocoa
import Combine

class MouseTracker: ObservableObject {
    @Published var mouseLocation: CGPoint = .zero
    @Published var isHoveringOverFinder: Bool = false
    @Published var isDragging: Bool = false

    private var mouseMovedEventMonitor: Any?
    private var mouseDragEventMonitor: Any?
    private var hoverTimer: Timer?
    private let hoverDelay: TimeInterval = 0.5

    func startTracking() {
        // Monitor global mouse movement
        mouseMovedEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
        }

        // Also monitor local events
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
            return event
        }

        // Monitor drag events (left mouse dragged)
        mouseDragEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.handleMouseDragged(event)
        }

        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.handleMouseDragged(event)
            return event
        }

        // Monitor mouse down/up to track drag state
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            DispatchQueue.main.async {
                self?.isDragging = true
            }
        }

        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            DispatchQueue.main.async {
                self?.isDragging = true
            }
            return event
        }

        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { [weak self] event in
            DispatchQueue.main.async {
                self?.isDragging = false
            }
        }

        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { [weak self] event in
            DispatchQueue.main.async {
                self?.isDragging = false
            }
            return event
        }
    }

    func stopTracking() {
        if let monitor = mouseMovedEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = mouseDragEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        hoverTimer?.invalidate()
    }

    private func handleMouseMoved(_ event: NSEvent) {
        let location = NSEvent.mouseLocation
        DispatchQueue.main.async {
            self.mouseLocation = location
        }

        // Reset hover timer
        hoverTimer?.invalidate()
        hoverTimer = Timer.scheduledTimer(withTimeInterval: hoverDelay, repeats: false) { [weak self] _ in
            self?.checkIfHoveringOverFinder()
        }
    }

    private func handleMouseDragged(_ event: NSEvent) {
        let location = NSEvent.mouseLocation
        DispatchQueue.main.async {
            self.mouseLocation = location
            self.isDragging = true
        }
    }

    private func checkIfHoveringOverFinder() {
        let mouseLocation = NSEvent.mouseLocation

        // Get the window under the cursor using accessibility API
        let systemWideElement = AXUIElementCreateSystemWide()

        var elementRef: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(
            systemWideElement,
            Float(mouseLocation.x),
            Float(NSScreen.main?.frame.height ?? 0 - mouseLocation.y),
            &elementRef
        )

        if result == .success, let element = elementRef {
            // Check if this is a Finder window
            var appRef: AnyObject?
            AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &appRef)

            if let app = appRef as! AXUIElement? {
                var pid: pid_t = 0
                AXUIElementGetPid(app, &pid)

                if let runningApp = NSRunningApplication(processIdentifier: pid),
                   runningApp.bundleIdentifier == "com.apple.finder" {
                    DispatchQueue.main.async {
                        self.isHoveringOverFinder = true
                    }
                    return
                }
            }
        }

        DispatchQueue.main.async {
            self.isHoveringOverFinder = false
        }
    }

    deinit {
        stopTracking()
    }
}
