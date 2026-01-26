//
//  HoverWindow.swift
//  FinderHover
//
//  Floating window that displays file information
//

import SwiftUI
import AppKit
import Combine
import QuickLookThumbnailing

// MARK: - Notification for Option Key Release
extension Notification.Name {
    static let hoverWindowUnlocked = Notification.Name("hoverWindowUnlocked")
}

// MARK: - Shared State for Lock Mode
class HoverWindowState: ObservableObject {
    static let shared = HoverWindowState()
    @Published var isLocked: Bool = false
    @Published var copiedValue: String?  // For "Copied!" feedback

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
    private let windowState = HoverWindowState.shared

    /// Whether the window is locked (Option key is pressed)
    var isLocked: Bool {
        windowState.isLocked
    }

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.ignoresMouseEvents = true
        window.hasShadow = true

        // Ensure no title bar or border is drawn
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        // Additional settings to prevent border artifacts on older macOS
        window.isMovableByWindowBackground = false
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        self.init(window: window)
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
    }

    func hide() {
        // Don't hide if locked
        guard !windowState.isLocked else { return }

        window?.orderOut(nil)
        stopKeyMonitoring()
    }

    /// Force hide the window, ignoring lock state
    func forceHide() {
        windowState.isLocked = false
        windowState.copiedValue = nil
        window?.ignoresMouseEvents = true
        window?.orderOut(nil)
        stopKeyMonitoring()
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
        window?.ignoresMouseEvents = true
        // Notify HoverManager to re-check cursor position
        NotificationCenter.default.post(name: .hoverWindowUnlocked, object: nil)
    }

    deinit {
        stopKeyMonitoring()
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

        if settings.enableBlur {
            setupBlurContent(window: window, hostingView: hostingView, size: size, cornerRadius: cornerRadius)
        } else {
            setupSolidContent(window: window, hostingView: hostingView, size: size, cornerRadius: cornerRadius, opacity: settings.windowOpacity)
        }
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

struct HoverContentView: View {
    let fileInfo: FileInfo
    @State private var isExpanded = false
    @State private var thumbnail: NSImage?
    @State private var thumbnailRequest: QLThumbnailGenerator.Request?
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject private var windowState = HoverWindowState.shared

    var body: some View {
        VStack(alignment: .leading, spacing: settings.compactMode ? 6 : 10) {
            // File icon and name
            HStack(spacing: settings.compactMode ? 8 : 12) {
                if settings.showIcon {
                    let iconSize = settings.compactMode
                        ? Constants.Thumbnail.compactIconSize
                        : Constants.Thumbnail.normalIconSize
                    Image(nsImage: thumbnail ?? fileInfo.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                        .onAppear {
                            // Load thumbnail asynchronously with cancellation support
                            thumbnailRequest = fileInfo.generateThumbnailAsync { image in
                                if let image = image {
                                    thumbnail = image
                                }
                            }
                        }
                        .onDisappear {
                            // Cancel pending thumbnail generation to prevent resource accumulation
                            if let request = thumbnailRequest {
                                FileInfo.cancelThumbnailGeneration(request)
                                thumbnailRequest = nil
                            }
                        }
                }

                VStack(alignment: .leading, spacing: settings.compactMode ? 2 : 4) {
                    Text(fileInfo.name)
                        .font(.system(size: settings.compactMode ? settings.fontSize : settings.fontSize + 2, weight: .semibold))
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(fileInfo.isDirectory ? "hover.fileType.folder".localized : (fileInfo.fileExtension?.uppercased() ?? "hover.fileType.file".localized))
                        .font(.system(size: settings.fontSize - 1))
                        .foregroundColor(.secondary)
                }
            }

            Divider()
                .background(Color.gray.opacity(0.3))

            // File details - displayed in order based on settings
            ForEach(settings.displayOrder) { item in
                displayItemView(for: item)
            }
        }
        .padding(settings.compactMode ? 10 : 14)
        .frame(minWidth: 320, maxWidth: settings.windowMaxWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.clear)
    }

    @ViewBuilder
    private func displayItemView(for item: DisplayItem) -> some View {
        switch item {
        case .fileType:
            if settings.showFileType {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "doc.text", label: "hover.label.type".localized, value: getFileTypeDescription(), fontSize: settings.fontSize)
                }
            }

        case .fileSize:
            if settings.showFileSize {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "archivebox", label: "hover.label.size".localized, value: fileInfo.formattedSize, fontSize: settings.fontSize)
                }
            }

        case .itemCount:
            if settings.showItemCount && fileInfo.isDirectory {
                if let count = fileInfo.itemCount {
                    let itemText = count == 1 ? "common.item".localized : "common.items".localized
                    VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                        DetailRow(icon: "number", label: "hover.label.items".localized, value: "\(count) \(itemText)", fontSize: settings.fontSize)
                    }
                }
            }

        case .creationDate:
            if settings.showCreationDate {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "calendar", label: "hover.label.created".localized, value: fileInfo.formattedCreationDate, fontSize: settings.fontSize)
                }
            }

        case .modificationDate:
            if settings.showModificationDate {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "clock", label: "hover.label.modified".localized, value: fileInfo.formattedModificationDate, fontSize: settings.fontSize)
                }
            }

        case .lastAccessDate:
            if settings.showLastAccessDate {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "eye", label: "hover.label.accessed".localized, value: fileInfo.formattedLastAccessDate, fontSize: settings.fontSize)
                }
            }

        case .permissions:
            if settings.showPermissions {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "lock.shield", label: "hover.label.mode".localized, value: fileInfo.formattedPermissions, fontSize: settings.fontSize)
                }
            }

        case .owner:
            if settings.showOwner {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "person", label: "hover.label.owner".localized, value: fileInfo.owner, fontSize: settings.fontSize)
                }
            }

        case .exif:
            if settings.showEXIF, let exif = fileInfo.exifData {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.exif.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showEXIFCamera, let camera = exif.camera {
                        DetailRow(icon: "camera", label: "hover.exif.camera".localized, value: camera, fontSize: settings.fontSize)
                    }
                    if settings.showEXIFLens, let lens = exif.lens {
                        DetailRow(icon: "camera.aperture", label: "hover.exif.lens".localized, value: lens, fontSize: settings.fontSize)
                    }
                    if settings.showEXIFSettings {
                        let settingsComponents = [
                            exif.focalLength,
                            exif.aperture,
                            exif.shutterSpeed,
                            exif.iso
                        ].compactMap { $0 }

                        if !settingsComponents.isEmpty {
                            DetailRow(icon: IconManager.Photo.settings, label: "hover.exif.settings".localized, value: settingsComponents.joined(separator: "  "), fontSize: settings.fontSize)
                        }
                    }
                    if settings.showEXIFDateTaken, let date = exif.dateTaken {
                        DetailRow(icon: IconManager.Photo.calendarClock, label: "hover.exif.taken".localized, value: date, fontSize: settings.fontSize)
                    }
                    if settings.showEXIFDimensions, let size = exif.imageSize {
                        DetailRow(icon: IconManager.Photo.dimensions, label: "hover.exif.dimensions".localized, value: size, fontSize: settings.fontSize)
                    }
                    if settings.showEXIFGPS, let gps = exif.gpsLocation {
                        DetailRow(icon: IconManager.Photo.location, label: "hover.exif.gps".localized, value: gps, fontSize: settings.fontSize)
                    }
                }
            }

        case .video:
            if settings.showVideo, let video = fileInfo.videoMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.video.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showVideoDuration, let duration = video.duration {
                        DetailRow(icon: IconManager.Video.duration, label: "hover.video.duration".localized, value: duration, fontSize: settings.fontSize)
                    }
                    if settings.showVideoResolution, let resolution = video.resolution {
                        DetailRow(icon: IconManager.Video.resolution, label: "hover.video.resolution".localized, value: resolution, fontSize: settings.fontSize)
                    }
                    if settings.showVideoCodec, let codec = video.codec {
                        DetailRow(icon: IconManager.Video.codec, label: "hover.video.codec".localized, value: codec, fontSize: settings.fontSize)
                    }
                    if settings.showVideoFrameRate, let frameRate = video.frameRate {
                        DetailRow(icon: IconManager.Video.frameRate, label: "hover.video.framerate".localized, value: frameRate, fontSize: settings.fontSize)
                    }
                    if settings.showVideoBitrate, let bitrate = video.bitrate {
                        DetailRow(icon: IconManager.Video.bitrate, label: "hover.video.bitrate".localized, value: bitrate, fontSize: settings.fontSize)
                    }
                    if settings.showVideoHDR, let hdrFormat = video.hdrFormat, hdrFormat != "SDR" {
                        DetailRow(icon: "sparkles", label: "hover.video.hdr".localized, value: hdrFormat, fontSize: settings.fontSize)
                    }
                }
            }

        case .audio:
            if settings.showAudio, let audio = fileInfo.audioMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.audio.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showAudioTitle, let title = audio.title {
                        DetailRow(icon: IconManager.Audio.songTitle, label: "hover.audio.songTitle".localized, value: title, fontSize: settings.fontSize)
                    }
                    if settings.showAudioArtist, let artist = audio.artist {
                        DetailRow(icon: IconManager.Audio.artist, label: "hover.audio.artist".localized, value: artist, fontSize: settings.fontSize)
                    }
                    if settings.showAudioAlbum, let album = audio.album {
                        DetailRow(icon: IconManager.Audio.album, label: "hover.audio.album".localized, value: album, fontSize: settings.fontSize)
                    }
                    if settings.showAudioGenre, let genre = audio.genre {
                        DetailRow(icon: IconManager.Audio.genre, label: "hover.audio.genre".localized, value: genre, fontSize: settings.fontSize)
                    }
                    if settings.showAudioYear, let year = audio.year {
                        DetailRow(icon: IconManager.Audio.year, label: "hover.audio.year".localized, value: year, fontSize: settings.fontSize)
                    }
                    if settings.showAudioDuration, let duration = audio.duration {
                        DetailRow(icon: IconManager.Audio.duration, label: "hover.audio.duration".localized, value: duration, fontSize: settings.fontSize)
                    }
                    if settings.showAudioBitrate, let bitrate = audio.bitrate {
                        DetailRow(icon: IconManager.Audio.bitrate, label: "hover.audio.bitrate".localized, value: bitrate, fontSize: settings.fontSize)
                    }
                    if settings.showAudioSampleRate, let sampleRate = audio.sampleRate {
                        DetailRow(icon: IconManager.Audio.sampleRate, label: "hover.audio.samplerate".localized, value: sampleRate, fontSize: settings.fontSize)
                    }
                    if let channels = audio.channels {
                        DetailRow(icon: IconManager.Audio.channels, label: "hover.audio.channels".localized, value: channels, fontSize: settings.fontSize)
                    }
                }
            }

        case .pdf:
            if settings.showPDF, let pdf = fileInfo.pdfMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.pdf.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showPDFPageCount, let pageCount = pdf.pageCount {
                        DetailRow(icon: "doc.text", label: "hover.pdf.pageCount".localized, value: "\(pageCount)", fontSize: settings.fontSize)
                    }
                    if settings.showPDFPageSize, let pageSize = pdf.pageSize {
                        DetailRow(icon: "ruler", label: "hover.pdf.pageSize".localized, value: pageSize, fontSize: settings.fontSize)
                    }
                    if settings.showPDFVersion, let version = pdf.version {
                        DetailRow(icon: "info.circle", label: "hover.pdf.version".localized, value: version, fontSize: settings.fontSize)
                    }
                    if settings.showPDFTitle, let title = pdf.title {
                        DetailRow(icon: "textformat", label: "hover.pdf.documentTitle".localized, value: title, fontSize: settings.fontSize)
                    }
                    if settings.showPDFAuthor, let author = pdf.author {
                        DetailRow(icon: "person", label: "hover.pdf.author".localized, value: author, fontSize: settings.fontSize)
                    }
                    if settings.showPDFSubject, let subject = pdf.subject {
                        DetailRow(icon: "text.alignleft", label: "hover.pdf.subject".localized, value: subject, fontSize: settings.fontSize)
                    }
                    if settings.showPDFCreator, let creator = pdf.creator {
                        DetailRow(icon: "app", label: "hover.pdf.creator".localized, value: creator, fontSize: settings.fontSize)
                    }
                    if settings.showPDFProducer, let producer = pdf.producer {
                        DetailRow(icon: "gearshape", label: "hover.pdf.producer".localized, value: producer, fontSize: settings.fontSize)
                    }
                    if settings.showPDFCreationDate, let creationDate = pdf.creationDate {
                        DetailRow(icon: "calendar", label: "hover.pdf.creationDate".localized, value: creationDate, fontSize: settings.fontSize)
                    }
                    if settings.showPDFModificationDate, let modificationDate = pdf.modificationDate {
                        DetailRow(icon: "clock", label: "hover.pdf.modificationDate".localized, value: modificationDate, fontSize: settings.fontSize)
                    }
                    if settings.showPDFKeywords, let keywords = pdf.keywords {
                        DetailRow(icon: "tag", label: "hover.pdf.keywords".localized, value: keywords, fontSize: settings.fontSize)
                    }
                    if settings.showPDFEncrypted, let isEncrypted = pdf.isEncrypted, isEncrypted {
                        DetailRow(icon: "lock.fill", label: "hover.pdf.encrypted".localized, value: "Yes", fontSize: settings.fontSize)
                    }
                }
            }

        case .office:
            if settings.showOffice, let office = fileInfo.officeMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.office.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showOfficeTitle, let title = office.title {
                        DetailRow(icon: "textformat", label: "hover.office.documentTitle".localized, value: title, fontSize: settings.fontSize)
                    }
                    if settings.showOfficeAuthor, let author = office.author {
                        DetailRow(icon: "person", label: "hover.office.author".localized, value: author, fontSize: settings.fontSize)
                    }
                    if settings.showOfficeSubject, let subject = office.subject {
                        DetailRow(icon: "text.alignleft", label: "hover.office.subject".localized, value: subject, fontSize: settings.fontSize)
                    }
                    if settings.showOfficePageCount, let pageCount = office.pageCount {
                        DetailRow(icon: "doc.text", label: "hover.office.pageCount".localized, value: "\(pageCount)", fontSize: settings.fontSize)
                    }
                    if settings.showOfficeWordCount, let wordCount = office.wordCount {
                        DetailRow(icon: "textformat.size", label: "hover.office.wordCount".localized, value: "\(wordCount)", fontSize: settings.fontSize)
                    }
                    if settings.showOfficeSheetCount, let sheetCount = office.sheetCount {
                        DetailRow(icon: "tablecells", label: "hover.office.sheetCount".localized, value: "\(sheetCount)", fontSize: settings.fontSize)
                    }
                    if settings.showOfficeSlideCount, let slideCount = office.slideCount {
                        DetailRow(icon: "rectangle.stack", label: "hover.office.slideCount".localized, value: "\(slideCount)", fontSize: settings.fontSize)
                    }
                    if settings.showOfficeKeywords, let keywords = office.keywords {
                        DetailRow(icon: "tag", label: "hover.office.keywords".localized, value: keywords, fontSize: settings.fontSize)
                    }
                    if settings.showOfficeComment, let comment = office.comment {
                        DetailRow(icon: "text.bubble", label: "hover.office.comment".localized, value: comment, fontSize: settings.fontSize)
                    }
                    if settings.showOfficeLastModifiedBy, let lastModifiedBy = office.lastModifiedBy {
                        DetailRow(icon: "person.crop.circle", label: "hover.office.lastModifiedBy".localized, value: lastModifiedBy, fontSize: settings.fontSize)
                    }
                    if settings.showOfficeCreationDate, let creationDate = office.creationDate {
                        DetailRow(icon: "calendar", label: "hover.office.creationDate".localized, value: creationDate, fontSize: settings.fontSize)
                    }
                    if settings.showOfficeModificationDate, let modificationDate = office.modificationDate {
                        DetailRow(icon: "clock", label: "hover.office.modificationDate".localized, value: modificationDate, fontSize: settings.fontSize)
                    }
                    if settings.showOfficeCompany, let company = office.company {
                        DetailRow(icon: "building.2", label: "hover.office.company".localized, value: company, fontSize: settings.fontSize)
                    }
                    if settings.showOfficeCategory, let category = office.category {
                        DetailRow(icon: "folder", label: "hover.office.category".localized, value: category, fontSize: settings.fontSize)
                    }
                }
            }

        case .archive:
            if settings.showArchive, let archive = fileInfo.archiveMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.archive.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showArchiveFormat, let format = archive.format {
                        DetailRow(icon: "doc.zipper", label: "hover.archive.format".localized, value: format, fontSize: settings.fontSize)
                    }
                    if settings.showArchiveFileCount, let fileCount = archive.fileCount {
                        DetailRow(icon: "doc.on.doc", label: "hover.archive.fileCount".localized, value: "\(fileCount)", fontSize: settings.fontSize)
                    }
                    if settings.showArchiveUncompressedSize, let uncompressedSize = archive.uncompressedSize {
                        let sizeStr = ByteCountFormatter.string(fromByteCount: Int64(uncompressedSize), countStyle: .file)
                        DetailRow(icon: "arrow.up.doc", label: "hover.archive.uncompressedSize".localized, value: sizeStr, fontSize: settings.fontSize)
                    }
                    if settings.showArchiveCompressionRatio, let compressionRatio = archive.compressionRatio {
                        DetailRow(icon: "chart.bar", label: "hover.archive.compressionRatio".localized, value: String(format: "%.1f%%", compressionRatio), fontSize: settings.fontSize)
                    }
                    if settings.showArchiveEncrypted, let isEncrypted = archive.isEncrypted, isEncrypted {
                        DetailRow(icon: "lock.fill", label: "hover.archive.encrypted".localized, value: "hover.archive.yes".localized, fontSize: settings.fontSize)
                    }
                }
            }

        case .ebook:
            if settings.showEbook, let ebook = fileInfo.ebookMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.ebook.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showEbookTitle, let title = ebook.title {
                        DetailRow(icon: "book.closed", label: "hover.ebook.bookTitle".localized, value: title, fontSize: settings.fontSize)
                    }
                    if settings.showEbookAuthor, let author = ebook.author {
                        DetailRow(icon: "person", label: "hover.ebook.author".localized, value: author, fontSize: settings.fontSize)
                    }
                    if settings.showEbookPublisher, let publisher = ebook.publisher {
                        DetailRow(icon: "building.2", label: "hover.ebook.publisher".localized, value: publisher, fontSize: settings.fontSize)
                    }
                    if settings.showEbookPublicationDate, let publicationDate = ebook.publicationDate {
                        DetailRow(icon: "calendar", label: "hover.ebook.publicationDate".localized, value: publicationDate, fontSize: settings.fontSize)
                    }
                    if settings.showEbookISBN, let isbn = ebook.isbn {
                        DetailRow(icon: "barcode", label: "hover.ebook.isbn".localized, value: isbn, fontSize: settings.fontSize)
                    }
                    if settings.showEbookLanguage, let language = ebook.language {
                        DetailRow(icon: "globe", label: "hover.ebook.language".localized, value: language, fontSize: settings.fontSize)
                    }
                    if settings.showEbookDescription, let description = ebook.description {
                        DetailRow(icon: "text.alignleft", label: "hover.ebook.description".localized, value: description, fontSize: settings.fontSize)
                    }
                    if settings.showEbookPageCount, let pageCount = ebook.pageCount {
                        DetailRow(icon: "doc.text", label: "hover.ebook.pageCount".localized, value: "\(pageCount)", fontSize: settings.fontSize)
                    }
                }
            }

        case .code:
            if settings.showCode, let code = fileInfo.codeMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.code.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showCodeLanguage, let language = code.language {
                        DetailRow(icon: "chevron.left.forwardslash.chevron.right", label: "hover.code.language".localized, value: language, fontSize: settings.fontSize)
                    }
                    if settings.showCodeLineCount, let lineCount = code.lineCount {
                        DetailRow(icon: "number", label: "hover.code.lineCount".localized, value: "\(lineCount)", fontSize: settings.fontSize)
                    }
                    if settings.showCodeLines, let codeLines = code.codeLines {
                        DetailRow(icon: "curlybraces", label: "hover.code.codeLines".localized, value: "\(codeLines)", fontSize: settings.fontSize)
                    }
                    if settings.showCodeCommentLines, let commentLines = code.commentLines {
                        DetailRow(icon: "text.bubble", label: "hover.code.commentLines".localized, value: "\(commentLines)", fontSize: settings.fontSize)
                    }
                    if settings.showCodeBlankLines, let blankLines = code.blankLines {
                        DetailRow(icon: "minus", label: "hover.code.blankLines".localized, value: "\(blankLines)", fontSize: settings.fontSize)
                    }
                    if settings.showCodeEncoding, let encoding = code.encoding {
                        DetailRow(icon: "textformat.abc", label: "hover.code.encoding".localized, value: encoding, fontSize: settings.fontSize)
                    }
                }
            }

        case .font:
            if settings.showFont, let font = fileInfo.fontMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.font.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showFontName, let fontName = font.fontName {
                        DetailRow(icon: "textformat", label: "hover.font.name".localized, value: fontName, fontSize: settings.fontSize)
                    }
                    if settings.showFontFamily, let fontFamily = font.fontFamily {
                        DetailRow(icon: "textformat.alt", label: "hover.font.family".localized, value: fontFamily, fontSize: settings.fontSize)
                    }
                    if settings.showFontStyle, let fontStyle = font.fontStyle {
                        DetailRow(icon: "italic", label: "hover.font.style".localized, value: fontStyle, fontSize: settings.fontSize)
                    }
                    if settings.showFontVersion, let version = font.version {
                        DetailRow(icon: "number", label: "hover.font.version".localized, value: version, fontSize: settings.fontSize)
                    }
                    if settings.showFontDesigner, let designer = font.designer {
                        DetailRow(icon: "person", label: "hover.font.designer".localized, value: designer, fontSize: settings.fontSize)
                    }
                    if settings.showFontCopyright, let copyright = font.copyright {
                        DetailRow(icon: "c.circle", label: "hover.font.copyright".localized, value: copyright, fontSize: settings.fontSize)
                    }
                    if settings.showFontGlyphCount, let glyphCount = font.glyphCount {
                        DetailRow(icon: "character.textbox", label: "hover.font.glyphCount".localized, value: "\(glyphCount)", fontSize: settings.fontSize)
                    }
                }
            }

        case .diskImage:
            if settings.showDiskImage, let diskImage = fileInfo.diskImageMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.diskImage.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showDiskImageFormat, let format = diskImage.format {
                        DetailRow(icon: "opticaldiscdrive", label: "hover.diskImage.format".localized, value: format, fontSize: settings.fontSize)
                    }
                    if settings.showDiskImageTotalSize, let totalSize = diskImage.totalSize {
                        let sizeStr = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
                        DetailRow(icon: "externaldrive", label: "hover.diskImage.totalSize".localized, value: sizeStr, fontSize: settings.fontSize)
                    }
                    if settings.showDiskImageCompressedSize, let compressedSize = diskImage.compressedSize {
                        let sizeStr = ByteCountFormatter.string(fromByteCount: compressedSize, countStyle: .file)
                        DetailRow(icon: "arrow.down.circle", label: "hover.diskImage.compressedSize".localized, value: sizeStr, fontSize: settings.fontSize)
                    }
                    if settings.showDiskImageCompressionRatio, let ratio = diskImage.compressionRatio {
                        DetailRow(icon: "chart.bar", label: "hover.diskImage.compressionRatio".localized, value: ratio, fontSize: settings.fontSize)
                    }
                    if settings.showDiskImageEncrypted, let isEncrypted = diskImage.isEncrypted {
                        let status = isEncrypted ? "Yes" : "No"
                        DetailRow(icon: "lock.shield", label: "hover.diskImage.encrypted".localized, value: status, fontSize: settings.fontSize)
                    }
                    if settings.showDiskImagePartitionScheme, let scheme = diskImage.partitionScheme {
                        DetailRow(icon: "square.split.2x2", label: "hover.diskImage.partitionScheme".localized, value: scheme, fontSize: settings.fontSize)
                    }
                    if settings.showDiskImageFileSystem, let fileSystem = diskImage.fileSystem {
                        DetailRow(icon: "doc.text", label: "hover.diskImage.fileSystem".localized, value: fileSystem, fontSize: settings.fontSize)
                    }
                }
            }

        case .vectorGraphics:
            if settings.showVectorGraphics, let vectorGraphics = fileInfo.vectorGraphicsMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.vectorGraphics.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showVectorGraphicsFormat, let format = vectorGraphics.format {
                        DetailRow(icon: "paintbrush.pointed", label: "hover.vectorGraphics.format".localized, value: format, fontSize: settings.fontSize)
                    }
                    if settings.showVectorGraphicsDimensions, let dimensions = vectorGraphics.dimensions {
                        DetailRow(icon: "arrow.up.left.and.arrow.down.right", label: "hover.vectorGraphics.dimensions".localized, value: dimensions, fontSize: settings.fontSize)
                    }
                    if settings.showVectorGraphicsViewBox, let viewBox = vectorGraphics.viewBox {
                        DetailRow(icon: "rectangle.dashed", label: "hover.vectorGraphics.viewBox".localized, value: viewBox, fontSize: settings.fontSize)
                    }
                    if settings.showVectorGraphicsElementCount, let elementCount = vectorGraphics.elementCount {
                        DetailRow(icon: "square.stack.3d.up", label: "hover.vectorGraphics.elementCount".localized, value: "\(elementCount)", fontSize: settings.fontSize)
                    }
                    if settings.showVectorGraphicsColorMode, let colorMode = vectorGraphics.colorMode {
                        DetailRow(icon: "paintpalette", label: "hover.vectorGraphics.colorMode".localized, value: colorMode, fontSize: settings.fontSize)
                    }
                    if settings.showVectorGraphicsCreator, let creator = vectorGraphics.creator {
                        DetailRow(icon: "hammer", label: "hover.vectorGraphics.creator".localized, value: creator, fontSize: settings.fontSize)
                    }
                    if settings.showVectorGraphicsVersion, let version = vectorGraphics.version {
                        DetailRow(icon: "number", label: "hover.vectorGraphics.version".localized, value: version, fontSize: settings.fontSize)
                    }
                }
            }

        case .subtitle:
            if settings.showSubtitle, let subtitle = fileInfo.subtitleMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.subtitle.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showSubtitleFormat, let format = subtitle.format {
                        DetailRow(icon: "captions.bubble", label: "hover.subtitle.format".localized, value: format, fontSize: settings.fontSize)
                    }
                    if settings.showSubtitleEncoding, let encoding = subtitle.encoding {
                        DetailRow(icon: "textformat.abc", label: "hover.subtitle.encoding".localized, value: encoding, fontSize: settings.fontSize)
                    }
                    if settings.showSubtitleEntryCount, let entryCount = subtitle.entryCount {
                        DetailRow(icon: "list.number", label: "hover.subtitle.entryCount".localized, value: "\(entryCount)", fontSize: settings.fontSize)
                    }
                    if settings.showSubtitleDuration, let duration = subtitle.duration {
                        DetailRow(icon: "clock", label: "hover.subtitle.duration".localized, value: duration, fontSize: settings.fontSize)
                    }
                    if settings.showSubtitleLanguage, let language = subtitle.language {
                        DetailRow(icon: "globe", label: "hover.subtitle.language".localized, value: language, fontSize: settings.fontSize)
                    }
                    if settings.showSubtitleFrameRate, let frameRate = subtitle.frameRate {
                        DetailRow(icon: "film", label: "hover.subtitle.frameRate".localized, value: frameRate, fontSize: settings.fontSize)
                    }
                    if settings.showSubtitleFormatting, let hasFormatting = subtitle.hasFormatting {
                        let status = hasFormatting ? "Yes" : "No"
                        DetailRow(icon: "textformat", label: "hover.subtitle.hasFormatting".localized, value: status, fontSize: settings.fontSize)
                    }
                }
            }

        case .html:
            if settings.showHTML, let html = fileInfo.htmlMetadata, html.hasData {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.html.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showHTMLTitle, let title = html.title {
                        DetailRow(icon: "textformat", label: "hover.html.pageTitle".localized, value: title, fontSize: settings.fontSize)
                    }
                    if settings.showHTMLDescription, let desc = html.description {
                        DetailRow(icon: "text.alignleft", label: "hover.html.description".localized, value: desc, fontSize: settings.fontSize)
                    }
                    if settings.showHTMLCharset, let charset = html.charset {
                        DetailRow(icon: "textformat.abc", label: "hover.html.charset".localized, value: charset, fontSize: settings.fontSize)
                    }
                    if settings.showHTMLOpenGraph {
                        if let ogTitle = html.ogTitle {
                            DetailRow(icon: "square.and.arrow.up", label: "hover.html.ogTitle".localized, value: ogTitle, fontSize: settings.fontSize)
                        }
                        if let ogDesc = html.ogDescription {
                            DetailRow(icon: "square.and.arrow.up", label: "hover.html.ogDescription".localized, value: ogDesc, fontSize: settings.fontSize)
                        }
                    }
                    if settings.showHTMLTwitterCard, let twitterCard = html.twitterCard {
                        DetailRow(icon: "bubble.left", label: "hover.html.twitterCard".localized, value: twitterCard, fontSize: settings.fontSize)
                    }
                    if settings.showHTMLKeywords, let keywords = html.keywords {
                        DetailRow(icon: "tag", label: "hover.html.keywords".localized, value: keywords, fontSize: settings.fontSize)
                    }
                    if settings.showHTMLAuthor, let author = html.author {
                        DetailRow(icon: "person", label: "hover.html.author".localized, value: author, fontSize: settings.fontSize)
                    }
                    if settings.showHTMLLanguage, let language = html.language {
                        DetailRow(icon: "globe", label: "hover.html.language".localized, value: language, fontSize: settings.fontSize)
                    }
                }
            }

        case .imageExtended:
            if settings.showImageExtended, let imageExt = fileInfo.imageExtendedMetadata, imageExt.hasData {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.imageExtended.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showImageCopyright, let copyright = imageExt.copyright {
                        DetailRow(icon: "c.circle", label: "hover.imageExtended.copyright".localized, value: copyright, fontSize: settings.fontSize)
                    }
                    if settings.showImageCreator, let creator = imageExt.creator {
                        DetailRow(icon: "person", label: "hover.imageExtended.creator".localized, value: creator, fontSize: settings.fontSize)
                    }
                    if settings.showImageKeywords, let keywords = imageExt.keywords {
                        DetailRow(icon: "tag", label: "hover.imageExtended.keywords".localized, value: keywords, fontSize: settings.fontSize)
                    }
                    if settings.showImageRating, let rating = imageExt.rating {
                        let stars = String(repeating: "★", count: rating) + String(repeating: "☆", count: 5 - rating)
                        DetailRow(icon: "star", label: "hover.imageExtended.rating".localized, value: stars, fontSize: settings.fontSize)
                    }
                    if settings.showImageCreatorTool, let tool = imageExt.creatorTool {
                        DetailRow(icon: "wrench.and.screwdriver", label: "hover.imageExtended.creatorTool".localized, value: tool, fontSize: settings.fontSize)
                    }
                    if settings.showImageDescription, let desc = imageExt.description {
                        DetailRow(icon: "text.alignleft", label: "hover.imageExtended.description".localized, value: desc, fontSize: settings.fontSize)
                    }
                    if settings.showImageHeadline, let headline = imageExt.headline {
                        DetailRow(icon: "textformat", label: "hover.imageExtended.headline".localized, value: headline, fontSize: settings.fontSize)
                    }
                }
            }

        case .markdown:
            if settings.showMarkdown, let md = fileInfo.markdownMetadata, md.hasData {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.markdown.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showMarkdownFrontmatter, let hasFm = md.hasFrontmatter {
                        let fmStatus = hasFm ? (md.frontmatterFormat ?? "Yes") : "No"
                        DetailRow(icon: "doc.text", label: "hover.markdown.frontmatter".localized, value: fmStatus, fontSize: settings.fontSize)
                    }
                    if settings.showMarkdownTitle, let title = md.title {
                        DetailRow(icon: "textformat", label: "hover.markdown.mdTitle".localized, value: title, fontSize: settings.fontSize)
                    }
                    if settings.showMarkdownWordCount, let wordCount = md.wordCount {
                        DetailRow(icon: "character.cursor.ibeam", label: "hover.markdown.wordCount".localized, value: "\(wordCount)", fontSize: settings.fontSize)
                    }
                    if settings.showMarkdownHeadingCount, let headingCount = md.headingCount {
                        DetailRow(icon: "number", label: "hover.markdown.headingCount".localized, value: "\(headingCount)", fontSize: settings.fontSize)
                    }
                    if settings.showMarkdownLinkCount, let linkCount = md.linkCount {
                        DetailRow(icon: "link", label: "hover.markdown.linkCount".localized, value: "\(linkCount)", fontSize: settings.fontSize)
                    }
                    if settings.showMarkdownImageCount, let imageCount = md.imageCount {
                        DetailRow(icon: "photo", label: "hover.markdown.imageCount".localized, value: "\(imageCount)", fontSize: settings.fontSize)
                    }
                    if settings.showMarkdownCodeBlockCount, let codeBlockCount = md.codeBlockCount {
                        DetailRow(icon: "chevron.left.forwardslash.chevron.right", label: "hover.markdown.codeBlockCount".localized, value: "\(codeBlockCount)", fontSize: settings.fontSize)
                    }
                }
            }

        case .config:
            if settings.showConfig, let config = fileInfo.configMetadata, config.hasData {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.config.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showConfigFormat, let format = config.format {
                        DetailRow(icon: "doc.text", label: "hover.config.format".localized, value: format, fontSize: settings.fontSize)
                    }
                    if settings.showConfigValid, let isValid = config.isValid {
                        let status = isValid ? "hover.config.yes".localized : "hover.config.no".localized
                        DetailRow(icon: "checkmark.circle", label: "hover.config.isValid".localized, value: status, fontSize: settings.fontSize)
                    }
                    if settings.showConfigKeyCount, let keyCount = config.keyCount {
                        DetailRow(icon: "number", label: "hover.config.keyCount".localized, value: "\(keyCount)", fontSize: settings.fontSize)
                    }
                    if settings.showConfigMaxDepth, let maxDepth = config.maxDepth {
                        DetailRow(icon: "arrow.down.right", label: "hover.config.maxDepth".localized, value: "\(maxDepth)", fontSize: settings.fontSize)
                    }
                    if settings.showConfigHasComments, let hasComments = config.hasComments {
                        let status = hasComments ? "hover.config.yes".localized : "hover.config.no".localized
                        DetailRow(icon: "text.bubble", label: "hover.config.hasComments".localized, value: status, fontSize: settings.fontSize)
                    }
                    if settings.showConfigEncoding, let encoding = config.encoding {
                        DetailRow(icon: "textformat.abc", label: "hover.config.encoding".localized, value: encoding, fontSize: settings.fontSize)
                    }
                }
            }

        case .psd:
            if settings.showPSD, let psd = fileInfo.psdMetadata, psd.hasData {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.psd.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showPSDLayerCount, let layerCount = psd.layerCount {
                        DetailRow(icon: "square.stack.3d.up", label: "hover.psd.layerCount".localized, value: "\(layerCount)", fontSize: settings.fontSize)
                    }
                    if settings.showPSDColorMode, let colorMode = psd.colorMode {
                        DetailRow(icon: "paintpalette", label: "hover.psd.colorMode".localized, value: colorMode, fontSize: settings.fontSize)
                    }
                    if settings.showPSDBitDepth, let bitDepth = psd.bitDepth {
                        DetailRow(icon: "number", label: "hover.psd.bitDepth".localized, value: "\(bitDepth) bit", fontSize: settings.fontSize)
                    }
                    if settings.showPSDResolution, let resolution = psd.resolution {
                        DetailRow(icon: "square.dashed", label: "hover.psd.resolution".localized, value: resolution, fontSize: settings.fontSize)
                    }
                    if settings.showPSDTransparency, let hasTransparency = psd.hasTransparency {
                        let status = hasTransparency ? "Yes" : "No"
                        DetailRow(icon: "checkerboard.rectangle", label: "hover.psd.transparency".localized, value: status, fontSize: settings.fontSize)
                    }
                    if settings.showPSDDimensions, let dimensions = psd.dimensions {
                        DetailRow(icon: "aspectratio", label: "hover.psd.dimensions".localized, value: dimensions, fontSize: settings.fontSize)
                    }
                }
            }

        case .executable:
            if settings.showExecutable, let exe = fileInfo.executableMetadata, exe.hasData {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.executable.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showExecutableArchitecture, let arch = exe.architecture {
                        DetailRow(icon: "cpu", label: "hover.executable.architecture".localized, value: arch, fontSize: settings.fontSize)
                    }
                    if settings.showExecutableCodeSigned, let isSigned = exe.isCodeSigned {
                        let status = isSigned ? "Yes" : "No"
                        DetailRow(icon: "checkmark.seal", label: "hover.executable.codeSigned".localized, value: status, fontSize: settings.fontSize)
                    }
                    if settings.showExecutableSigningAuthority, let authority = exe.signingAuthority {
                        DetailRow(icon: "signature", label: "hover.executable.signingAuthority".localized, value: authority, fontSize: settings.fontSize)
                    }
                    if settings.showExecutableMinimumOS, let minOS = exe.minimumOS {
                        DetailRow(icon: "desktopcomputer", label: "hover.executable.minimumOS".localized, value: minOS, fontSize: settings.fontSize)
                    }
                    if settings.showExecutableSDKVersion, let sdk = exe.sdkVersion {
                        DetailRow(icon: "wrench.and.screwdriver", label: "hover.executable.sdkVersion".localized, value: sdk, fontSize: settings.fontSize)
                    }
                    if settings.showExecutableFileType, let fileType = exe.fileType {
                        DetailRow(icon: "doc", label: "hover.executable.fileType".localized, value: fileType, fontSize: settings.fontSize)
                    }
                }
            }

        case .appBundle:
            if settings.showAppBundle, let app = fileInfo.appBundleMetadata, app.hasData {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.appBundle.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showAppBundleID, let bundleID = app.bundleID {
                        DetailRow(icon: "app", label: "hover.appBundle.bundleID".localized, value: bundleID, fontSize: settings.fontSize)
                    }
                    if settings.showAppBundleVersion, let version = app.version {
                        DetailRow(icon: "number", label: "hover.appBundle.version".localized, value: version, fontSize: settings.fontSize)
                    }
                    if settings.showAppBundleBuildNumber, let build = app.buildNumber {
                        DetailRow(icon: "hammer", label: "hover.appBundle.buildNumber".localized, value: build, fontSize: settings.fontSize)
                    }
                    if settings.showAppBundleMinimumOS, let minOS = app.minimumOS {
                        DetailRow(icon: "desktopcomputer", label: "hover.appBundle.minimumOS".localized, value: minOS, fontSize: settings.fontSize)
                    }
                    if settings.showAppBundleCategory, let category = app.category {
                        DetailRow(icon: "folder", label: "hover.appBundle.category".localized, value: category, fontSize: settings.fontSize)
                    }
                    if settings.showAppBundleCopyright, let copyright = app.copyright {
                        DetailRow(icon: "c.circle", label: "hover.appBundle.copyright".localized, value: copyright, fontSize: settings.fontSize)
                    }
                    if settings.showAppBundleCodeSigned, let isSigned = app.isCodeSigned {
                        let status = isSigned ? "Yes" : "No"
                        DetailRow(icon: "checkmark.seal", label: "hover.appBundle.codeSigned".localized, value: status, fontSize: settings.fontSize)
                    }
                    if settings.showAppBundleEntitlements, let hasEntitlements = app.hasEntitlements {
                        let status = hasEntitlements ? "Yes" : "No"
                        DetailRow(icon: "lock.shield", label: "hover.appBundle.entitlements".localized, value: status, fontSize: settings.fontSize)
                    }
                }
            }

        case .sqlite:
            if settings.showSQLite, let db = fileInfo.sqliteMetadata, db.hasData {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.sqlite.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showSQLiteTableCount, let tableCount = db.tableCount {
                        DetailRow(icon: "tablecells", label: "hover.sqlite.tableCount".localized, value: "\(tableCount)", fontSize: settings.fontSize)
                    }
                    if settings.showSQLiteIndexCount, let indexCount = db.indexCount {
                        DetailRow(icon: "list.number", label: "hover.sqlite.indexCount".localized, value: "\(indexCount)", fontSize: settings.fontSize)
                    }
                    if settings.showSQLiteTriggerCount, let triggerCount = db.triggerCount {
                        DetailRow(icon: "bolt", label: "hover.sqlite.triggerCount".localized, value: "\(triggerCount)", fontSize: settings.fontSize)
                    }
                    if settings.showSQLiteViewCount, let viewCount = db.viewCount {
                        DetailRow(icon: "eye", label: "hover.sqlite.viewCount".localized, value: "\(viewCount)", fontSize: settings.fontSize)
                    }
                    if settings.showSQLiteTotalRows, let totalRows = db.totalRows {
                        DetailRow(icon: "number", label: "hover.sqlite.totalRows".localized, value: "\(totalRows)", fontSize: settings.fontSize)
                    }
                    if settings.showSQLiteSchemaVersion, let schemaVersion = db.schemaVersion {
                        DetailRow(icon: "tag", label: "hover.sqlite.schemaVersion".localized, value: "\(schemaVersion)", fontSize: settings.fontSize)
                    }
                    if settings.showSQLitePageSize, let pageSize = db.pageSize {
                        DetailRow(icon: "doc", label: "hover.sqlite.pageSize".localized, value: "\(pageSize) bytes", fontSize: settings.fontSize)
                    }
                    if settings.showSQLiteEncoding, let encoding = db.encoding {
                        DetailRow(icon: "textformat.abc", label: "hover.sqlite.encoding".localized, value: encoding, fontSize: settings.fontSize)
                    }
                }
            }

        case .git:
            if settings.showGit, let git = fileInfo.gitMetadata, git.hasData {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.git.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showGitCurrentBranch, let currentBranch = git.currentBranch {
                        DetailRow(icon: "arrow.right.circle", label: "hover.git.currentBranch".localized, value: currentBranch, fontSize: settings.fontSize)
                    }
                    if settings.showGitBranchCount, let branchCount = git.branchCount {
                        DetailRow(icon: "arrow.triangle.branch", label: "hover.git.branchCount".localized, value: "\(branchCount)", fontSize: settings.fontSize)
                    }
                    if settings.showGitCommitCount, let commitCount = git.commitCount {
                        DetailRow(icon: "number", label: "hover.git.commitCount".localized, value: "\(commitCount)", fontSize: settings.fontSize)
                    }
                    if settings.showGitLastCommitDate, let lastCommitDate = git.lastCommitDate {
                        DetailRow(icon: "calendar", label: "hover.git.lastCommitDate".localized, value: lastCommitDate, fontSize: settings.fontSize)
                    }
                    if settings.showGitLastCommitMessage, let lastCommitMessage = git.lastCommitMessage {
                        DetailRow(icon: "text.bubble", label: "hover.git.lastCommitMessage".localized, value: lastCommitMessage, fontSize: settings.fontSize)
                    }
                    if settings.showGitRemoteURL, let remoteURL = git.remoteURL {
                        DetailRow(icon: "link", label: "hover.git.remoteURL".localized, value: remoteURL, fontSize: settings.fontSize)
                    }
                    if settings.showGitUncommittedChanges, let hasChanges = git.hasUncommittedChanges {
                        let status = hasChanges ? "Yes" : "No"
                        DetailRow(icon: "exclamationmark.triangle", label: "hover.git.uncommittedChanges".localized, value: status, fontSize: settings.fontSize)
                    }
                    if settings.showGitTagCount, let tagCount = git.tagCount {
                        DetailRow(icon: "tag", label: "hover.git.tagCount".localized, value: "\(tagCount)", fontSize: settings.fontSize)
                    }
                }
            }

        case .systemMetadata:
            if settings.showSystemMetadata, let systemMeta = fileInfo.systemMetadata, systemMeta.hasData {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.systemMetadata.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    // Finder Tags
                    if settings.showFinderTags, let tags = systemMeta.finderTags, !tags.isEmpty {
                        DetailRow(icon: "tag", label: "hover.systemMetadata.tags".localized, value: tags.joined(separator: ", "), fontSize: settings.fontSize)
                    }

                    // Where From (Download Source)
                    if settings.showWhereFroms, let whereFroms = systemMeta.whereFroms, !whereFroms.isEmpty {
                        let source = whereFroms.first ?? ""
                        DetailRow(icon: "arrow.down.circle", label: "hover.systemMetadata.whereFrom".localized, value: source, fontSize: settings.fontSize)
                    }

                    // Quarantine Info
                    if settings.showQuarantineInfo, let quarantine = systemMeta.quarantineInfo, quarantine.hasData {
                        if quarantine.isQuarantined {
                            if let downloadDate = quarantine.downloadDate {
                                DetailRow(icon: "exclamationmark.shield", label: "hover.systemMetadata.quarantineDate".localized, value: downloadDate, fontSize: settings.fontSize)
                            }
                            if let sourceApp = quarantine.sourceApp {
                                DetailRow(icon: "app.badge", label: "hover.systemMetadata.downloadedBy".localized, value: sourceApp, fontSize: settings.fontSize)
                            }
                        }
                    }

                    // Link Info
                    if settings.showLinkInfo, let linkInfo = systemMeta.linkInfo, linkInfo.hasData {
                        if linkInfo.isSymlink, let target = linkInfo.symlinkTarget {
                            DetailRow(icon: "link", label: "hover.systemMetadata.symlinkTarget".localized, value: target, fontSize: settings.fontSize)
                        }
                        if linkInfo.hardLinkCount > 1 {
                            DetailRow(icon: "doc.on.doc", label: "hover.systemMetadata.hardLinks".localized, value: "\(linkInfo.hardLinkCount)", fontSize: settings.fontSize)
                        }
                    }

                    // Usage Stats
                    if settings.showUsageStats, let usage = systemMeta.usageStats, usage.hasData {
                        if let useCount = usage.useCount {
                            DetailRow(icon: "chart.bar", label: "hover.systemMetadata.useCount".localized, value: "\(useCount)", fontSize: settings.fontSize)
                        }
                        if let lastUsed = usage.lastUsedDate {
                            DetailRow(icon: "clock.arrow.circlepath", label: "hover.systemMetadata.lastUsed".localized, value: lastUsed, fontSize: settings.fontSize)
                        }
                    }

                    // iCloud Status
                    if settings.showiCloudStatus, let iCloudStatus = systemMeta.iCloudStatus {
                        DetailRow(icon: "icloud", label: "hover.systemMetadata.iCloud".localized, value: iCloudStatus, fontSize: settings.fontSize)
                    }

                    // Finder Comment
                    if settings.showFinderComment, let comment = systemMeta.finderComment {
                        DetailRow(icon: "text.bubble", label: "hover.systemMetadata.comment".localized, value: comment, fontSize: settings.fontSize)
                    }

                    // UTI
                    if settings.showUTI, let uti = systemMeta.uti {
                        DetailRow(icon: "doc.badge.gearshape", label: "hover.systemMetadata.uti".localized, value: uti, fontSize: settings.fontSize)
                    }

                    // Extended Attributes
                    if settings.showExtendedAttributes, let xattrs = systemMeta.extendedAttributes, !xattrs.isEmpty {
                        DetailRow(icon: "list.bullet", label: "hover.systemMetadata.xattr".localized, value: "\(xattrs.count)", fontSize: settings.fontSize)
                    }

                    // Alias Target
                    if settings.showAliasTarget, systemMeta.isAliasFile, let target = systemMeta.aliasTarget {
                        DetailRow(icon: "arrow.turn.up.right", label: "hover.systemMetadata.aliasTarget".localized, value: target, fontSize: settings.fontSize)
                    }
                }
            }

        case .filePath:
            if settings.showFilePath {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "folder", label: "hover.label.location".localized, value: fileInfo.path, fontSize: settings.fontSize)
                }
            }

        case .fileSystemAdvanced:
            if settings.showFileSystemAdvanced, let fsMetadata = fileInfo.fileSystemAdvancedMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.fileSystemAdvanced.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showAllocatedSize, let size = fsMetadata.formattedAllocatedSize {
                        DetailRow(icon: "archivebox", label: "hover.fileSystemAdvanced.allocatedSize".localized, value: size, fontSize: settings.fontSize)
                    }
                    if settings.showVolumeInfo {
                        if let volumeName = fsMetadata.volumeName {
                            DetailRow(icon: "externaldrive", label: "hover.fileSystemAdvanced.volumeName".localized, value: volumeName, fontSize: settings.fontSize)
                        }
                        if let volumeFormat = fsMetadata.volumeFormat {
                            DetailRow(icon: "internaldrive", label: "hover.fileSystemAdvanced.volumeFormat".localized, value: volumeFormat, fontSize: settings.fontSize)
                        }
                        if let available = fsMetadata.formattedVolumeAvailable {
                            DetailRow(icon: "chart.pie", label: "hover.fileSystemAdvanced.volumeAvailable".localized, value: available, fontSize: settings.fontSize)
                        }
                    }
                    if settings.showSpotlightIndexed, let indexed = fsMetadata.spotlightIndexed {
                        DetailRow(icon: "magnifyingglass", label: "hover.fileSystemAdvanced.spotlightIndexed".localized, value: indexed ? "hover.config.yes".localized : "hover.config.no".localized, fontSize: settings.fontSize)
                    }
                    if settings.showFileProvider, let provider = fsMetadata.fileProviderName {
                        DetailRow(icon: "cloud", label: "hover.fileSystemAdvanced.fileProvider".localized, value: provider, fontSize: settings.fontSize)
                        if let status = fsMetadata.fileProviderStatus {
                            DetailRow(icon: "arrow.triangle.2.circlepath", label: "hover.fileSystemAdvanced.fileProviderStatus".localized, value: status, fontSize: settings.fontSize)
                        }
                    }
                }
            }

        case .model3D:
            if settings.showModel3D, let model3D = fileInfo.model3DMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.model3D.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if settings.showModel3DFormat, let format = model3D.format {
                        DetailRow(icon: "doc", label: "hover.model3D.format".localized, value: format, fontSize: settings.fontSize)
                    }
                    if settings.showModel3DVertices {
                        if let vertices = model3D.vertexCount {
                            DetailRow(icon: "circle.grid.3x3", label: "hover.model3D.vertices".localized, value: "\(vertices)", fontSize: settings.fontSize)
                        }
                        if let faces = model3D.faceCount {
                            DetailRow(icon: "triangle", label: "hover.model3D.faces".localized, value: "\(faces)", fontSize: settings.fontSize)
                        }
                    }
                    if settings.showModel3DMaterials, let materials = model3D.materialCount {
                        DetailRow(icon: "paintpalette", label: "hover.model3D.materials".localized, value: "\(materials)", fontSize: settings.fontSize)
                    }
                    if settings.showModel3DAnimations, let animations = model3D.animationCount, animations > 0 {
                        DetailRow(icon: "play.rectangle", label: "hover.model3D.animations".localized, value: "\(animations)", fontSize: settings.fontSize)
                    }
                }
            }

        case .xcodeProject:
            if settings.showXcodeProject, let xcode = fileInfo.xcodeProjectMetadata {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    Text("hover.xcodeProject.title".localized)
                        .font(.system(size: settings.fontSize, weight: .semibold))

                    if let name = xcode.projectName {
                        DetailRow(icon: "folder", label: "hover.xcodeProject.projectName".localized, value: name, fontSize: settings.fontSize)
                    }
                    if settings.showXcodeTargets, let targets = xcode.targetCount {
                        DetailRow(icon: "target", label: "hover.xcodeProject.targets".localized, value: "\(targets)", fontSize: settings.fontSize)
                    }
                    if settings.showXcodeSwiftVersion, let swift = xcode.swiftVersion {
                        DetailRow(icon: "swift", label: "hover.xcodeProject.swiftVersion".localized, value: swift, fontSize: settings.fontSize)
                    }
                    if settings.showXcodeDeploymentTarget, let target = xcode.deploymentTarget {
                        DetailRow(icon: "desktopcomputer", label: "hover.xcodeProject.deploymentTarget".localized, value: target, fontSize: settings.fontSize)
                    }
                    if let hasTests = xcode.hasTests, hasTests {
                        DetailRow(icon: "checkmark.circle", label: "hover.xcodeProject.hasTests".localized, value: "hover.config.yes".localized, fontSize: settings.fontSize)
                    }
                }
            }
        }
    }

    private func getFileTypeDescription() -> String {
        return FileTypeDescriptor.description(
            fileExtension: fileInfo.fileExtension,
            isDirectory: fileInfo.isDirectory
        )
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let fontSize: Double
    @ObservedObject private var windowState = HoverWindowState.shared

    private var uniqueKey: String {
        label + ":" + value
    }

    private var isCopied: Bool {
        windowState.copiedValue == uniqueKey
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: fontSize))
                .foregroundColor(.secondary)
                .frame(width: 14, alignment: .center)

            Text(label + ":")
                .font(.system(size: fontSize))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(minWidth: 75, alignment: .trailing)

            Text(value)
                .font(.system(size: fontSize))
                .fontWeight(.medium)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            // "Copied" text - shown after value when copied
            if isCopied {
                Text(NSLocalizedString("hover.copy.copied", comment: ""))
                    .font(.system(size: fontSize - 1))
                    .foregroundColor(.green)
            }

            Spacer(minLength: 0)

            // Copy button - always present but only visible when locked
            CopyButton(uniqueKey: uniqueKey, value: value, fontSize: fontSize, isVisible: windowState.isLocked)
        }
    }
}

// MARK: - Copy Button
struct CopyButton: View {
    let uniqueKey: String  // Unique identifier for this row
    let value: String      // Actual value to copy
    let fontSize: Double
    let isVisible: Bool
    @ObservedObject private var windowState = HoverWindowState.shared
    @State private var isHovering = false

    var body: some View {
        Image(systemName: "doc.on.doc")
            .font(.system(size: fontSize))
            .foregroundColor(isHovering ? .primary : .secondary)
            .frame(width: 14, alignment: .center)
            .opacity(isVisible ? 1 : 0)
            .onTapGesture {
                if isVisible {
                    windowState.copyToClipboard(value, key: uniqueKey)
                }
            }
            .onHover { hovering in
                if isVisible {
                    isHovering = hovering
                }
            }
            .help(NSLocalizedString("hover.copy.copy", comment: ""))
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
