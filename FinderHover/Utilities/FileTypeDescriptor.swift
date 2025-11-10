//
//  FileTypeDescriptor.swift
//  FinderHover
//
//  Centralized file type descriptions to eliminate code duplication
//

import Foundation

/// Provides human-readable descriptions for file extensions
enum FileTypeDescriptor {

    /// Map of file extensions to their descriptions
    private static let typeMap: [String: String] = [
        // Documents
        "pdf": "PDF Document",
        "doc": "Microsoft Word 97 - 2003 Document",
        "docx": "Microsoft Word Document",
        "xls": "Microsoft Excel 97 - 2003 Spreadsheet",
        "xlsx": "Microsoft Excel Spreadsheet",
        "ppt": "Microsoft PowerPoint 97 - 2003 Presentation",
        "pptx": "Microsoft PowerPoint Presentation",
        "key": "Keynote Presentation",
        "pages": "Pages Document",
        "numbers": "Numbers Spreadsheet",
        "txt": "Text Document",
        "rtf": "Rich Text Document",
        "md": "Markdown File",
        "csv": "CSV File",
        "json": "JSON File",
        "xml": "XML File",

        // Images
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

        // Videos
        "mp4": "MP4 Video",
        "mov": "QuickTime Movie",
        "avi": "AVI Video",
        "mkv": "MKV Video",

        // Audio
        "mp3": "MP3 Audio",
        "wav": "WAV Audio",
        "aac": "AAC Audio",
        "flac": "FLAC Audio",

        // Archives
        "zip": "ZIP Archive",
        "rar": "RAR Archive",
        "7z": "7-Zip Archive",
        "tar": "TAR Archive",
        "gz": "GZIP Archive",
        "dmg": "Disk Image",
        "iso": "ISO Disk Image",
        "pkg": "macOS Installer",

        // Applications & Code
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

    /// Get human-readable description for a file extension
    /// - Parameter extension: File extension (without the dot)
    /// - Returns: Description of the file type, or "{EXT} File" if not found
    static func description(for extension: String) -> String {
        let lowercased = `extension`.lowercased()
        return typeMap[lowercased] ?? "\(`extension`.uppercased()) File"
    }

    /// Get description for a file, or "Folder" if it's a directory
    /// - Parameters:
    ///   - fileExtension: Optional file extension
    ///   - isDirectory: Whether the item is a directory
    /// - Returns: Human-readable description
    static func description(fileExtension: String?, isDirectory: Bool) -> String {
        if isDirectory {
            return "Folder"
        }

        guard let ext = fileExtension, !ext.isEmpty else {
            return "File"
        }

        return description(for: ext)
    }
}
