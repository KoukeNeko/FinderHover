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

        // Set a width constraint for proper height calculation
        let maxWidth = settings.windowMaxWidth

        // Use intrinsicContentSize with proper width constraint
        hostingView.frame = NSRect(x: 0, y: 0, width: maxWidth, height: 0)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        // Create temporary container to calculate size
        let tempContainer = NSView(frame: NSRect(x: 0, y: 0, width: maxWidth, height: 5000))
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

        // Determine corner radius based on UI style
        let cornerRadius: CGFloat = settings.uiStyle == .windows ? 0 : 10

        // Check if blur is enabled
        if settings.enableBlur {
            let osVersion = ProcessInfo.processInfo.operatingSystemVersion
            // Use container view approach for macOS <= macOS 15.x (where direct cornerRadius doesn't work)
            let useLegacyBlurLayout = osVersion.majorVersion <= 15

            // Create visual effect view for blur
            let effectView = NSVisualEffectView()
            effectView.state = .active

            if useLegacyBlurLayout {
                // For macOS 15.x, use transparent container with clipping
                // Direct cornerRadius on NSVisualEffectView doesn't work properly on macOS 15.x
                effectView.material = .hudWindow
                effectView.blendingMode = .behindWindow
                effectView.frame = NSRect(origin: .zero, size: fittingSize)

                hostingView.frame = effectView.bounds
                hostingView.autoresizingMask = [.width, .height]
                effectView.addSubview(hostingView)

                // Create transparent clipping container
                let containerView = NSView(frame: NSRect(origin: .zero, size: fittingSize))
                containerView.wantsLayer = true
                containerView.layer?.cornerRadius = cornerRadius
                containerView.layer?.masksToBounds = true

                // Add subtle border like native macOS HUD windows (only for macOS style)
                if cornerRadius > 0 {
                    containerView.layer?.borderWidth = 0.5
                    containerView.layer?.borderColor = NSColor.systemGray.withAlphaComponent(0.5).cgColor
                }

                effectView.autoresizingMask = [.width, .height]
                containerView.addSubview(effectView)
                window.contentView = containerView
            } else {
                // macOS 26+ support direct cornerRadius on NSVisualEffectView
                effectView.material = .hudWindow
                effectView.blendingMode = .behindWindow
                effectView.wantsLayer = true
                effectView.layer?.cornerRadius = cornerRadius
                effectView.layer?.masksToBounds = true

                // Add subtle border like native macOS HUD windows (only for macOS style)
                if cornerRadius > 0 {
                    effectView.layer?.borderWidth = 0.5
                    effectView.layer?.borderColor = NSColor.black.withAlphaComponent(0.2).cgColor
                } else {
                    effectView.layer?.borderWidth = 0
                    effectView.layer?.borderColor = nil
                }

                effectView.frame = NSRect(origin: .zero, size: fittingSize)

                hostingView.frame = effectView.bounds
                hostingView.autoresizingMask = [.width, .height]
                effectView.addSubview(hostingView)
                window.contentView = effectView
            }

            self.visualEffectView = effectView
        } else {
            // No blur - use solid background
            let containerView = NSView(frame: NSRect(origin: .zero, size: fittingSize))
            containerView.wantsLayer = true
            containerView.layer?.cornerRadius = cornerRadius
            containerView.layer?.masksToBounds = true
            containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(settings.windowOpacity).cgColor

            hostingView.frame = containerView.bounds
            containerView.addSubview(hostingView)
            window.contentView = containerView
        }

        // Set window size
        window.setContentSize(fittingSize)

        // Position window near mouse cursor with smart positioning
        let offsetX: CGFloat = settings.windowOffsetX
        let offsetY: CGFloat = settings.windowOffsetY
        var windowOrigin = CGPoint(
            x: position.x + offsetX,
            y: position.y - offsetY - window.frame.height
        )

        // Ensure window stays on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame

            // Check right edge
            if windowOrigin.x + window.frame.width > screenFrame.maxX {
                windowOrigin.x = position.x - offsetX - window.frame.width
            }

            // Check left edge
            if windowOrigin.x < screenFrame.minX {
                windowOrigin.x = screenFrame.minX + 10
            }

            // Check bottom edge
            if windowOrigin.y < screenFrame.minY {
                windowOrigin.y = position.y + offsetY
            }

            // Check top edge
            if windowOrigin.y + window.frame.height > screenFrame.maxY {
                windowOrigin.y = screenFrame.maxY - window.frame.height - 10
            }
        }

        window.setFrameOrigin(windowOrigin)
        window.orderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
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
                    Image(nsImage: thumbnail ?? fileInfo.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: settings.compactMode ? 32 : 48, height: settings.compactMode ? 32 : 48)
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
            .onAppear {
                print("Display order: \(settings.displayOrder.map { $0.rawValue })")
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
                            DetailRow(icon: "slider.horizontal.3", label: "hover.exif.settings".localized, value: settingsComponents.joined(separator: "  "), fontSize: settings.fontSize)
                        }
                    }
                    if settings.showEXIFDateTaken, let date = exif.dateTaken {
                        DetailRow(icon: "calendar.badge.clock", label: "hover.exif.taken".localized, value: date, fontSize: settings.fontSize)
                    }
                    if settings.showEXIFDimensions, let size = exif.imageSize {
                        DetailRow(icon: "arrow.up.left.and.arrow.down.right", label: "hover.exif.dimensions".localized, value: size, fontSize: settings.fontSize)
                    }
                    if settings.showEXIFGPS, let gps = exif.gpsLocation {
                        DetailRow(icon: "location", label: "hover.exif.gps".localized, value: gps, fontSize: settings.fontSize)
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
                        DetailRow(icon: "clock", label: "hover.video.duration".localized, value: duration, fontSize: settings.fontSize)
                    }
                    if settings.showVideoResolution, let resolution = video.resolution {
                        DetailRow(icon: "arrow.up.left.and.arrow.down.right", label: "hover.video.resolution".localized, value: resolution, fontSize: settings.fontSize)
                    }
                    if settings.showVideoCodec, let codec = video.codec {
                        DetailRow(icon: "film", label: "hover.video.codec".localized, value: codec, fontSize: settings.fontSize)
                    }
                    if settings.showVideoFrameRate, let frameRate = video.frameRate {
                        DetailRow(icon: "speedometer", label: "hover.video.framerate".localized, value: frameRate, fontSize: settings.fontSize)
                    }
                    if settings.showVideoBitrate, let bitrate = video.bitrate {
                        DetailRow(icon: "speedometer", label: "hover.video.bitrate".localized, value: bitrate, fontSize: settings.fontSize)
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
                        DetailRow(icon: "textformat", label: "hover.audio.songTitle".localized, value: title, fontSize: settings.fontSize)
                    }
                    if settings.showAudioArtist, let artist = audio.artist {
                        DetailRow(icon: "person", label: "hover.audio.artist".localized, value: artist, fontSize: settings.fontSize)
                    }
                    if settings.showAudioAlbum, let album = audio.album {
                        DetailRow(icon: "square.stack", label: "hover.audio.album".localized, value: album, fontSize: settings.fontSize)
                    }
                    if settings.showAudioGenre, let genre = audio.genre {
                        DetailRow(icon: "music.note.list", label: "hover.audio.genre".localized, value: genre, fontSize: settings.fontSize)
                    }
                    if settings.showAudioYear, let year = audio.year {
                        DetailRow(icon: "calendar", label: "hover.audio.year".localized, value: year, fontSize: settings.fontSize)
                    }
                    if settings.showAudioDuration, let duration = audio.duration {
                        DetailRow(icon: "clock", label: "hover.audio.duration".localized, value: duration, fontSize: settings.fontSize)
                    }
                    if settings.showAudioBitrate, let bitrate = audio.bitrate {
                        DetailRow(icon: "speedometer", label: "hover.audio.bitrate".localized, value: bitrate, fontSize: settings.fontSize)
                    }
                    if settings.showAudioSampleRate, let sampleRate = audio.sampleRate {
                        DetailRow(icon: "waveform", label: "hover.audio.samplerate".localized, value: sampleRate, fontSize: settings.fontSize)
                    }
                    if let channels = audio.channels {
                        DetailRow(icon: "speaker.wave.2", label: "hover.audio.channels".localized, value: channels, fontSize: settings.fontSize)
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
        if fileInfo.isDirectory {
            return "Folder"
        }

        if let ext = fileInfo.fileExtension {
            let typeMap: [String: String] = [
                "pdf": "PDF Document",
                "doc": "Word Document",
                "docx": "Word Document",
                "xls": "Excel Spreadsheet",
                "xlsx": "Excel Spreadsheet",
                "ppt": "PowerPoint Presentation",
                "pptx": "PowerPoint Presentation",
                "key": "Keynote Presentation",
                "pages": "Pages Document",
                "numbers": "Numbers Spreadsheet",
                "txt": "Text File",
                "rtf": "Rich Text Document",
                "md": "Markdown File",
                "csv": "CSV File",
                "json": "JSON File",
                "xml": "XML File",
                "jpg": "JPEG Image",
                "jpeg": "JPEG Image",
                "png": "PNG Image",
                "gif": "GIF Image",
                "svg": "SVG Image",
                "bmp": "Bitmap Image",
                "tiff": "TIFF Image",
                "psd": "Photoshop Document",
                "ai": "Illustrator File",
                "sketch": "Sketch File",
                "mp4": "MP4 Video",
                "mov": "QuickTime Movie",
                "avi": "AVI Video",
                "mkv": "MKV Video",
                "mp3": "MP3 Audio",
                "wav": "WAV Audio",
                "aac": "AAC Audio",
                "flac": "FLAC Audio",
                "zip": "ZIP Archive",
                "rar": "RAR Archive",
                "7z": "7-Zip Archive",
                "tar": "TAR Archive",
                "gz": "GZIP Archive",
                "dmg": "Disk Image",
                "iso": "ISO Disk Image",
                "pkg": "macOS Installer",
                "app": "Application",
                "swift": "Swift Source",
                "py": "Python Script",
                "js": "JavaScript File",
                "ts": "TypeScript File",
                "css": "CSS Stylesheet",
                "html": "HTML Document",
                "php": "PHP Script",
                "java": "Java Source",
                "c": "C Source",
                "cpp": "C++ Source",
                "h": "Header File",
                "sh": "Shell Script"
            ]

            return typeMap[ext.lowercased()] ?? "\(ext.uppercased()) File"
        }

        return "File"
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
        if fileInfo.isDirectory {
            return "Folder"
        }

        if let ext = fileInfo.fileExtension {
            let typeMap: [String: String] = [
                "pdf": "PDF Document",
                "doc": "Microsoft Word 97 - 2003 Document",
                "docx": "Microsoft Word Document",
                "xls": "Microsoft Excel 97 - 2003 Spreadsheet",
                "xlsx": "Microsoft Excel Spreadsheet",
                "ppt": "Microsoft PowerPoint 97 - 2003 Presentation",
                "pptx": "Microsoft PowerPoint Presentation",
                "txt": "Text Document",
                "rtf": "Rich Text Document",
                "jpg": "JPEG Image",
                "jpeg": "JPEG Image",
                "png": "PNG Image",
                "gif": "GIF Image",
                "bmp": "Bitmap Image",
                "mp4": "MP4 Video",
                "mov": "QuickTime Movie",
                "avi": "AVI Video",
                "mp3": "MP3 Audio",
                "wav": "WAV Audio",
                "zip": "ZIP Archive",
                "rar": "RAR Archive"
            ]

            return typeMap[ext.lowercased()] ?? "\(ext.uppercased()) File"
        }

        return "File"
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
