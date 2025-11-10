//
//  HoverWindow.swift
//  FinderHover
//
//  Floating window that displays file information
//

import SwiftUI
import AppKit

class HoverWindowController: NSWindowController {
    private var visualEffectView: NSVisualEffectView?

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
    }

    func hide() {
        window?.orderOut(nil)
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
        var windowOrigin = CGPoint(
            x: position.x + offsetX,
            y: position.y - offsetY - window.frame.height
        )

        // Find the screen that contains the mouse position
        let screen = NSScreen.screens.first { NSMouseInRect(position, $0.frame, false) } ?? NSScreen.main
        guard let screen = screen else { return }

        let screenFrame = screen.visibleFrame

        // Check right edge
        if windowOrigin.x + window.frame.width > screenFrame.maxX {
            windowOrigin.x = position.x - offsetX - window.frame.width
        }

        // Check left edge
        if windowOrigin.x < screenFrame.minX {
            windowOrigin.x = screenFrame.minX + Constants.WindowLayout.screenEdgePadding
        }

        // Check bottom edge
        if windowOrigin.y < screenFrame.minY {
            windowOrigin.y = position.y + offsetY
        }

        // Check top edge
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
    @ObservedObject var settings = AppSettings.shared

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
                            // Load thumbnail asynchronously
                            fileInfo.generateThumbnailAsync { image in
                                if let image = image {
                                    thumbnail = image
                                }
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

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
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

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
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

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
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

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
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

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
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

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                }
            }

        case .filePath:
            if settings.showFilePath {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "folder")
                            .font(.system(size: settings.fontSize))
                            .foregroundColor(.secondary)
                            .frame(width: 14, alignment: .center)

                        Text("hover.label.location".localized + ":")
                            .font(.system(size: settings.fontSize))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .frame(minWidth: 65, alignment: .trailing)

                        Text(fileInfo.path)
                            .font(.system(size: settings.fontSize, design: .monospaced))
                            .fontWeight(.medium)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                .frame(minWidth: 65, alignment: .trailing)

            Text(value)
                .font(.system(size: fontSize))
                .fontWeight(.medium)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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
