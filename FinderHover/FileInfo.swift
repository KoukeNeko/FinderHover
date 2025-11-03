//
//  FileInfo.swift
//  FinderHover
//
//  File metadata model
//

import Foundation
import AppKit

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
        NSWorkspace.shared.icon(forFile: path)
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
