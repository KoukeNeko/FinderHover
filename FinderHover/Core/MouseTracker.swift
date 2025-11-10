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
    @Published var isDragging: Bool = false

    // Store all event monitors for proper cleanup
    private var globalMouseMovedMonitor: Any?
    private var localMouseMovedMonitor: Any?
    private var globalMouseDragMonitor: Any?
    private var localMouseDragMonitor: Any?
    private var globalMouseDownMonitor: Any?
    private var localMouseDownMonitor: Any?
    private var globalMouseUpMonitor: Any?
    private var localMouseUpMonitor: Any?

    func startTracking() {
        // Monitor global mouse movement
        globalMouseMovedMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
        }

        // Monitor local mouse movement
        localMouseMovedMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
            return event
        }

        // Monitor global drag events
        globalMouseDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.handleMouseDragged(event)
        }

        // Monitor local drag events
        localMouseDragMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.handleMouseDragged(event)
            return event
        }

        // Monitor global mouse down to track drag state
        globalMouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isDragging = true
            }
        }

        // Monitor local mouse down to track drag state
        localMouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            DispatchQueue.main.async {
                self?.isDragging = true
            }
            return event
        }

        // Monitor global mouse up to track drag state
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isDragging = false
            }
        }

        // Monitor local mouse up to track drag state
        localMouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { [weak self] event in
            DispatchQueue.main.async {
                self?.isDragging = false
            }
            return event
        }
    }

    func stopTracking() {
        // Remove all global monitors
        if let monitor = globalMouseMovedMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMovedMonitor = nil
        }
        if let monitor = globalMouseDragMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseDragMonitor = nil
        }
        if let monitor = globalMouseDownMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseDownMonitor = nil
        }
        if let monitor = globalMouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseUpMonitor = nil
        }

        // Remove all local monitors
        if let monitor = localMouseMovedMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseMovedMonitor = nil
        }
        if let monitor = localMouseDragMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseDragMonitor = nil
        }
        if let monitor = localMouseDownMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseDownMonitor = nil
        }
        if let monitor = localMouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseUpMonitor = nil
        }
    }

    private func handleMouseMoved(_ event: NSEvent) {
        let location = NSEvent.mouseLocation
        DispatchQueue.main.async {
            self.mouseLocation = location
        }
    }

    private func handleMouseDragged(_ event: NSEvent) {
        let location = NSEvent.mouseLocation
        DispatchQueue.main.async {
            self.mouseLocation = location
            self.isDragging = true
        }
    }


    deinit {
        stopTracking()
    }
}
