//
//  HoverWindow.swift
//  FinderHover
//
//  Floating window that displays file information
//

import SwiftUI
import AppKit

class HoverWindowController: NSWindowController {
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

        // Update content
        let hostingView = NSHostingView(rootView: HoverContentView(fileInfo: fileInfo))
        window.contentView = hostingView

        // Calculate proper window size from content
        hostingView.invalidateIntrinsicContentSize()
        let fittingSize = hostingView.fittingSize
        window.setContentSize(fittingSize)

        // Position window near mouse cursor with smart positioning
        let offsetX: CGFloat = 15
        let offsetY: CGFloat = 15
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // File icon and name
            HStack(spacing: 12) {
                Image(nsImage: fileInfo.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(fileInfo.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(fileInfo.isDirectory ? "Folder" : (fileInfo.fileExtension?.uppercased() ?? "File"))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Divider()
                .background(Color.gray.opacity(0.3))

            // File details in a grid
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(icon: "doc.text", label: "Type", value: getFileTypeDescription())
                DetailRow(icon: "archivebox", label: "Size", value: fileInfo.formattedSize)
                DetailRow(icon: "calendar", label: "Created", value: formattedDate(fileInfo.creationDate))
                DetailRow(icon: "clock", label: "Modified", value: fileInfo.formattedModificationDate)
            }
            .font(.system(size: 11))

            // File path section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "folder")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("Location:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Text(fileInfo.path)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .frame(minWidth: 320, maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.gray.opacity(0.15)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
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

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(label + ":")
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            Text(value)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

