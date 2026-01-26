//
//  MediaMetadata.swift
//  FinderHover
//
//  Media-related metadata structures (Image, Video, Audio)
//

import Foundation

// MARK: - EXIF Data Structure
struct EXIFData {
    let camera: String?
    let lens: String?
    let focalLength: String?
    let aperture: String?
    let shutterSpeed: String?
    let iso: String?
    let dateTaken: String?
    let imageSize: String?
    let colorSpace: String?
    let gpsLocation: String?
    // HDR/Color fields
    let colorProfile: String?         // Display P3, sRGB, Adobe RGB, Rec.2020
    let bitDepth: Int?                // 8, 10, 12, 16 bit
    let hasHDRGainMap: Bool?          // Has HDR gain map (for HEIC/AVIF)
    let hdrFormat: String?            // HDR10, HLG, Dolby Vision

    var hasData: Bool {
        return camera != nil || lens != nil || focalLength != nil ||
               aperture != nil || shutterSpeed != nil || iso != nil ||
               dateTaken != nil || imageSize != nil || colorSpace != nil ||
               gpsLocation != nil || colorProfile != nil || bitDepth != nil ||
               hasHDRGainMap != nil || hdrFormat != nil
    }
}

// MARK: - Video Metadata Structure
struct VideoMetadata {
    let duration: String?
    let resolution: String?
    let codec: String?
    let frameRate: String?
    let bitrate: String?
    let videoTracks: Int?
    let audioTracks: Int?
    let hdrFormat: String?        // Dolby Vision, HDR10, HDR10+, HLG, SDR
    let colorPrimaries: String?   // BT.709, BT.2020, P3
    let transferFunction: String? // SDR, PQ, HLG
    // MKV/WebM specific fields
    let chapterCount: Int?        // Number of chapters
    let subtitleTracks: Int?      // Number of subtitle tracks
    let attachmentCount: Int?     // Number of attachments (fonts, cover art)
    let containerFormat: String?  // MKV, WebM, MP4, MOV, etc.

    var hasData: Bool {
        return duration != nil || resolution != nil || codec != nil ||
               frameRate != nil || bitrate != nil || videoTracks != nil ||
               audioTracks != nil || hdrFormat != nil || colorPrimaries != nil ||
               transferFunction != nil || chapterCount != nil || subtitleTracks != nil ||
               attachmentCount != nil || containerFormat != nil
    }
}

// MARK: - Audio Metadata Structure
struct AudioMetadata {
    let title: String?
    let artist: String?
    let album: String?
    let albumArtist: String?
    let genre: String?
    let year: String?
    let duration: String?
    let bitrate: String?
    let sampleRate: String?
    let channels: String?

    var hasData: Bool {
        return title != nil || artist != nil || album != nil ||
               albumArtist != nil || genre != nil || year != nil ||
               duration != nil || bitrate != nil || sampleRate != nil ||
               channels != nil
    }
}

// MARK: - Extended Image Metadata Structure (IPTC/XMP)
struct ImageExtendedMetadata {
    let copyright: String?
    let creator: String?
    let keywords: String?          // Comma-separated keywords
    let rating: Int?               // 0-5 stars
    let creatorTool: String?       // Application used to create
    let description: String?
    let headline: String?

    var hasData: Bool {
        return copyright != nil || creator != nil || keywords != nil ||
               rating != nil || creatorTool != nil || description != nil || headline != nil
    }
}
