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
            // Create visual effect view for blur
            let effectView = NSVisualEffectView()
            effectView.material = .hudWindow
            effectView.state = .active
            effectView.blendingMode = .behindWindow
            effectView.wantsLayer = true
            effectView.layer?.cornerRadius = 10
            effectView.layer?.masksToBounds = true

            // Set frame to match content size
            effectView.frame = NSRect(origin: .zero, size: fittingSize)
            hostingView.frame = effectView.bounds
            hostingView.autoresizingMask = [.width, .height]

            // Add hosting view to effect view
            effectView.addSubview(hostingView)
            window.contentView = effectView
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
        VStack(alignment: .leading, spacing: 10) {
            // File icon and name
            HStack(spacing: 12) {
                if settings.showIcon {
                    Image(nsImage: thumbnail ?? fileInfo.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .onAppear {
                            // Load thumbnail asynchronously
                            fileInfo.generateThumbnailAsync { image in
                                if let image = image {
                                    thumbnail = image
                                }
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(fileInfo.name)
                        .font(.system(size: settings.fontSize + 2, weight: .semibold))
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

            // File details in a grid
            VStack(alignment: .leading, spacing: 8) {
                if settings.showFileType {
                    DetailRow(icon: "doc.text", label: "Type", value: getFileTypeDescription(), fontSize: settings.fontSize)
                }
                if settings.showFileSize {
                    DetailRow(icon: "archivebox", label: "Size", value: fileInfo.formattedSize, fontSize: settings.fontSize)
                }
                if settings.showCreationDate {
                    DetailRow(icon: "calendar", label: "Created", value: formattedDate(fileInfo.creationDate), fontSize: settings.fontSize)
                }
                if settings.showModificationDate {
                    DetailRow(icon: "clock", label: "Modified", value: fileInfo.formattedModificationDate, fontSize: settings.fontSize)
                }
            }

            // File path section
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
                .padding(.top, 4)
            }
        }
        .padding(14)
        .frame(minWidth: 320, maxWidth: settings.windowMaxWidth)
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

