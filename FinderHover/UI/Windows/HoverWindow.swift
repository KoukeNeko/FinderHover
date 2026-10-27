//
//  HoverWindow.swift
//  FinderHover
//
//  Floating window that displays file information
//

import SwiftUI
import AppKit
import Combine

// MARK: - Notification for Option Key Release
extension Notification.Name {
    static let hoverWindowUnlocked = Notification.Name("hoverWindowUnlocked")
}

// MARK: - Key-capable borderless panel
/// A borderless NSPanel that can become key, allowing embedded text editors to receive focus.
class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

// MARK: - Shared State for Lock Mode
class HoverWindowState: ObservableObject {
    static let shared = HoverWindowState()
    @Published var isLocked: Bool = false
    @Published var copiedValue: String?  // For "Copied!" feedback
    @Published var isEditingNotes: Bool = false

    private init() {}

    /// Copy value to clipboard and show feedback
    /// - Parameters:
    ///   - value: The actual text to copy to clipboard
    ///   - key: Unique identifier for tracking which row was copied
    func copyToClipboard(_ value: String, key: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)

        // Show "Copied!" feedback briefly using the unique key
        copiedValue = key
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            if self?.copiedValue == key {
                self?.copiedValue = nil
            }
        }
    }
}

class HoverWindowController: NSWindowController {
    private var visualEffectView: NSVisualEffectView?
    private var flagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var keyDownMonitor: Any?
    private var mouseMovedMonitor: Any?
    private let windowState = HoverWindowState.shared

    /// Whether the window is locked (Option key is pressed)
    var isLocked: Bool {
        windowState.isLocked
    }

    convenience init() {
        // NSPanel with .nonactivatingPanel prevents FinderHover from becoming the active
        // application when the user clicks inside the popup (e.g. the Notes text editor).
        // Without this, clicking in the popup fires NSWorkspace.didActivateApplicationNotification
        // for FinderHover, which triggers appActivateObserver and dismisses the popup before
        // textDidBeginEditing has a chance to set isEditingNotes = true.
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Allow the panel to become key when it contains a text editor (Notes field),
        // but never make it the main window or steal app focus.
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false

        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.ignoresMouseEvents = true
        panel.hasShadow = true

        // Ensure no title bar or border is drawn
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden

        // Additional settings to prevent border artifacts on older macOS
        panel.isMovableByWindowBackground = false
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        self.init(window: panel)
    }

    func show(at position: CGPoint, with fileInfo: FileInfo) {
        guard let window = window else { return }

        let settings = AppSettings.shared

        // Create content view based on UI style
        let contentView: any View = settings.uiStyle == .windows
            ? AnyView(WindowsStyleHoverView(fileInfo: fileInfo))
            : AnyView(HoverContentView(fileInfo: fileInfo))

        let hostingView = NSHostingView(rootView: AnyView(contentView))

        // Calculate required size for the view
        let fittingSize = calculateViewSize(for: hostingView, maxWidth: settings.windowMaxWidth)

        // Setup window content with proper styling
        setupWindowContent(window: window, hostingView: hostingView, size: fittingSize, settings: settings)

        // Set window size
        window.setContentSize(fittingSize)

        // Position window intelligently near cursor
        positionWindow(window: window, at: position, settings: settings)

        window.orderFront(nil)

        // Start monitoring Option key
        startKeyMonitoring()
        // Start tracking mouse position to enable popup interaction
        startMouseTracking()
        // Immediately check if cursor is already inside the popup (no mouseMoved fires
        // if the popup appears under the cursor, so ignoresMouseEvents would stay true).
        updateMouseInteraction()
    }

    func hide() {
        // Don't hide if locked or editing notes
        guard !windowState.isLocked else { return }
        guard !windowState.isEditingNotes else { return }

        window?.orderOut(nil)
        stopKeyMonitoring()
        stopMouseTracking()
    }

    /// Force hide the window, ignoring lock state
    func forceHide() {
        windowState.isLocked = false
        windowState.copiedValue = nil
        windowState.isEditingNotes = false
        window?.ignoresMouseEvents = true
        window?.orderOut(nil)
        stopKeyMonitoring()
        stopMouseTracking()
    }

    // MARK: - Key Monitoring

    private func startKeyMonitoring() {
        // Avoid duplicate monitors
        stopKeyMonitoring()

        // Monitor Option key (flags changed) - global monitor for events outside the window
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        // Local monitor for events when window has focus (after clicking copy button)
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }

        // Monitor Escape key to hide window
        keyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 && self?.windowState.isLocked == true {  // 53 = Escape
                self?.forceHide()
            }
        }
    }

    private func stopKeyMonitoring() {
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
        if let monitor = localFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            localFlagsMonitor = nil
        }
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
            keyDownMonitor = nil
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let optionPressed = event.modifierFlags.contains(.option)

        if optionPressed && !windowState.isLocked {
            // Lock the window
            windowState.isLocked = true
            window?.ignoresMouseEvents = false  // Allow mouse interaction
        } else if !optionPressed && windowState.isLocked {
            // Option released - just unlock, let normal hover behavior decide visibility
            unlock()
        }
    }

    /// Unlock the window without hiding (let HoverManager decide visibility)
    private func unlock() {
        windowState.isLocked = false
        windowState.copiedValue = nil
        // Stay clickable while the cursor is still over the popup or notes are being edited
        updateMouseInteraction()
        // Notify HoverManager to re-check cursor position
        NotificationCenter.default.post(name: .hoverWindowUnlocked, object: nil)
    }

    // MARK: - Mouse Tracking (popup hover detection)

    private func startMouseTracking() {
        stopMouseTracking()
        mouseMovedMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            self?.updateMouseInteraction()
        }
    }

    private func stopMouseTracking() {
        if let monitor = mouseMovedMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMovedMonitor = nil
        }
    }

    /// Update ignoresMouseEvents based on whether the mouse is over the popup
    private func updateMouseInteraction() {
        guard let window = window, window.isVisible else { return }
        let mouseLocation = NSEvent.mouseLocation
        let isOverPopup = window.frame.contains(mouseLocation)

        // When the mouse leaves the popup while editing notes, resign first responder
        // so that textDidEndEditing fires and isEditingNotes is cleared. Cancel any
        // in-flight IME composition first: makeFirstResponder(nil) alone force-commits
        // half-composed marked text, which then leaks into the saved note.
        if !isOverPopup && !windowState.isLocked && windowState.isEditingNotes {
            if let editor = window.firstResponder as? NSTextView, editor.hasMarkedText() {
                editor.inputContext?.discardMarkedText()
            }
            window.makeFirstResponder(nil)
        }

        let shouldInteract = isOverPopup || windowState.isLocked || windowState.isEditingNotes
        window.ignoresMouseEvents = !shouldInteract
    }

    deinit {
        stopKeyMonitoring()
        stopMouseTracking()
    }

    // MARK: - Private Helper Methods

    /// Calculate the required size for the hosting view
    private func calculateViewSize(for hostingView: NSHostingView<AnyView>, maxWidth: Double) -> NSSize {
        // Set a width constraint for proper height calculation
        hostingView.frame = NSRect(x: 0, y: 0, width: maxWidth, height: 0)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        // Create temporary container to calculate size
        let tempContainer = NSView(frame: NSRect(
            x: 0,
            y: 0,
            width: maxWidth,
            height: Constants.WindowLayout.tempContainerHeight
        ))
        tempContainer.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: tempContainer.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: tempContainer.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: tempContainer.topAnchor)
        ])

        // Force layout
        tempContainer.layoutSubtreeIfNeeded()

        // Get the calculated size
        let fittingSize = hostingView.fittingSize

        // Remove from temp container and reset
        hostingView.removeFromSuperview()
        hostingView.translatesAutoresizingMaskIntoConstraints = true

        return fittingSize
    }

    /// Setup the window content with blur effect or solid background
    private func setupWindowContent(window: NSWindow, hostingView: NSHostingView<AnyView>, size: NSSize, settings: AppSettings) {
        let cornerRadius: CGFloat = settings.uiStyle == .windows
            ? Constants.WindowLayout.windowsCornerRadius
            : Constants.WindowLayout.macOSCornerRadius

        if #available(macOS 26, *), settings.enableLiquidGlass {
            setupLiquidGlassContent(window: window, hostingView: hostingView, size: size, cornerRadius: cornerRadius)
        } else if settings.enableBlur {
            setupBlurContent(window: window, hostingView: hostingView, size: size, cornerRadius: cornerRadius)
        } else {
            setupSolidContent(window: window, hostingView: hostingView, size: size, cornerRadius: cornerRadius, opacity: settings.windowOpacity)
        }
    }

    /// Setup window content with macOS 26+ Liquid Glass effect
    @available(macOS 26, *)
    private func setupLiquidGlassContent(window: NSWindow, hostingView: NSHostingView<AnyView>, size: NSSize, cornerRadius: CGFloat) {
        let glassView = NSGlassEffectView(frame: NSRect(origin: .zero, size: size))
        glassView.cornerRadius = cornerRadius
        glassView.autoresizingMask = [.width, .height]
        // Ensure the hosting view is transparent so the glass renders behind content
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = CGColor.clear
        hostingView.frame = glassView.bounds
        hostingView.autoresizingMask = [.width, .height]
        glassView.contentView = hostingView

        // Wrap the glass in a clear, rounded, clipping container. NSGlassEffectView does not
        // clip the borderless window's square corners — they show as a black edge when the
        // panel becomes key (e.g. focusing the Notes field) — and its own layer mask is reset
        // when the window resizes, so a plain clipping container (which the glass cannot reset)
        // is the robust fix.
        let clipContainer = NSView(frame: NSRect(origin: .zero, size: size))
        clipContainer.wantsLayer = true
        clipContainer.layer?.cornerRadius = cornerRadius
        clipContainer.layer?.masksToBounds = true
        clipContainer.addSubview(glassView)
        window.contentView = clipContainer
        self.visualEffectView = nil
    }

    /// Setup window content with blur effect
    private func setupBlurContent(window: NSWindow, hostingView: NSHostingView<AnyView>, size: NSSize, cornerRadius: CGFloat) {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let useLegacyBlurLayout = osVersion.majorVersion <= Constants.Compatibility.blurLayoutChangeVersion

        let effectView = NSVisualEffectView()
        effectView.state = .active
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow

        if useLegacyBlurLayout {
            // For macOS 15.x and earlier, use transparent container with clipping
            effectView.frame = NSRect(origin: .zero, size: size)
            hostingView.frame = effectView.bounds
            hostingView.autoresizingMask = [.width, .height]
            effectView.addSubview(hostingView)

            // Create transparent clipping container
            let containerView = NSView(frame: NSRect(origin: .zero, size: size))
            containerView.wantsLayer = true
            containerView.layer?.cornerRadius = cornerRadius
            containerView.layer?.masksToBounds = true

            // Add subtle border for macOS style
            if cornerRadius > 0 {
                containerView.layer?.borderWidth = Constants.WindowLayout.macOSBorderWidth
                containerView.layer?.borderColor = NSColor.systemGray.withAlphaComponent(0.5).cgColor
            } else {
                // Windows style: no border
                containerView.layer?.borderWidth = 0
                containerView.layer?.borderColor = nil
            }

            effectView.autoresizingMask = [.width, .height]
            containerView.addSubview(effectView)
            window.contentView = containerView
        } else {
            // macOS 16+ supports direct cornerRadius on NSVisualEffectView
            effectView.wantsLayer = true
            effectView.layer?.cornerRadius = cornerRadius
            effectView.layer?.masksToBounds = true
            effectView.frame = NSRect(origin: .zero, size: size)
            hostingView.frame = effectView.bounds
            hostingView.autoresizingMask = [.width, .height]
            effectView.addSubview(hostingView)
            window.contentView = effectView
        }

        self.visualEffectView = effectView
    }

    /// Setup window content with solid background (no blur)
    private func setupSolidContent(window: NSWindow, hostingView: NSHostingView<AnyView>, size: NSSize, cornerRadius: CGFloat, opacity: Double) {
        let containerView = NSView(frame: NSRect(origin: .zero, size: size))
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = cornerRadius
        containerView.layer?.masksToBounds = true
        containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(opacity).cgColor

        hostingView.frame = containerView.bounds
        containerView.addSubview(hostingView)
        window.contentView = containerView
    }

    /// Position window near cursor with intelligent screen edge detection
    private func positionWindow(window: NSWindow, at position: CGPoint, settings: AppSettings) {
        let offsetX: CGFloat = settings.windowOffsetX
        let offsetY: CGFloat = settings.windowOffsetY

        // Find the screen that contains the mouse position using a more robust method
        // NSMouseInRect can fail with certain monitor configurations
        let screen = NSScreen.screens.first { screen in
            let frame = screen.frame
            return position.x >= frame.minX && position.x < frame.maxX &&
                   position.y >= frame.minY && position.y < frame.maxY
        } ?? NSScreen.main

        guard let screen = screen else { return }

        let screenFrame = screen.visibleFrame

        // Calculate initial window position relative to cursor
        // Position below and to the right of the cursor by default
        var windowOrigin = CGPoint(
            x: position.x + offsetX,
            y: position.y - offsetY - window.frame.height
        )

        // Check right edge - flip to left side of cursor if needed
        if windowOrigin.x + window.frame.width > screenFrame.maxX {
            windowOrigin.x = position.x - offsetX - window.frame.width
        }

        // Check left edge - ensure window stays within screen
        if windowOrigin.x < screenFrame.minX {
            windowOrigin.x = screenFrame.minX + Constants.WindowLayout.screenEdgePadding
        }

        // Check bottom edge - flip to above cursor if needed
        if windowOrigin.y < screenFrame.minY {
            windowOrigin.y = position.y + offsetY
        }

        // Check top edge - ensure window stays within screen
        if windowOrigin.y + window.frame.height > screenFrame.maxY {
            windowOrigin.y = screenFrame.maxY - window.frame.height - Constants.WindowLayout.screenEdgePadding
        }

        window.setFrameOrigin(windowOrigin)
    }
}

// MARK: - Notes Storage (per-file xattr persistence)
enum NotesStorage {
    static let xattrKey = "com.finderhover.notes"

    /// Serial queue for xattr I/O. Saves are dispatched here immediately (no debounce) and
    /// run to completion independently of the popup's SwiftUI lifecycle — so a note is never
    /// lost when the popup tears down right after editing, while still keeping the blocking
    /// getxattr/setxattr syscalls off the main thread.
    static let ioQueue = DispatchQueue(label: "com.finderhover.notes.io", qos: .utility)

    enum StorageError: LocalizedError {
        case readFailed(path: String, code: Int32)
        case writeFailed(path: String, code: Int32)
        case deleteFailed(path: String, code: Int32)
        case tooLarge(path: String, byteCount: Int)

        var errorDescription: String? {
            switch self {
            case let .readFailed(path, code):
                let message = String(cString: strerror(code))
                return "getxattr failed for xattr \(NotesStorage.xattrKey) at \(path): [\(code)] \(message)"
            case let .writeFailed(path, code):
                let message = String(cString: strerror(code))
                return "setxattr failed for xattr \(NotesStorage.xattrKey) at \(path): [\(code)] \(message)"
            case let .deleteFailed(path, code):
                let message = String(cString: strerror(code))
                return "removexattr failed for xattr \(NotesStorage.xattrKey) at \(path): [\(code)] \(message)"
            case let .tooLarge(path, byteCount):
                return "note exceeds \(Constants.Notes.maxByteCount) bytes (\(byteCount)) at \(path)"
            }
        }
    }

    static func read(for path: String) throws -> String {
        // ERANGE re-probe loop: another writer may grow the value between the size
        // probe and the buffered fetch, so re-probe instead of trusting the first
        // size. Bounded by maxReadProbeRetries to avoid a livelock. (#25)
        for _ in 0...Constants.Notes.maxReadProbeRetries {
            let size = getxattr(path, xattrKey, nil, 0, 0, 0)
            guard size >= 0 else {
                let code = errno
                if code == ENOATTR { return "" }
                throw logAndReturn(.readFailed(path: path, code: code))
            }

            let cappedSize = min(size, Constants.Notes.maxByteCount)
            var buffer = [UInt8](repeating: 0, count: cappedSize)
            let result = getxattr(path, xattrKey, &buffer, cappedSize, 0, 0)
            if result >= 0 {
                return String(decoding: buffer.prefix(result), as: UTF8.self)
            }
            if errno == ERANGE { continue } // value grew between probe and fetch; re-probe
            throw logAndReturn(.readFailed(path: path, code: errno))
        }
        throw logAndReturn(.readFailed(path: path, code: ERANGE))
    }

    static func save(_ note: String, for path: String) throws {
        if note.isEmpty {
            try delete(for: path)
            return
        }

        let data = Data(note.utf8)
        guard data.count <= Constants.Notes.maxByteCount else {
            throw logAndReturn(.tooLarge(path: path, byteCount: data.count))
        }

        let result = data.withUnsafeBytes { bytes in
            setxattr(path, xattrKey, bytes.baseAddress, data.count, 0, 0)
        }

        guard result >= 0 else {
            throw logAndReturn(.writeFailed(path: path, code: errno))
        }
    }

    private static func delete(for path: String) throws {
        let result = removexattr(path, xattrKey, 0)
        if result < 0, errno != ENOATTR {
            throw logAndReturn(.deleteFailed(path: path, code: errno))
        }
    }

    private static func logAndReturn(_ error: StorageError) -> StorageError {
        Logger.error("Notes xattr operation failed", error: error, subsystem: .fileSystem)
        return error
    }
}

// MARK: - Notes Editor (plain-text NSTextView representable)
struct NotesEditorView: NSViewRepresentable {
    @Binding var text: String
    let fontSize: Double
    /// Reports the laid-out text height so the parent can grow the field to fit the content.
    var onHeightChange: (CGFloat) -> Void = { _ in }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false

        let textView = NSTextView(frame: .zero)
        textView.isRichText = false          // Plain text only — enforces Cmd+V as plain paste
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: fontSize)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 0, height: 2)
        textView.textContainer?.lineFragmentPadding = 0
        // Auto-grow: the text view sizes vertically to its content; the parent clamps the
        // visible height via .frame(height:) and the scroll view scrolls past the cap.
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.delegate = context.coordinator
        textView.string = text

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        // Only push *external* state into the live editor. While the user is typing
        // (a CJK composition leaves uncommitted marked text) or while this view owns
        // first responder, the NSTextView is the source of truth: overwriting `string`
        // would corrupt marked text and reset the undo stack. SwiftUI re-runs this on
        // every HoverWindowState change, so the guard must stay conservative.
        if !textView.isComposingOrEditing, textView.string != text {
            textView.string = text
        }
        textView.font = .systemFont(ofSize: fontSize)
        reportContentHeight(of: textView)
    }

    /// Measures the laid-out text height and reports it (deferred so we never mutate
    /// SwiftUI state during the view-update pass).
    private func reportContentHeight(of textView: NSTextView) {
        // Skip until the view has a real width, otherwise the text wraps per-character and
        // reports a wildly tall (wrong) height before layout settles.
        guard textView.bounds.width > 1,
              let layoutManager = textView.layoutManager,
              let container = textView.textContainer else { return }
        layoutManager.ensureLayout(for: container)
        let contentHeight = ceil(layoutManager.usedRect(for: container).height)
            + textView.textContainerInset.height * 2
        DispatchQueue.main.async { onHeightChange(contentHeight) }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NotesEditorView

        init(_ parent: NotesEditorView) { self.parent = parent }

        func textDidBeginEditing(_ notification: Notification) {
            HoverWindowState.shared.isEditingNotes = true
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textDidEndEditing(_ notification: Notification) {
            HoverWindowState.shared.isEditingNotes = false
        }
    }
}

// MARK: - NSTextView IME helpers
private extension NSTextView {
    /// True when this text view should be treated as the source of truth and left
    /// untouched by external state sync: either it has uncommitted IME marked text,
    /// or it is the active first responder in its window.
    var isComposingOrEditing: Bool {
        hasMarkedText() || window?.firstResponder === self
    }
}

// MARK: - Windows Style Hover View
struct WindowsStyleHoverView: View {
    let fileInfo: FileInfo
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // File name only (no icon)
            Text(fileInfo.name)
                .font(.system(size: settings.fontSize, weight: .regular))
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

            // Windows-style simple info display (no columns, all left-aligned)
            VStack(alignment: .leading, spacing: 0) {
                if settings.showFileType {
                    WindowsDetailRow(
                        label: "hover.windows.type".localized,
                        value: getFileTypeDescription(),
                        fontSize: settings.fontSize
                    )
                }

                if settings.showFileSize {
                    WindowsDetailRow(
                        label: "hover.windows.size".localized,
                        value: fileInfo.size == 0 ? "0 bytes" : fileInfo.formattedSize,
                        fontSize: settings.fontSize
                    )
                }

                if settings.showModificationDate {
                    WindowsDetailRow(
                        label: "hover.windows.dateModified".localized,
                        value: fileInfo.formattedModificationDate,
                        fontSize: settings.fontSize
                    )
                }
            }

            if let analysisNotice = fileInfo.analysisNotice {
                Text(analysisNotice.localizedText)
                    .font(.system(size: settings.fontSize - 1))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
        .padding(10)
        .frame(minWidth: 280, maxWidth: settings.windowMaxWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.clear)
    }

    private func getFileTypeDescription() -> String {
        return FileTypeDescriptor.description(
            fileExtension: fileInfo.fileExtension,
            isDirectory: fileInfo.isDirectory
        )
    }
}

// Windows-style detail row (no columns, all text left-aligned)
struct WindowsDetailRow: View {
    let label: String
    let value: String
    let fontSize: Double

    var body: some View {
        Text(label + ": " + value)
            .font(.system(size: fontSize))
            .foregroundColor(.primary)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
