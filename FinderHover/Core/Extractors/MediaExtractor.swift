//
//  MediaExtractor.swift
//  FinderHover
//
//  Media metadata extraction functions (Image, Video, Audio)
//

import Foundation
import AppKit
import ImageIO
import AVFoundation

// MARK: - Media Metadata Extractor

enum MediaExtractor {

    /// Matches a 4-digit year in 1900-2099. Compiled once: hoisted out of the
    /// metadata-scanning loops in extractAudioMetadata where it was previously
    /// recompiled per metadata item.
    private static let yearRegex = try? NSRegularExpression(pattern: #"\b(19|20)\d{2}\b"#)

    // MARK: - EXIF Data Extraction

    static func extractEXIFData(from url: URL) -> EXIFData? {
        // Check if file is an image by extension (including WebP and AVIF)
        let imageExtensions = ["jpg", "jpeg", "png", "tiff", "tif", "heic", "heif", "raw", "cr2", "nef", "arw", "dng", "webp", "avif"]
        guard let ext = url.pathExtension.lowercased() as String?,
              imageExtensions.contains(ext) else {
            return nil
        }

        // Create image source from file
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        // Get image properties
        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return nil
        }

        // Extract EXIF dictionary
        let exifDict = imageProperties[kCGImagePropertyExifDictionary as String] as? [String: Any]
        let tiffDict = imageProperties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        let gpsDict = imageProperties[kCGImagePropertyGPSDictionary as String] as? [String: Any]

        // Extract camera and lens info
        var camera: String? = nil
        if let make = tiffDict?[kCGImagePropertyTIFFMake as String] as? String,
           let model = tiffDict?[kCGImagePropertyTIFFModel as String] as? String {
            camera = "\(make) \(model)".trimmingCharacters(in: .whitespaces)
        } else if let model = tiffDict?[kCGImagePropertyTIFFModel as String] as? String {
            camera = model
        }

        let lens = exifDict?[kCGImagePropertyExifLensModel as String] as? String

        // Extract focal length
        var focalLength: String? = nil
        if let fl = exifDict?[kCGImagePropertyExifFocalLength as String] as? Double {
            focalLength = String(format: "%.0fmm", fl)
        }

        // Extract aperture (f-number)
        var aperture: String? = nil
        if let fNumber = exifDict?[kCGImagePropertyExifFNumber as String] as? Double {
            aperture = String(format: "f/%.1f", fNumber)
        }

        // Extract shutter speed (exposure time)
        var shutterSpeed: String? = nil
        if let exposureTime = exifDict?[kCGImagePropertyExifExposureTime as String] as? Double,
           exposureTime > 0 {
            if exposureTime < 1 {
                shutterSpeed = String(format: "1/%.0f", 1.0 / exposureTime)
            } else {
                shutterSpeed = String(format: "%.1fs", exposureTime)
            }
        }

        // Extract ISO
        var iso: String? = nil
        if let isoArray = exifDict?[kCGImagePropertyExifISOSpeedRatings as String] as? [Int],
           let isoValue = isoArray.first {
            iso = "ISO \(isoValue)"
        }

        // Extract date taken
        var dateTaken: String? = nil
        if let dateString = exifDict?[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            dateTaken = DateFormatters.parseAndFormatExifDate(dateString)
        }

        // Extract image dimensions
        var imageSize: String? = nil
        if let width = imageProperties[kCGImagePropertyPixelWidth as String] as? Int,
           let height = imageProperties[kCGImagePropertyPixelHeight as String] as? Int {
            imageSize = "\(width) × \(height)"
        }

        // Extract color space
        var colorSpace: String? = nil
        if let colorModel = imageProperties[kCGImagePropertyColorModel as String] as? String {
            colorSpace = colorModel
        }

        // Extract GPS location
        var gpsLocation: String? = nil
        if let lat = gpsDict?[kCGImagePropertyGPSLatitude as String] as? Double,
           let latRef = gpsDict?[kCGImagePropertyGPSLatitudeRef as String] as? String,
           let lon = gpsDict?[kCGImagePropertyGPSLongitude as String] as? Double,
           let lonRef = gpsDict?[kCGImagePropertyGPSLongitudeRef as String] as? String {
            gpsLocation = String(format: "%.6f°%@, %.6f°%@", lat, latRef, lon, lonRef)
        }

        // Extract color profile (Display P3, sRGB, Adobe RGB, Rec.2020)
        var colorProfile: String? = nil
        if let profileName = imageProperties[kCGImagePropertyProfileName as String] as? String {
            colorProfile = profileName
        } else if let iccProfile = imageProperties["ProfileName"] as? String {
            colorProfile = iccProfile
        }

        // Extract bit depth
        var bitDepth: Int? = nil
        if let depth = imageProperties[kCGImagePropertyDepth as String] as? Int {
            bitDepth = depth
        }

        // Check for HDR gain map (HEIC/AVIF specific)
        var hasHDRGainMap: Bool? = nil
        var hdrFormat: String? = nil

        // Check HEIC-specific properties for HDR
        if let heicsDict = imageProperties["{HEICS}"] as? [String: Any] {
            // Check for HDR gain map
            if heicsDict["HasHDRGainMap"] as? Bool == true ||
               heicsDict["HDRGainMapVersion"] != nil {
                hasHDRGainMap = true
            }
        }

        // Check for auxiliary images (HDR gain map is stored as auxiliary)
        let auxDataCount = CGImageSourceGetCount(imageSource)
        if auxDataCount > 1 {
            // Multiple images might indicate HDR gain map
            for i in 1..<auxDataCount {
                if let auxProps = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) as? [String: Any] {
                    if auxProps[kCGImagePropertyImageCount as String] != nil {
                        // Has auxiliary data
                        if hasHDRGainMap == nil {
                            hasHDRGainMap = true
                        }
                    }
                }
            }
        }

        // Determine HDR format from color profile and transfer function
        if let profile = colorProfile {
            let profileLower = profile.lowercased()
            if profileLower.contains("bt.2100") || profileLower.contains("rec.2100") {
                if profileLower.contains("hlg") {
                    hdrFormat = "HLG"
                } else if profileLower.contains("pq") {
                    hdrFormat = "HDR10"
                }
            } else if profileLower.contains("display p3") {
                // P3 with high bit depth might be HDR
                if let depth = bitDepth, depth > 8 {
                    hdrFormat = "HDR (P3)"
                }
            } else if profileLower.contains("bt.2020") || profileLower.contains("rec.2020") {
                hdrFormat = "HDR (BT.2020)"
            }
        }

        // Check for Dolby Vision in MakerNote (for some cameras)
        if let makerNote = exifDict?[kCGImagePropertyExifMakerNote as String] as? Data {
            let makerNoteString = String(data: makerNote, encoding: .ascii) ?? ""
            if makerNoteString.contains("Dolby") {
                hdrFormat = "Dolby Vision"
            }
        }

        // Only return EXIF data if at least one field has data
        let exifData = EXIFData(
            camera: camera,
            lens: lens,
            focalLength: focalLength,
            aperture: aperture,
            shutterSpeed: shutterSpeed,
            iso: iso,
            dateTaken: dateTaken,
            imageSize: imageSize,
            colorSpace: colorSpace,
            gpsLocation: gpsLocation,
            colorProfile: colorProfile,
            bitDepth: bitDepth,
            hasHDRGainMap: hasHDRGainMap,
            hdrFormat: hdrFormat
        )

        return exifData.hasData ? exifData : nil
    }

    // MARK: - Video Metadata Extraction

    static func extractVideoMetadata(from url: URL) async -> VideoMetadata? {
        // Check if file is a video by extension
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv", "flv", "wmv", "webm", "mpeg", "mpg", "3gp", "mts", "m2ts"]
        guard let ext = url.pathExtension.lowercased() as String?,
              videoExtensions.contains(ext) else {
            return nil
        }

        let asset = AVURLAsset(url: url)

        // Extract duration. A failed load degrades to no duration, matching the
        // prior guard that ignored non-finite/non-positive values.
        var duration: String? = nil
        if let assetDuration = try? await asset.load(.duration) {
            let durationSeconds = CMTimeGetSeconds(assetDuration)
            if durationSeconds.isFinite && durationSeconds > 0 {
                let hours = Int(durationSeconds) / 3600
                let minutes = Int(durationSeconds) % 3600 / 60
                let seconds = Int(durationSeconds) % 60

                if hours > 0 {
                    duration = String(format: "%d:%02d:%02d", hours, minutes, seconds)
                } else {
                    duration = String(format: "%d:%02d", minutes, seconds)
                }
            }
        }

        // Extract video track information
        var resolution: String? = nil
        var codec: String? = nil
        var frameRate: String? = nil
        var videoTrackCount = 0
        var audioTrackCount = 0

        let videoTracks = (try? await asset.loadTracks(withMediaType: .video)) ?? []
        videoTrackCount = videoTracks.count

        // Format descriptions of the primary video track, loaded once and reused
        // for codec and HDR detection below.
        var videoFormatDescriptions: [CMFormatDescription] = []

        if let videoTrack = videoTracks.first {
            // Get resolution
            if let naturalSize = try? await videoTrack.load(.naturalSize),
               let preferredTransform = try? await videoTrack.load(.preferredTransform) {
                let size = naturalSize.applying(preferredTransform)
                let width = abs(Int(size.width))
                let height = abs(Int(size.height))
                resolution = "\(width) × \(height)"
            }

            // Get frame rate
            if let fps = try? await videoTrack.load(.nominalFrameRate), fps > 0 {
                frameRate = String(format: "%.0f fps", fps)
            }

            // Get codec
            videoFormatDescriptions = (try? await videoTrack.load(.formatDescriptions)) ?? []
            if let formatDescription = videoFormatDescriptions.first {
                let codecType = CMFormatDescriptionGetMediaSubType(formatDescription)
                let codecString = fourCCToString(codecType)
                codec = codecString
            }
        }

        // Count audio tracks
        let audioTracks = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
        audioTrackCount = audioTracks.count

        // Extract bitrate
        var bitrate: String? = nil
        if let videoTrack = videoTracks.first,
           let estimatedDataRate = try? await videoTrack.load(.estimatedDataRate) {
            let bitrateKbps = estimatedDataRate / 1000
            if bitrateKbps >= 1000 {
                bitrate = String(format: "%.1f Mbps", bitrateKbps / 1000)
            } else {
                bitrate = String(format: "%.0f kbps", bitrateKbps)
            }
        }

        // Extract HDR information
        var hdrFormat: String? = nil
        var colorPrimaries: String? = nil
        var transferFunction: String? = nil

        if let formatDescription = videoFormatDescriptions.first {

            // Get color primaries
            if let primaries = CMFormatDescriptionGetExtension(formatDescription, extensionKey: kCMFormatDescriptionExtension_ColorPrimaries) as? String {
                switch primaries {
                case "ITU_R_709_2":
                    colorPrimaries = "BT.709"
                case "ITU_R_2020":
                    colorPrimaries = "BT.2020"
                case "P3_D65", "P3_DCI":
                    colorPrimaries = "P3"
                default:
                    colorPrimaries = primaries
                }
            }

            // Get transfer function to determine HDR type
            if let transfer = CMFormatDescriptionGetExtension(formatDescription, extensionKey: kCMFormatDescriptionExtension_TransferFunction) as? String {
                switch transfer {
                case "ITU_R_709_2", "ITU_R_601_4":
                    transferFunction = "SDR"
                case "SMPTE_ST_2084_PQ":
                    transferFunction = "PQ"
                case "ITU_R_2100_HLG", "ARIB_STD_B67":
                    transferFunction = "HLG"
                default:
                    transferFunction = transfer
                }
            }

            // Determine HDR format based on codec and transfer function
            if transferFunction == "PQ" || transferFunction == "HLG" {
                // Check for Dolby Vision across the already-loaded video tracks'
                // format descriptions.
                var hasDolbyVision = false
                for track in videoTracks {
                    let formats = (try? await track.load(.formatDescriptions)) ?? []
                    let trackHasDolbyVision = formats.contains { desc in
                        let codecType = CMFormatDescriptionGetMediaSubType(desc)
                        // Dolby Vision codec types: dvh1, dvhe, dva1, dvav
                        let codecStr = fourCCToString(codecType)
                        return codecStr.hasPrefix("dvh") || codecStr.hasPrefix("dva")
                    }
                    if trackHasDolbyVision {
                        hasDolbyVision = true
                        break
                    }
                }

                if hasDolbyVision {
                    hdrFormat = "Dolby Vision"
                } else if transferFunction == "HLG" {
                    hdrFormat = "HLG"
                } else if transferFunction == "PQ" {
                    hdrFormat = "HDR10"
                }
            } else {
                hdrFormat = "SDR"
            }
        }

        // Determine container format
        var containerFormat: String? = nil
        switch ext {
        case "mkv":
            containerFormat = "Matroska (MKV)"
        case "webm":
            containerFormat = "WebM"
        case "mp4", "m4v":
            containerFormat = "MPEG-4"
        case "mov":
            containerFormat = "QuickTime"
        case "avi":
            containerFormat = "AVI"
        case "flv":
            containerFormat = "Flash Video"
        case "wmv":
            containerFormat = "Windows Media"
        case "mpeg", "mpg":
            containerFormat = "MPEG"
        case "3gp":
            containerFormat = "3GPP"
        case "mts", "m2ts":
            containerFormat = "MPEG-2 Transport Stream"
        default:
            containerFormat = ext.uppercased()
        }

        // Extract chapter count (if available)
        var chapterCount: Int? = nil
        let chapterMetadataGroups = (try? await asset.loadChapterMetadataGroups(bestMatchingPreferredLanguages: ["en", "*"])) ?? []
        if !chapterMetadataGroups.isEmpty {
            chapterCount = chapterMetadataGroups.count
        }

        // Extract subtitle track count
        var subtitleTracks: Int? = nil
        let subtitleTrackCount = ((try? await asset.loadTracks(withMediaType: .text)) ?? []).count
        if subtitleTrackCount > 0 {
            subtitleTracks = subtitleTrackCount
        }

        // Also check for closed caption tracks
        let closedCaptionCount = ((try? await asset.loadTracks(withMediaType: .closedCaption)) ?? []).count
        if closedCaptionCount > 0 {
            subtitleTracks = (subtitleTracks ?? 0) + closedCaptionCount
        }

        // Check for embedded artwork/attachments via metadata
        var attachmentCount: Int? = nil
        let commonMetadata = (try? await asset.load(.commonMetadata)) ?? []
        let artworkItems = AVMetadataItem.metadataItems(from: commonMetadata, filteredByIdentifier: .commonIdentifierArtwork)
        if !artworkItems.isEmpty {
            attachmentCount = artworkItems.count
        }

        let metadata = VideoMetadata(
            duration: duration,
            resolution: resolution,
            codec: codec,
            frameRate: frameRate,
            bitrate: bitrate,
            videoTracks: videoTrackCount > 0 ? videoTrackCount : nil,
            audioTracks: audioTrackCount > 0 ? audioTrackCount : nil,
            hdrFormat: hdrFormat,
            colorPrimaries: colorPrimaries,
            transferFunction: transferFunction,
            chapterCount: chapterCount,
            subtitleTracks: subtitleTracks,
            attachmentCount: attachmentCount,
            containerFormat: containerFormat
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Audio Metadata Extraction

    static func extractAudioMetadata(from url: URL) async -> AudioMetadata? {
        // Check if file is an audio by extension
        let audioExtensions = ["mp3", "m4a", "aac", "wav", "flac", "aiff", "aif", "wma", "ogg", "opus", "alac"]
        guard let ext = url.pathExtension.lowercased() as String?,
              audioExtensions.contains(ext) else {
            return nil
        }

        let asset = AVURLAsset(url: url)

        // Extract common metadata
        var title: String? = nil
        var artist: String? = nil
        var album: String? = nil
        var albumArtist: String? = nil
        var genre: String? = nil
        var year: String? = nil

        let commonMetadata = (try? await asset.load(.commonMetadata)) ?? []
        for item in commonMetadata {
            // load(.stringValue) yields String?; flatten the try? wrapper so the
            // guard still skips items without a string value, as before.
            guard let key = item.commonKey?.rawValue,
                  let value = (try? await item.load(.stringValue)) ?? nil else { continue }

            switch key {
            case "title":
                title = value
            case "artist":
                artist = value
            case "albumName":
                album = value
            case "type":
                genre = value
            case "creator":
                if artist == nil {
                    artist = value
                }
            default:
                break
            }
        }

        // Try to extract album artist and year from format-specific metadata
        let availableMetadataFormats = (try? await asset.load(.availableMetadataFormats)) ?? []
        for format in availableMetadataFormats {
            let metadata = (try? await asset.loadMetadata(for: format)) ?? []

            for item in metadata {
                if let key = item.commonKey?.rawValue {
                    switch key {
                    case "artist":
                        if albumArtist == nil, let value = (try? await item.load(.stringValue)) ?? nil {
                            albumArtist = value
                        }
                    default:
                        break
                    }
                }

                // Try to get year from creation date
                if item.identifier?.rawValue.contains("creationDate") == true ||
                   item.identifier?.rawValue.contains("year") == true {
                    if let value = try? await item.load(.stringValue), year == nil {
                        // Extract year from date string using the hoisted regex.
                        if let match = Self.yearRegex?.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) {
                            if let range = Range(match.range, in: value) {
                                year = String(value[range])
                            }
                        }
                    }
                }
            }
        }

        // Extract duration
        var duration: String? = nil
        if let assetDuration = try? await asset.load(.duration) {
            let durationSeconds = CMTimeGetSeconds(assetDuration)
            if durationSeconds.isFinite && durationSeconds > 0 {
                let minutes = Int(durationSeconds) / 60
                let seconds = Int(durationSeconds) % 60
                duration = String(format: "%d:%02d", minutes, seconds)
            }
        }

        // Extract audio track information
        var bitrate: String? = nil
        var sampleRate: String? = nil
        var channels: String? = nil

        let audioTracks = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
        if let audioTrack = audioTracks.first {
            // Get bitrate
            if let estimatedDataRate = try? await audioTrack.load(.estimatedDataRate),
               estimatedDataRate > 0 {
                bitrate = String(format: "%.0f kbps", estimatedDataRate / 1000)
            }

            // Get format descriptions for sample rate and channels
            let formatDescriptions = (try? await audioTrack.load(.formatDescriptions)) ?? []
            if let formatDescription = formatDescriptions.first {
                if let streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
                    let sampleRateHz = streamBasicDescription.pointee.mSampleRate
                    if sampleRateHz > 0 {
                        if sampleRateHz >= 1000 {
                            sampleRate = String(format: "%.1f kHz", sampleRateHz / 1000)
                        } else {
                            sampleRate = String(format: "%.0f Hz", sampleRateHz)
                        }
                    }

                    let channelCount = streamBasicDescription.pointee.mChannelsPerFrame
                    switch channelCount {
                    case 1:
                        channels = "Mono"
                    case 2:
                        channels = "Stereo"
                    default:
                        if channelCount > 0 {
                            channels = "\(channelCount) channels"
                        }
                    }
                }
            }
        }

        let metadata = AudioMetadata(
            title: title,
            artist: artist,
            album: album,
            albumArtist: albumArtist,
            genre: genre,
            year: year,
            duration: duration,
            bitrate: bitrate,
            sampleRate: sampleRate,
            channels: channels
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Extended Image Metadata Extraction (IPTC/XMP)

    static func extractImageExtendedMetadata(from url: URL) -> ImageExtendedMetadata? {
        // Check if file is an image by extension
        let imageExtensions = ["jpg", "jpeg", "png", "tiff", "tif", "heic", "heif", "raw", "cr2", "nef", "arw", "dng", "psd"]
        guard let ext = url.pathExtension.lowercased() as String?,
              imageExtensions.contains(ext) else {
            return nil
        }

        // Create image source from file
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        // Get image properties
        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return nil
        }

        // Extract IPTC dictionary
        let iptcDict = imageProperties[kCGImagePropertyIPTCDictionary as String] as? [String: Any]

        // Extract TIFF dictionary for copyright
        let tiffDict = imageProperties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]

        // Extract copyright
        var copyright: String? = nil
        if let iptcCopyright = iptcDict?[kCGImagePropertyIPTCCopyrightNotice as String] as? String {
            copyright = iptcCopyright
        } else if let tiffCopyright = tiffDict?[kCGImagePropertyTIFFCopyright as String] as? String {
            copyright = tiffCopyright
        }

        // Extract creator
        var creator: String? = nil
        if let bylineArray = iptcDict?[kCGImagePropertyIPTCByline as String] as? [String], !bylineArray.isEmpty {
            creator = bylineArray.joined(separator: ", ")
        } else if let artist = tiffDict?[kCGImagePropertyTIFFArtist as String] as? String {
            creator = artist
        }

        // Extract keywords
        var keywords: String? = nil
        if let keywordArray = iptcDict?[kCGImagePropertyIPTCKeywords as String] as? [String], !keywordArray.isEmpty {
            keywords = keywordArray.joined(separator: ", ")
        }

        // Extract rating (from XMP if available)
        var rating: Int? = nil

        // Try to get rating using MDItem
        if let mdItem = MDItemCreate(kCFAllocatorDefault, url.path as CFString) {
            if let ratingValue = MDItemCopyAttribute(mdItem, "kMDItemStarRating" as CFString) as? Int {
                rating = ratingValue
            }
        }

        // Extract creator tool
        var creatorTool: String? = nil
        if let software = tiffDict?[kCGImagePropertyTIFFSoftware as String] as? String {
            creatorTool = software
        }

        // Extract description/caption
        var description: String? = nil
        if let captionAbstract = iptcDict?[kCGImagePropertyIPTCCaptionAbstract as String] as? String {
            description = captionAbstract
        }

        // Extract headline
        var headline: String? = nil
        if let iptcHeadline = iptcDict?[kCGImagePropertyIPTCHeadline as String] as? String {
            headline = iptcHeadline
        }

        let metadata = ImageExtendedMetadata(
            copyright: copyright,
            creator: creator,
            keywords: keywords,
            rating: rating,
            creatorTool: creatorTool,
            description: description,
            headline: headline
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Helper Functions

    /// Convert FourCharCode to String
    static func fourCCToString(_ value: FourCharCode) -> String {
        let bytes: [CChar] = [
            CChar(truncatingIfNeeded: (value >> 24) & 0xFF),
            CChar(truncatingIfNeeded: (value >> 16) & 0xFF),
            CChar(truncatingIfNeeded: (value >> 8) & 0xFF),
            CChar(truncatingIfNeeded: value & 0xFF),
            0
        ]
        return String(cString: bytes)
    }
}

// Convenience function for backward compatibility
func fourCCToString(_ value: FourCharCode) -> String {
    return MediaExtractor.fourCCToString(value)
}
