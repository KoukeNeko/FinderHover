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
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
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

        // Position window near mouse cursor
        let offsetX: CGFloat = 15
        let offsetY: CGFloat = -15
        let windowOrigin = CGPoint(
            x: position.x + offsetX,
            y: position.y + offsetY - window.frame.height
        )

        window.setFrameOrigin(windowOrigin)
        window.orderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }
}

struct HoverContentView: View {
    let fileInfo: FileInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // File icon and name
            HStack(spacing: 10) {
                Image(nsImage: fileInfo.icon)
                    .resizable()
                    .frame(width: 32, height: 32)

                Text(fileInfo.name)
                    .font(.headline)
                    .lineLimit(2)
            }

            Divider()

            // File details
            VStack(alignment: .leading, spacing: 6) {
                InfoRow(label: "Type", value: fileInfo.isDirectory ? "Folder" : (fileInfo.fileExtension?.uppercased() ?? "File"))
                InfoRow(label: "Size", value: fileInfo.formattedSize)
                InfoRow(label: "Modified", value: fileInfo.formattedModificationDate)
            }
            .font(.system(size: 11))

            // File path
            Text(fileInfo.path)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)
        }
        .padding(12)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.windowBackgroundColor).opacity(0.95))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
