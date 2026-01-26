//
//  TextExtractor.swift
//  FinderHover
//
//  Text-related metadata extraction (Subtitle, Font)
//

import Foundation
import AppKit

// MARK: - Text Metadata Extractor

enum TextExtractor {

    // MARK: - Subtitle Metadata Extraction

    static func extractSubtitleMetadata(from url: URL) -> SubtitleMetadata? {
        let ext = url.pathExtension.lowercased()
        let subtitleExtensions = ["srt", "vtt", "ass", "ssa", "sub", "idx", "smi"]

        guard subtitleExtensions.contains(ext) else {
            return nil
        }

        var format: String? = nil
        var encoding: String? = nil
        var entryCount: Int? = nil
        var duration: String? = nil
        var language: String? = nil
        var frameRate: String? = nil
        var hasFormatting: Bool? = nil

        // Determine format
        switch ext {
        case "srt":
            format = "SubRip"
        case "vtt":
            format = "WebVTT"
        case "ass", "ssa":
            format = "Advanced SubStation Alpha"
        case "sub":
            format = "MicroDVD"
        case "idx":
            format = "VobSub Index"
        case "smi":
            format = "SAMI"
        default:
            format = ext.uppercased()
        }

        // Try to read and parse the file
        guard let data = try? Data(contentsOf: url) else {
            return SubtitleMetadata(
                format: format,
                encoding: nil,
                entryCount: nil,
                duration: nil,
                language: nil,
                frameRate: nil,
                hasFormatting: nil
            )
        }

        // Detect encoding
        encoding = detectEncoding(data: data)

        // Parse content
        if let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
            let lines = content.components(separatedBy: .newlines)

            switch ext {
            case "srt":
                // Count entries (numeric lines followed by timestamps)
                var count = 0
                var lastTimestamp: String? = nil

                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.contains(" --> ") {
                        count += 1
                        lastTimestamp = trimmed
                    }
                    // Check for formatting tags
                    if trimmed.contains("<") && trimmed.contains(">") {
                        hasFormatting = true
                    }
                }

                entryCount = count

                // Extract duration from last timestamp
                if let timestamp = lastTimestamp {
                    let parts = timestamp.components(separatedBy: " --> ")
                    if parts.count == 2 {
                        duration = parts[1].components(separatedBy: ",").first
                    }
                }

            case "vtt":
                // Similar to SRT
                var count = 0
                var lastTimestamp: String? = nil

                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.contains(" --> ") {
                        count += 1
                        lastTimestamp = trimmed
                    }
                }

                entryCount = count
                hasFormatting = content.contains("<c>") || content.contains("<v ")

                if let timestamp = lastTimestamp {
                    let parts = timestamp.components(separatedBy: " --> ")
                    if parts.count == 2 {
                        duration = parts[1].components(separatedBy: ".").first
                    }
                }

            case "ass", "ssa":
                // Count [Events] section entries
                var inEventsSection = false
                var count = 0

                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed == "[Events]" {
                        inEventsSection = true
                    } else if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                        inEventsSection = false
                    } else if inEventsSection && trimmed.hasPrefix("Dialogue:") {
                        count += 1
                    }
                }

                entryCount = count
                hasFormatting = true // ASS always has formatting

            default:
                break
            }
        }

        let metadata = SubtitleMetadata(
            format: format,
            encoding: encoding,
            entryCount: entryCount,
            duration: duration,
            language: language,
            frameRate: frameRate,
            hasFormatting: hasFormatting
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Font Metadata Extraction

    static func extractFontMetadata(from url: URL) -> FontMetadata? {
        let ext = url.pathExtension.lowercased()
        let fontExtensions = ["ttf", "otf", "woff", "woff2", "ttc", "dfont"]

        guard fontExtensions.contains(ext) else {
            return nil
        }

        var fontName: String? = nil
        var fontFamily: String? = nil
        var fontStyle: String? = nil
        var version: String? = nil
        var designer: String? = nil
        var copyright: String? = nil
        var glyphCount: Int? = nil

        // Use Core Text to get font information
        guard let fontDescriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let fontDescriptor = fontDescriptors.first else {
            return nil
        }

        // Create font from descriptor
        let font = CTFontCreateWithFontDescriptor(fontDescriptor, 0, nil)

        // Get font name
        fontName = CTFontCopyFullName(font) as String?

        // Get family name
        fontFamily = CTFontCopyFamilyName(font) as String?

        // Get style name
        if let traits = CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontTraitsAttribute) as? [String: Any],
           let symbolicTraits = traits[kCTFontSymbolicTrait as String] as? UInt32 {
            var styles: [String] = []

            if symbolicTraits & UInt32(CTFontSymbolicTraits.boldTrait.rawValue) != 0 {
                styles.append("Bold")
            }
            if symbolicTraits & UInt32(CTFontSymbolicTraits.italicTrait.rawValue) != 0 {
                styles.append("Italic")
            }
            if symbolicTraits & UInt32(CTFontSymbolicTraits.monoSpaceTrait.rawValue) != 0 {
                styles.append("Monospace")
            }

            if styles.isEmpty {
                fontStyle = "Regular"
            } else {
                fontStyle = styles.joined(separator: " ")
            }
        }

        // Get glyph count
        glyphCount = Int(CTFontGetGlyphCount(font))

        // Get version (from name table)
        if let versionString = CTFontCopyName(font, kCTFontVersionNameKey) as String? {
            version = versionString
        }

        // Get copyright
        if let copyrightString = CTFontCopyName(font, kCTFontCopyrightNameKey) as String? {
            copyright = copyrightString
        }

        // Get designer
        if let designerString = CTFontCopyName(font, kCTFontDesignerNameKey) as String? {
            designer = designerString
        }

        let metadata = FontMetadata(
            fontName: fontName,
            fontFamily: fontFamily,
            fontStyle: fontStyle,
            version: version,
            designer: designer,
            copyright: copyright,
            glyphCount: glyphCount
        )

        return metadata.hasData ? metadata : nil
    }
}
