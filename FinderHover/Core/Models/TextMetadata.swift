//
//  TextMetadata.swift
//  FinderHover
//
//  Text-related metadata structures (Subtitle, Font)
//

import Foundation

// MARK: - Subtitle Metadata Structure
struct SubtitleMetadata {
    let format: String?           // Subtitle format (SRT, VTT, ASS, etc.)
    let encoding: String?         // Text encoding (UTF-8, etc.)
    let entryCount: Int?          // Number of subtitle entries
    let duration: String?         // Total duration
    let language: String?         // Language code
    let frameRate: String?        // Frame rate (for frame-based formats)
    let hasFormatting: Bool?      // Whether subtitles contain rich formatting

    var hasData: Bool {
        return format != nil || encoding != nil || entryCount != nil ||
               duration != nil || language != nil || frameRate != nil || hasFormatting != nil
    }
}

// MARK: - Font Metadata Structure
struct FontMetadata {
    let fontName: String?         // Full font name
    let fontFamily: String?       // Font family name
    let fontStyle: String?        // Font style (Regular, Bold, Italic, etc.)
    let version: String?          // Font version
    let designer: String?         // Font designer/creator
    let copyright: String?        // Copyright information
    let glyphCount: Int?          // Number of glyphs

    var hasData: Bool {
        return fontName != nil || fontFamily != nil || fontStyle != nil ||
               version != nil || designer != nil || copyright != nil || glyphCount != nil
    }
}
