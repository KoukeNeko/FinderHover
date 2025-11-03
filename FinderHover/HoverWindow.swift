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

        // Create content view
        let hostingView = NSHostingView(rootView: HoverContentView(fileInfo: fileInfo))

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

        // Check if blur is enabled
        if settings.enableBlur {
            let osVersion = ProcessInfo.processInfo.operatingSystemVersion
            let useLegacyBlurLayout = osVersion.majorVersion < 11

            // Create visual effect view for blur
            let effectView = NSVisualEffectView()
            effectView.state = .active

            if useLegacyBlurLayout {
                // Older macOS builds (pre-11.0) have rendering artifacts when rounding the effect view layer directly.
                effectView.material = .dark
                effectView.blendingMode = .withinWindow

                let containerView = NSView(frame: NSRect(origin: .zero, size: fittingSize))
                containerView.wantsLayer = true
                containerView.layer?.cornerRadius = 10
                containerView.layer?.masksToBounds = true
                containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(settings.windowOpacity).cgColor

                effectView.frame = containerView.bounds
                effectView.autoresizingMask = [.width, .height]

                hostingView.frame = effectView.bounds
                hostingView.autoresizingMask = [.width, .height]
                effectView.addSubview(hostingView)

                containerView.addSubview(effectView)
                window.contentView = containerView
            } else {
                effectView.material = .hudWindow
                effectView.blendingMode = .behindWindow
                effectView.wantsLayer = true
                effectView.layer?.cornerRadius = 10
                effectView.layer?.masksToBounds = true

                // Remove any borders from the visual effect view
                effectView.layer?.borderWidth = 0
                effectView.layer?.borderColor = nil

                // Set frame to match content size
                effectView.frame = NSRect(origin: .zero, size: fittingSize)
                hostingView.frame = effectView.bounds
                hostingView.autoresizingMask = [.width, .height]

                // Add hosting view to effect view
                effectView.addSubview(hostingView)
                window.contentView = effectView
            }

            self.visualEffectView = effectView
        } else {
            // No blur - use solid background with rounded corners
            let containerView = NSView(frame: NSRect(origin: .zero, size: fittingSize))
            containerView.wantsLayer = true
            containerView.layer?.cornerRadius = 10
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

                    Text(fileInfo.isDirectory ? "Folder" : (fileInfo.fileExtension?.uppercased() ?? "File"))
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

            // File path section - always at the bottom when enabled
            if settings.showFilePath {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "folder")
                        .font(.system(size: settings.fontSize))
                        .foregroundColor(.secondary)
                        .frame(width: 14, alignment: .center)

                    Text("Location:")
                        .font(.system(size: settings.fontSize))
                        .foregroundColor(.secondary)
                        .frame(width: 65, alignment: .trailing)

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
                    DetailRow(icon: "doc.text", label: "Type", value: getFileTypeDescription(), fontSize: settings.fontSize)
                }
            }

        case .fileSize:
            if settings.showFileSize {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "archivebox", label: "Size", value: fileInfo.formattedSize, fontSize: settings.fontSize)
                }
            }

        case .itemCount:
            if settings.showItemCount && fileInfo.isDirectory {
                if let count = fileInfo.itemCount {
                    VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                        DetailRow(icon: "number", label: "Items", value: "\(count) item\(count == 1 ? "" : "s")", fontSize: settings.fontSize)
                    }
                }
            }

        case .creationDate:
            if settings.showCreationDate {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "calendar", label: "Created", value: fileInfo.formattedCreationDate, fontSize: settings.fontSize)
                }
            }

        case .modificationDate:
            if settings.showModificationDate {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "clock", label: "Modified", value: fileInfo.formattedModificationDate, fontSize: settings.fontSize)
                }
            }

        case .lastAccessDate:
            if settings.showLastAccessDate {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "eye", label: "Accessed", value: fileInfo.formattedLastAccessDate, fontSize: settings.fontSize)
                }
            }

        case .permissions:
            if settings.showPermissions {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "lock.shield", label: "Mode", value: fileInfo.formattedPermissions, fontSize: settings.fontSize)
                }
            }

        case .owner:
            if settings.showOwner {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    DetailRow(icon: "person", label: "Owner", value: fileInfo.owner, fontSize: settings.fontSize)
                }
            }

        case .exif:
            if settings.showEXIF, let exif = fileInfo.exifData {
                VStack(alignment: .leading, spacing: settings.compactMode ? 4 : 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                        .padding(.bottom, settings.compactMode ? 2 : 4)

                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: settings.fontSize))
                            .foregroundColor(.secondary)
                        Text("Photo Information")
                            .font(.system(size: settings.fontSize, weight: .semibold))
                    }

                    if settings.showEXIFCamera, let camera = exif.camera {
                        DetailRow(icon: "camera", label: "Camera", value: camera, fontSize: settings.fontSize)
                    }
                    if settings.showEXIFLens, let lens = exif.lens {
                        DetailRow(icon: "camera.aperture", label: "Lens", value: lens, fontSize: settings.fontSize)
                    }
                    if settings.showEXIFSettings {
                        let settingsComponents = [
                            exif.focalLength,
                            exif.aperture,
                            exif.shutterSpeed,
                            exif.iso
                        ].compactMap { $0 }

                        if !settingsComponents.isEmpty {
                            DetailRow(icon: "slider.horizontal.3", label: "Settings", value: settingsComponents.joined(separator: "  "), fontSize: settings.fontSize)
                        }
                    }
                    if settings.showEXIFDateTaken, let date = exif.dateTaken {
                        DetailRow(icon: "calendar.badge.clock", label: "Taken", value: date, fontSize: settings.fontSize)
                    }
                    if settings.showEXIFDimensions, let size = exif.imageSize {
                        DetailRow(icon: "square.resize", label: "Dimensions", value: size, fontSize: settings.fontSize)
                    }
                    if settings.showEXIFGPS, let gps = exif.gpsLocation {
                        DetailRow(icon: "location.fill", label: "Location", value: gps, fontSize: settings.fontSize)
                    }

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, settings.compactMode ? 2 : 4)
                }
            }

        case .filePath:
            EmptyView() // File path is handled separately at the bottom
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
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: fontSize))
                .foregroundColor(.secondary)
                .frame(width: 14, alignment: .center)

            Text(label + ":")
                .font(.system(size: fontSize))
                .foregroundColor(.secondary)
                .frame(width: 65, alignment: .trailing)

            Text(value)
                .font(.system(size: fontSize))
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
