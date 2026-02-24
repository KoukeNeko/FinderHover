//
//  FinderSync.swift
//  FinderHoverSyncExt
//
//  Principal class for the Finder Sync Extension.
//  Injects a "FinderHover 資訊" submenu into Finder's right-click context menu.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    // MARK: - Constants

    private enum ExtensionNotification {
        static let showFile = "com.finderhover.showFileFromExtension"
        static let filePathKey = "filePath"
    }

    // MARK: - Lifecycle

    override init() {
        super.init()
        // Monitor all directories — NSHomeDirectory() returns the sandbox
        // container path which Finder never browses.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    // MARK: - Context Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let selectedURLs = FIFinderSyncController.default().selectedItemURLs() ?? []
        guard !selectedURLs.isEmpty else { return NSMenu() }

        let menu = NSMenu(title: "")
        let topItem = NSMenuItem(
            title: NSLocalizedString("ext.menu.title", comment: ""),
            action: nil,
            keyEquivalent: ""
        )
        topItem.submenu = buildSubmenu(for: selectedURLs)
        menu.addItem(topItem)
        return menu
    }

    // MARK: - Submenu Construction

    private func buildSubmenu(for urls: [URL]) -> NSMenu {
        let submenu = NSMenu()
        submenu.autoenablesItems = false

        if urls.count == 1, let url = urls.first {
            appendSingleFileItems(to: submenu, url: url)
        } else {
            appendMultipleFilesItem(to: submenu, urls: urls)
        }

        submenu.addItem(.separator())
        submenu.addItem(buildShowInWindowItem(for: urls.first))
        return submenu
    }

    private func appendSingleFileItems(to menu: NSMenu, url: URL) {
        let metadata = MetadataReader.read(url: url)

        let basicLabels: [String] = [
            metadata.typeLabel,
            metadata.sizeLabel,
            metadata.creationDateLabel,
            metadata.modificationDateLabel,
            metadata.lastAccessDateLabel,
            metadata.permissionsLabel,
            metadata.ownerLabel,
        ].compactMap { $0 }

        let sections: [(header: String, labels: [String])] = [
            ("ext.section.exif",   metadata.exifLabels),
            ("ext.section.video",  metadata.videoLabels),
            ("ext.section.audio",  metadata.audioLabels),
            ("ext.section.pdf",    metadata.pdfLabels),
            ("ext.section.font",   metadata.fontLabels),
            ("ext.section.app",    metadata.appLabels),
            ("ext.section.system", metadata.systemLabels),
        ]

        let allItems = basicLabels
            + sections.flatMap { $0.labels }
            + [metadata.filePathLabel].compactMap { $0 }
        let maxLabelWidth = measureMaxLabelWidth(from: allItems)

        basicLabels.forEach { addAlignedItem(to: menu, title: $0, maxLabelWidth: maxLabelWidth) }

        for section in sections where !section.labels.isEmpty {
            menu.addItem(.separator())
            menu.addItem(.sectionHeader(title: NSLocalizedString(section.header, comment: "")))
            section.labels.forEach { addAlignedItem(to: menu, title: $0, maxLabelWidth: maxLabelWidth) }
        }

        if let pathLabel = metadata.filePathLabel {
            if metadata.systemLabels.isEmpty {
                menu.addItem(.separator())
            }
            addAlignedItem(to: menu, title: pathLabel, maxLabelWidth: maxLabelWidth)
        }
    }

    private func appendMultipleFilesItem(to menu: NSMenu, urls: [URL]) {
        let totalBytes = urls.compactMap { MetadataReader.readFileSize(url: $0) }.reduce(0, +)
        let formattedSize = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        let title = String(
            format: NSLocalizedString("ext.menu.multipleItems", comment: ""),
            urls.count,
            formattedSize
        )
        addDisabledItem(to: menu, title: title)
    }

    // MARK: - Menu Item Helpers

    private func addDisabledItem(to menu: NSMenu, title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    private func addAlignedItem(to menu: NSMenu, title: String, maxLabelWidth: CGFloat) {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.attributedTitle = makeAlignedTitle(title, maxLabelWidth: maxLabelWidth)
        menu.addItem(item)
    }

    // MARK: - Label Right-Aligned Layout

    private func measureMaxLabelWidth(from items: [String]) -> CGFloat {
        let font = NSFont.menuFont(ofSize: 0)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        var maxWidth: CGFloat = 0
        for item in items {
            let parts = item.split(separator: "\t", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let w = (String(parts[0]) as NSString).size(withAttributes: attrs).width
            maxWidth = max(maxWidth, w)
        }
        return maxWidth
    }

    /// Build attributed string: label right-aligned via pixel-perfect spacer, value left-aligned.
    private func makeAlignedTitle(_ title: String, maxLabelWidth: CGFloat) -> NSAttributedString {
        let font = NSFont.menuFont(ofSize: 0)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let parts = title.split(separator: "\t", maxSplits: 1)

        guard parts.count == 2 else {
            return NSAttributedString(string: title, attributes: attrs)
        }

        let labelStr = String(parts[0])
        let valueStr = String(parts[1])
        let labelWidth = (labelStr as NSString).size(withAttributes: attrs).width
        let padding = maxLabelWidth - labelWidth

        let result = NSMutableAttributedString()

        // Pixel-perfect spacer via NSTextAttachment with exact bounds
        if padding > 0 {
            let attachment = NSTextAttachment()
            attachment.image = NSImage(size: NSSize(width: padding, height: 1))
            result.append(NSAttributedString(attachment: attachment))
        }

        // Label (secondary color)
        result.append(NSAttributedString(
            string: labelStr,
            attributes: [.font: font, .foregroundColor: NSColor.secondaryLabelColor]))

        // Value (primary color)
        result.append(NSAttributedString(
            string: valueStr,
            attributes: [.font: font, .foregroundColor: NSColor.labelColor]))

        return result
    }

    private func buildShowInWindowItem(for url: URL?) -> NSMenuItem {
        let item = NSMenuItem(
            title: NSLocalizedString("ext.menu.showInWindow", comment: ""),
            action: #selector(handleShowInWindow(_:)),
            keyEquivalent: ""
        )
        item.target = self
        item.representedObject = url?.path
        return item
    }

    // MARK: - Show In Window Action

    @objc private func handleShowInWindow(_ sender: NSMenuItem) {
        guard let filePath = sender.representedObject as? String else { return }
        DistributedNotificationCenter.default().postNotificationName(
            .init(ExtensionNotification.showFile),
            object: nil,
            userInfo: [ExtensionNotification.filePathKey: filePath],
            deliverImmediately: true
        )
    }
}
