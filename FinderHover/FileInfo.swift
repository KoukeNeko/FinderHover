//
//  FileInfo.swift
//  FinderHover
//
//  File metadata model
//

import Foundation
import AppKit
import QuickLookThumbnailing

struct FileInfo {
    let name: String
    let path: String
    let size: Int64
    let modificationDate: Date
    let creationDate: Date
    let fileType: String
    let isDirectory: Bool
    let fileExtension: String?

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedModificationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modificationDate)
    }

    var icon: NSImage {
        // Try to generate thumbnail first
        if let thumbnail = generateThumbnail() {
            return thumbnail
        }
        // Fallback to standard icon
        return NSWorkspace.shared.icon(forFile: path)
    }

    private func generateThumbnail() -> NSImage? {
        let url = URL(fileURLWithPath: path)
        let size = CGSize(width: 128, height: 128)
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0

        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )

        var thumbnailImage: NSImage?
        let semaphore = DispatchSemaphore(value: 0)

        QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnail, type, error in
            if let thumbnail = thumbnail {
                thumbnailImage = thumbnail.nsImage
            }
            semaphore.signal()
        }

        // Wait max 0.5 seconds for thumbnail
        _ = semaphore.wait(timeout: .now() + 0.5)

        return thumbnailImage
    }

    static func from(path: String) -> FileInfo? {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: path) else {
            return nil
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let url = URL(fileURLWithPath: path)

            return FileInfo(
                name: url.lastPathComponent,
                path: path,
                size: attributes[.size] as? Int64 ?? 0,
                modificationDate: attributes[.modificationDate] as? Date ?? Date(),
                creationDate: attributes[.creationDate] as? Date ?? Date(),
                fileType: attributes[.type] as? String ?? "Unknown",
                isDirectory: (attributes[.type] as? FileAttributeType) == .typeDirectory,
                fileExtension: url.pathExtension.isEmpty ? nil : url.pathExtension
            )
        } catch {
            return nil
        }
    }
}
