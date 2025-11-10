//
//  FileInfo.swift
//  FinderHover
//
//  File metadata model
//

import Foundation
import AppKit
import QuickLookThumbnailing
import ImageIO
import AVFoundation
import PDFKit

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

    var hasData: Bool {
        return camera != nil || lens != nil || focalLength != nil ||
               aperture != nil || shutterSpeed != nil || iso != nil ||
               dateTaken != nil || imageSize != nil || colorSpace != nil ||
               gpsLocation != nil
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

    var hasData: Bool {
        return duration != nil || resolution != nil || codec != nil ||
               frameRate != nil || bitrate != nil || videoTracks != nil ||
               audioTracks != nil
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

// MARK: - PDF Metadata Structure
struct PDFMetadata {
    let title: String?
    let author: String?
    let subject: String?
    let creator: String?
    let producer: String?
    let creationDate: String?
    let modificationDate: String?
    let pageCount: Int?
    let pageSize: String?
    let version: String?
    let isEncrypted: Bool?
    let keywords: String?

    var hasData: Bool {
        return title != nil || author != nil || subject != nil ||
               creator != nil || producer != nil || creationDate != nil ||
               modificationDate != nil || pageCount != nil || pageSize != nil ||
               version != nil || isEncrypted != nil || keywords != nil
    }
}

// MARK: - Office Document Metadata Structure
struct OfficeMetadata {
    let title: String?
    let author: String?
    let subject: String?
    let keywords: String?
    let comment: String?
    let lastModifiedBy: String?
    let creationDate: String?
    let modificationDate: String?
    let pageCount: Int?        // For Word documents
    let wordCount: Int?        // For Word documents
    let sheetCount: Int?       // For Excel documents
    let slideCount: Int?       // For PowerPoint documents
    let company: String?
    let category: String?

    var hasData: Bool {
        return title != nil || author != nil || subject != nil ||
               keywords != nil || comment != nil || lastModifiedBy != nil ||
               creationDate != nil || modificationDate != nil || pageCount != nil ||
               wordCount != nil || sheetCount != nil || slideCount != nil ||
               company != nil || category != nil
    }
}

// MARK: - Archive Metadata Structure
struct ArchiveMetadata {
    let format: String?           // ZIP, RAR, 7Z, TAR, GZ, etc.
    let fileCount: Int?           // Number of files in archive
    let uncompressedSize: UInt64? // Total uncompressed size
    let compressionRatio: Double? // Compression ratio percentage
    let isEncrypted: Bool?        // Whether archive is password protected
    let comment: String?          // Archive comment (ZIP)

    var hasData: Bool {
        return format != nil || fileCount != nil || uncompressedSize != nil ||
               compressionRatio != nil || isEncrypted != nil || comment != nil
    }
}

// MARK: - E-book Metadata Structure
struct EbookMetadata {
    let title: String?            // Book title
    let author: String?           // Author(s)
    let publisher: String?        // Publisher
    let publicationDate: String?  // Publication date
    let isbn: String?             // ISBN
    let language: String?         // Language
    let description: String?      // Book description/summary
    let pageCount: Int?           // Number of pages

    var hasData: Bool {
        return title != nil || author != nil || publisher != nil ||
               publicationDate != nil || isbn != nil || language != nil ||
               description != nil || pageCount != nil
    }
}

// MARK: - Code File Metadata Structure
struct CodeMetadata {
    let language: String?         // Programming language
    let lineCount: Int?           // Total lines
    let codeLines: Int?           // Lines of code (excluding blank and comments)
    let commentLines: Int?        // Comment lines
    let blankLines: Int?          // Blank lines
    let encoding: String?         // File encoding (UTF-8, ASCII, etc.)

    var hasData: Bool {
        return language != nil || lineCount != nil || codeLines != nil ||
               commentLines != nil || blankLines != nil || encoding != nil
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

// MARK: - Disk Image Metadata Structure
struct DiskImageMetadata {
    let format: String?           // Image format (UDIF, UDZO, UDBZ, ISO 9660, etc.)
    let totalSize: Int64?         // Total size in bytes
    let compressedSize: Int64?    // Compressed size in bytes (if applicable)
    let compressionRatio: String? // Compression ratio (e.g., "2.5:1")
    let isEncrypted: Bool?        // Whether the image is encrypted
    let partitionScheme: String?  // Partition scheme (GPT, APM, MBR, etc.)
    let fileSystem: String?       // File system (HFS+, APFS, ISO 9660, etc.)
    
    var hasData: Bool {
        return format != nil || totalSize != nil || compressedSize != nil ||
               compressionRatio != nil || isEncrypted != nil || partitionScheme != nil || fileSystem != nil
    }
}

// MARK: - Vector Graphics Metadata Structure
struct VectorGraphicsMetadata {
    let format: String?           // Format type (SVG, EPS, AI, etc.)
    let dimensions: String?       // Width x Height
    let viewBox: String?          // ViewBox for SVG
    let elementCount: Int?        // Number of paths/shapes
    let colorMode: String?        // Color mode (RGB, CMYK, etc.)
    let creator: String?          // Creator application
    let version: String?          // Format version (e.g., SVG 1.1)
    
    var hasData: Bool {
        return format != nil || dimensions != nil || viewBox != nil ||
               elementCount != nil || colorMode != nil || creator != nil || version != nil
    }
}

struct FileInfo {
    let name: String
    let path: String
    let size: Int64
    let modificationDate: Date
    let creationDate: Date
    let fileType: String
    let isDirectory: Bool
    let fileExtension: String?

    // Additional metadata
    let lastAccessDate: Date?
    let permissions: String
    let owner: String
    let isReadable: Bool
    let isWritable: Bool
    let isExecutable: Bool
    let itemCount: Int? // For directories
    let isHidden: Bool

    // EXIF data for images
    let exifData: EXIFData?

    // Video metadata
    let videoMetadata: VideoMetadata?

    // Audio metadata
    let audioMetadata: AudioMetadata?

    // PDF metadata
    let pdfMetadata: PDFMetadata?

    // Office document metadata
    let officeMetadata: OfficeMetadata?

    // Archive metadata
    let archiveMetadata: ArchiveMetadata?

    // E-book metadata
    let ebookMetadata: EbookMetadata?

    // Code file metadata
    let codeMetadata: CodeMetadata?

    // Font metadata
    let fontMetadata: FontMetadata?
    
    // Disk image metadata
    let diskImageMetadata: DiskImageMetadata?
    
    // Vector graphics metadata
    let vectorGraphicsMetadata: VectorGraphicsMetadata?

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedModificationDate: String {
        return DateFormatters.formatMediumDateTime(modificationDate)
    }

    var formattedLastAccessDate: String {
        guard let date = lastAccessDate else { return "N/A" }
        return DateFormatters.formatShortDateTime(date)
    }

    var formattedCreationDate: String {
        return DateFormatters.formatShortDateTime(creationDate)
    }

    var formattedPermissions: String {
        var result = ""
        result += isReadable ? "r" : "-"
        result += isWritable ? "w" : "-"
        result += isExecutable ? "x" : "-"
        return "\(permissions) (\(result))"
    }

    var icon: NSImage {
        // Always return standard icon immediately
        // Thumbnail will be generated asynchronously
        return NSWorkspace.shared.icon(forFile: path)
    }

    func generateThumbnailAsync(completion: @escaping (NSImage?) -> Void) {
        let url = URL(fileURLWithPath: path)
        let size = CGSize(
            width: Constants.Thumbnail.standardSize,
            height: Constants.Thumbnail.standardSize
        )
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0

        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )

        QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnail, type, error in
            DispatchQueue.main.async {
                completion(thumbnail?.nsImage)
            }
        }
    }

    static func from(path: String) -> FileInfo? {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: path) else {
            Logger.debug("File does not exist: \(path)", subsystem: .fileSystem)
            return nil
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let url = URL(fileURLWithPath: path)
            let isDir = (attributes[.type] as? FileAttributeType) == .typeDirectory

            // Get permissions
            let posixPermissions = attributes[.posixPermissions] as? Int ?? 0
            let permissionsString = String(format: "%03o", posixPermissions)

            // Get owner name
            let ownerName = attributes[.ownerAccountName] as? String ?? "Unknown"

            // Check if readable/writable/executable
            let isReadable = fileManager.isReadableFile(atPath: path)
            let isWritable = fileManager.isWritableFile(atPath: path)
            let isExecutable = fileManager.isExecutableFile(atPath: path)

            // Get item count for directories
            var itemCount: Int? = nil
            if isDir {
                do {
                    let contents = try fileManager.contentsOfDirectory(atPath: path)
                    itemCount = contents.count
                } catch {
                    Logger.error("Failed to read directory contents: \(path)", error: error, subsystem: .fileSystem)
                    itemCount = nil
                }
            }

            // Check if hidden (starts with .)
            let isHidden = url.lastPathComponent.hasPrefix(".")

            // Get last access date (may not be available on all file systems)
            let lastAccessDate = attributes[.modificationDate] as? Date

            // Extract EXIF data for image files
            let exifData = extractEXIFData(from: url)

            // Extract video metadata for video files
            let videoMetadata = extractVideoMetadata(from: url)

            // Extract audio metadata for audio files
            let audioMetadata = extractAudioMetadata(from: url)

            // Extract PDF metadata for PDF files
            let pdfMetadata = extractPDFMetadata(from: url)

            // Extract Office document metadata
            let officeMetadata = extractOfficeMetadata(from: url)

            // Extract Archive metadata
            let archiveMetadata = extractArchiveMetadata(from: url)

            // Extract E-book metadata
            let ebookMetadata = extractEbookMetadata(from: url)

            // Extract Code file metadata
            let codeMetadata = extractCodeMetadata(from: url)

            // Extract Font metadata
            let fontMetadata = extractFontMetadata(from: url)
            
            // Extract Disk Image metadata
            let diskImageMetadata = extractDiskImageMetadata(from: url)
            
            // Extract Vector Graphics metadata
            let vectorGraphicsMetadata = extractVectorGraphicsMetadata(from: url)

            return FileInfo(
                name: url.lastPathComponent,
                path: path,
                size: attributes[.size] as? Int64 ?? 0,
                modificationDate: attributes[.modificationDate] as? Date ?? Date(),
                creationDate: attributes[.creationDate] as? Date ?? Date(),
                fileType: attributes[.type] as? String ?? "Unknown",
                isDirectory: isDir,
                fileExtension: url.pathExtension.isEmpty ? nil : url.pathExtension,
                lastAccessDate: lastAccessDate,
                permissions: permissionsString,
                owner: ownerName,
                isReadable: isReadable,
                isWritable: isWritable,
                isExecutable: isExecutable,
                itemCount: itemCount,
                isHidden: isHidden,
                exifData: exifData,
                videoMetadata: videoMetadata,
                audioMetadata: audioMetadata,
                pdfMetadata: pdfMetadata,
                officeMetadata: officeMetadata,
                archiveMetadata: archiveMetadata,
                ebookMetadata: ebookMetadata,
                codeMetadata: codeMetadata,
                fontMetadata: fontMetadata,
                diskImageMetadata: diskImageMetadata,
                vectorGraphicsMetadata: vectorGraphicsMetadata
            )
        } catch {
            Logger.error("Failed to read file attributes: \(path)", error: error, subsystem: .fileSystem)
            return nil
        }
    }

    // MARK: - EXIF Extraction
    private static func extractEXIFData(from url: URL) -> EXIFData? {
        // Check if file is an image by extension
        let imageExtensions = ["jpg", "jpeg", "png", "tiff", "tif", "heic", "heif", "raw", "cr2", "nef", "arw", "dng"]
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
        if let exposureTime = exifDict?[kCGImagePropertyExifExposureTime as String] as? Double {
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
            gpsLocation: gpsLocation
        )

        return exifData.hasData ? exifData : nil
    }

    // MARK: - Video Metadata Extraction
    private static func extractVideoMetadata(from url: URL) -> VideoMetadata? {
        // Check if file is a video by extension
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv", "flv", "wmv", "webm", "mpeg", "mpg", "3gp", "mts", "m2ts"]
        guard let ext = url.pathExtension.lowercased() as String?,
              videoExtensions.contains(ext) else {
            return nil
        }

        let asset = AVURLAsset(url: url)

        // Extract duration
        var duration: String? = nil
        let durationSeconds = CMTimeGetSeconds(asset.duration)
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

        // Extract video track information
        var resolution: String? = nil
        var codec: String? = nil
        var frameRate: String? = nil
        var videoTrackCount = 0
        var audioTrackCount = 0

        let videoTracks = asset.tracks(withMediaType: .video)
        videoTrackCount = videoTracks.count

        if let videoTrack = videoTracks.first {
            // Get resolution
            let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
            let width = abs(Int(size.width))
            let height = abs(Int(size.height))
            resolution = "\(width) × \(height)"

            // Get frame rate
            let fps = videoTrack.nominalFrameRate
            if fps > 0 {
                frameRate = String(format: "%.0f fps", fps)
            }

            // Get codec
            if let formatDescriptions = videoTrack.formatDescriptions as? [CMFormatDescription],
               let formatDescription = formatDescriptions.first {
                let codecType = CMFormatDescriptionGetMediaSubType(formatDescription)
                let codecString = fourCCToString(codecType)
                codec = codecString
            }
        }

        // Count audio tracks
        let audioTracks = asset.tracks(withMediaType: .audio)
        audioTrackCount = audioTracks.count

        // Extract bitrate
        var bitrate: String? = nil
        if let estimatedDataRate = videoTracks.first?.estimatedDataRate {
            let bitrateKbps = estimatedDataRate / 1000
            if bitrateKbps >= 1000 {
                bitrate = String(format: "%.1f Mbps", bitrateKbps / 1000)
            } else {
                bitrate = String(format: "%.0f kbps", bitrateKbps)
            }
        }

        let metadata = VideoMetadata(
            duration: duration,
            resolution: resolution,
            codec: codec,
            frameRate: frameRate,
            bitrate: bitrate,
            videoTracks: videoTrackCount > 0 ? videoTrackCount : nil,
            audioTracks: audioTrackCount > 0 ? audioTrackCount : nil
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Audio Metadata Extraction
    private static func extractAudioMetadata(from url: URL) -> AudioMetadata? {
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

        for item in asset.commonMetadata {
            guard let key = item.commonKey?.rawValue,
                  let value = item.stringValue else { continue }

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
        for format in asset.availableMetadataFormats {
            let metadata = asset.metadata(forFormat: format)

            for item in metadata {
                if let key = item.commonKey?.rawValue {
                    switch key {
                    case "artist":
                        if albumArtist == nil, let value = item.stringValue {
                            albumArtist = value
                        }
                    default:
                        break
                    }
                }

                // Try to get year from creation date
                if item.identifier?.rawValue.contains("creationDate") == true ||
                   item.identifier?.rawValue.contains("year") == true {
                    if let value = item.stringValue, year == nil {
                        // Extract year from date string
                        let yearRegex = try? NSRegularExpression(pattern: "\\b(19|20)\\d{2}\\b")
                        if let match = yearRegex?.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) {
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
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        if durationSeconds.isFinite && durationSeconds > 0 {
            let minutes = Int(durationSeconds) / 60
            let seconds = Int(durationSeconds) % 60
            duration = String(format: "%d:%02d", minutes, seconds)
        }

        // Extract audio track information
        var bitrate: String? = nil
        var sampleRate: String? = nil
        var channels: String? = nil

        let audioTracks = asset.tracks(withMediaType: .audio)
        if let audioTrack = audioTracks.first {
            // Get bitrate
            let estimatedDataRate = audioTrack.estimatedDataRate
            if estimatedDataRate > 0 {
                bitrate = String(format: "%.0f kbps", estimatedDataRate / 1000)
            }

            // Get format descriptions for sample rate and channels
            if let formatDescriptions = audioTrack.formatDescriptions as? [CMFormatDescription],
               let formatDescription = formatDescriptions.first {
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

    // MARK: - PDF Metadata Extraction
    private static func extractPDFMetadata(from url: URL) -> PDFMetadata? {
        // Check if file is a PDF by extension
        guard url.pathExtension.lowercased() == "pdf" else {
            return nil
        }

        // Import PDFKit
        guard let pdfDocument = PDFDocument(url: url) else {
            return nil
        }

        // Extract basic document attributes
        let attributes = pdfDocument.documentAttributes

        // Extract title
        let title = attributes?[PDFDocumentAttribute.titleAttribute] as? String

        // Extract author
        let author = attributes?[PDFDocumentAttribute.authorAttribute] as? String

        // Extract subject
        let subject = attributes?[PDFDocumentAttribute.subjectAttribute] as? String

        // Extract creator (application that created the PDF)
        let creator = attributes?[PDFDocumentAttribute.creatorAttribute] as? String

        // Extract producer (PDF library used)
        let producer = attributes?[PDFDocumentAttribute.producerAttribute] as? String

        // Extract keywords
        let keywords = attributes?[PDFDocumentAttribute.keywordsAttribute] as? String

        // Extract creation date
        var creationDate: String? = nil
        if let date = attributes?[PDFDocumentAttribute.creationDateAttribute] as? Date {
            creationDate = DateFormatters.formatMediumDateTime(date)
        }

        // Extract modification date
        var modificationDate: String? = nil
        if let date = attributes?[PDFDocumentAttribute.modificationDateAttribute] as? Date {
            modificationDate = DateFormatters.formatMediumDateTime(date)
        }

        // Get page count
        let pageCount = pdfDocument.pageCount

        // Get page size (from first page)
        var pageSize: String? = nil
        if let firstPage = pdfDocument.page(at: 0) {
            let bounds = firstPage.bounds(for: .mediaBox)
            let width = bounds.width
            let height = bounds.height

            // Convert points to inches (1 inch = 72 points)
            let widthInches = width / 72.0
            let heightInches = height / 72.0

            // Check for common paper sizes
            if abs(widthInches - 8.5) < 0.1 && abs(heightInches - 11.0) < 0.1 {
                pageSize = "Letter (8.5\" × 11\")"
            } else if abs(widthInches - 11.0) < 0.1 && abs(heightInches - 17.0) < 0.1 {
                pageSize = "Tabloid (11\" × 17\")"
            } else if abs(width - 595.0) < 2.0 && abs(height - 842.0) < 2.0 {
                pageSize = "A4 (210mm × 297mm)"
            } else if abs(width - 420.0) < 2.0 && abs(height - 595.0) < 2.0 {
                pageSize = "A5 (148mm × 210mm)"
            } else if abs(width - 842.0) < 2.0 && abs(height - 1191.0) < 2.0 {
                pageSize = "A3 (297mm × 420mm)"
            } else {
                // Custom size - show in points and approximate inches
                pageSize = String(format: "%.0f × %.0f pt (%.1f\" × %.1f\")", 
                                width, height, widthInches, heightInches)
            }
        }

        // Get PDF version
        var version: String? = nil
        let majorVersion = pdfDocument.majorVersion
        let minorVersion = pdfDocument.minorVersion
        if majorVersion > 0 {
            version = "\(majorVersion).\(minorVersion)"
        }

        // Check if encrypted
        let isEncrypted = pdfDocument.isEncrypted

        let metadata = PDFMetadata(
            title: title,
            author: author,
            subject: subject,
            creator: creator,
            producer: producer,
            creationDate: creationDate,
            modificationDate: modificationDate,
            pageCount: pageCount > 0 ? pageCount : nil,
            pageSize: pageSize,
            version: version,
            isEncrypted: isEncrypted ? true : nil,
            keywords: keywords
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Office Document Metadata Extraction
    private static func extractOfficeMetadata(from url: URL) -> OfficeMetadata? {
        // Check if file is an Office document by extension
        let officeExtensions = ["docx", "doc", "xlsx", "xls", "pptx", "ppt"]
        guard let ext = url.pathExtension.lowercased() as String?,
              officeExtensions.contains(ext) else {
            return nil
        }

        // Use MDItem to get Spotlight metadata
        guard let mdItem = MDItemCreate(kCFAllocatorDefault, url.path as CFString) else {
            return nil
        }

        // Extract title
        let title = MDItemCopyAttribute(mdItem, kMDItemTitle) as? String

        // Extract author(s)
        var author: String? = nil
        if let authors = MDItemCopyAttribute(mdItem, kMDItemAuthors) as? [String], !authors.isEmpty {
            author = authors.joined(separator: ", ")
        }

        // Extract subject
        let subject = MDItemCopyAttribute(mdItem, kMDItemSubject) as? String

        // Extract keywords
        var keywords: String? = nil
        if let keywordArray = MDItemCopyAttribute(mdItem, kMDItemKeywords) as? [String], !keywordArray.isEmpty {
            keywords = keywordArray.joined(separator: ", ")
        }

        // Extract comment/description
        let comment = MDItemCopyAttribute(mdItem, kMDItemComment) as? String

        // Extract last modified by
        let lastModifiedBy = MDItemCopyAttribute(mdItem, kMDItemLastUsedDate) as? String

        // Extract dates
        var creationDate: String? = nil
        if let date = MDItemCopyAttribute(mdItem, kMDItemContentCreationDate) as? Date {
            creationDate = DateFormatters.formatMediumDateTime(date)
        }

        var modificationDate: String? = nil
        if let date = MDItemCopyAttribute(mdItem, kMDItemContentModificationDate) as? Date {
            modificationDate = DateFormatters.formatMediumDateTime(date)
        }

        // Extract page count (for Word documents)
        let pageCount = MDItemCopyAttribute(mdItem, kMDItemNumberOfPages) as? Int

        // Extract word count (for Word documents)
        let wordCount = MDItemCopyAttribute(mdItem, kMDItemTextContent) as? String
        let actualWordCount: Int? = wordCount != nil ? wordCount!.split(separator: " ").count : nil

        // Extract sheet count (for Excel - approximate via page count)
        var sheetCount: Int? = nil
        if ext == "xlsx" || ext == "xls" {
            sheetCount = pageCount // Excel reports sheets as pages
        }

        // Extract slide count (for PowerPoint)
        var slideCount: Int? = nil
        if ext == "pptx" || ext == "ppt" {
            slideCount = pageCount // PowerPoint reports slides as pages
        }

        // Extract company
        let company = MDItemCopyAttribute(mdItem, kMDItemOrganizations) as? String

        // Extract category
        let category = MDItemCopyAttribute(mdItem, kMDItemHeadline) as? String

        let metadata = OfficeMetadata(
            title: title,
            author: author,
            subject: subject,
            keywords: keywords,
            comment: comment,
            lastModifiedBy: lastModifiedBy,
            creationDate: creationDate,
            modificationDate: modificationDate,
            pageCount: (ext == "docx" || ext == "doc") ? pageCount : nil,
            wordCount: (ext == "docx" || ext == "doc") ? actualWordCount : nil,
            sheetCount: sheetCount,
            slideCount: slideCount,
            company: company,
            category: category
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Archive Metadata Extraction
    private static func extractArchiveMetadata(from url: URL) -> ArchiveMetadata? {
        // Check if file is an archive by extension
        let archiveExtensions = ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "tgz", "tbz2", "txz", "tar.gz", "tar.bz2", "tar.xz"]
        let ext = url.pathExtension.lowercased()
        
        // Check for double extensions like .tar.gz
        let fileName = url.deletingPathExtension().lastPathComponent
        let doubleExt = fileName.contains(".") ? "\(fileName.split(separator: ".").last!).\(ext)" : ext
        
        guard archiveExtensions.contains(ext) || archiveExtensions.contains(doubleExt) else {
            return nil
        }

        // Determine format
        var format: String? = nil
        if ext == "zip" {
            format = "ZIP"
        } else if ext == "rar" {
            format = "RAR"
        } else if ext == "7z" {
            format = "7-Zip"
        } else if ext == "tar" || doubleExt.hasPrefix("tar.") {
            if doubleExt.hasSuffix(".gz") || ext == "tgz" {
                format = "TAR.GZ"
            } else if doubleExt.hasSuffix(".bz2") || ext == "tbz2" {
                format = "TAR.BZ2"
            } else if doubleExt.hasSuffix(".xz") || ext == "txz" {
                format = "TAR.XZ"
            } else {
                format = "TAR"
            }
        } else if ext == "gz" {
            format = "GZIP"
        } else if ext == "bz2" {
            format = "BZIP2"
        } else if ext == "xz" {
            format = "XZ"
        }

        var fileCount: Int? = nil
        var uncompressedSize: UInt64? = nil
        var isEncrypted: Bool? = nil
        var comment: String? = nil

        // Try to extract metadata based on archive type
        if ext == "zip" || ext == "jar" {
            // Use zipinfo command for ZIP files
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/zipinfo")
            process.arguments = ["-t", url.path]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    // Parse zipinfo output
                    // Format: "123 files, 456789 bytes uncompressed, 123456 bytes compressed"
                    let lines = output.components(separatedBy: .newlines)
                    for line in lines {
                        if line.contains("files,") {
                            // Extract file count
                            if let countMatch = line.split(separator: " ").first,
                               let count = Int(countMatch) {
                                fileCount = count
                            }
                            
                            // Extract uncompressed size
                            let components = line.components(separatedBy: " ")
                            if let uncompIndex = components.firstIndex(of: "bytes"), uncompIndex > 0,
                               let size = UInt64(components[uncompIndex - 1].replacingOccurrences(of: ",", with: "")) {
                                uncompressedSize = size
                            }
                        }
                    }
                }
            } catch {
                // Silently fail
            }
            
            // Check for encryption
            let listProcess = Process()
            listProcess.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            listProcess.arguments = ["-Z", "-1", url.path]
            
            let listPipe = Pipe()
            let errorPipe = Pipe()
            listProcess.standardOutput = listPipe
            listProcess.standardError = errorPipe
            
            do {
                try listProcess.run()
                listProcess.waitUntilExit()
                
                if listProcess.terminationStatus != 0 {
                    // If unzip fails, might be encrypted
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    if let errorOutput = String(data: errorData, encoding: .utf8),
                       errorOutput.contains("password") || errorOutput.contains("encrypted") {
                        isEncrypted = true
                    }
                }
            } catch {
                // Silently fail
            }
            
        } else if doubleExt.hasPrefix("tar") || ext == "tar" || ext == "tgz" || ext == "tbz2" || ext == "txz" {
            // Use tar command for TAR files
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            
            var tarArgs = ["-t"]
            if ext == "gz" || ext == "tgz" || doubleExt.hasSuffix(".gz") {
                tarArgs.append("-z")
            } else if ext == "bz2" || ext == "tbz2" || doubleExt.hasSuffix(".bz2") {
                tarArgs.append("-j")
            } else if ext == "xz" || ext == "txz" || doubleExt.hasSuffix(".xz") {
                tarArgs.append("-J")
            }
            tarArgs.append(contentsOf: ["-f", url.path])
            
            process.arguments = tarArgs
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let files = output.components(separatedBy: .newlines).filter { !$0.isEmpty && !$0.hasSuffix("/") }
                    fileCount = files.count
                }
            } catch {
                // Silently fail
            }
        }

        // Calculate compression ratio if we have both sizes
        var compressionRatio: Double? = nil
        if let uncompSize = uncompressedSize, uncompSize > 0 {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let compressedSize = attributes[.size] as? UInt64, compressedSize > 0 {
                    compressionRatio = (1.0 - Double(compressedSize) / Double(uncompSize)) * 100.0
                }
            } catch {
                // Silently fail
            }
        }

        let metadata = ArchiveMetadata(
            format: format,
            fileCount: fileCount,
            uncompressedSize: uncompressedSize,
            compressionRatio: compressionRatio,
            isEncrypted: isEncrypted,
            comment: comment
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - E-book Metadata Extraction
    private static func extractEbookMetadata(from url: URL) -> EbookMetadata? {
        let ext = url.pathExtension.lowercased()
        let ebookExtensions = ["epub", "mobi", "azw", "azw3", "fb2", "lit", "prc"]
        
        guard ebookExtensions.contains(ext) else {
            return nil
        }
        
        // Try EPUB parsing first (most common format)
        if ext == "epub" {
            return extractEPUBMetadata(from: url)
        }
        
        // Fallback to MDItem API for other formats
        return extractEbookMetadataViaMDItem(from: url)
    }
    
    private static func extractEPUBMetadata(from url: URL) -> EbookMetadata? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        // EPUB is a ZIP file, extract to temp directory
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", url.path, "-d", tempDir.path]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            guard process.terminationStatus == 0 else {
                return nil
            }
            
            // Find container.xml to get OPF file path
            let containerPath = tempDir.appendingPathComponent("META-INF/container.xml")
            guard fileManager.fileExists(atPath: containerPath.path) else {
                return nil
            }
            
            let containerData = try Data(contentsOf: containerPath)
            let containerXML = try XMLDocument(data: containerData, options: [])
            
            // Get OPF file path from container.xml
            guard let rootfile = try containerXML.nodes(forXPath: "//rootfile[@media-type='application/oebps-package+xml']").first as? XMLElement,
                  let opfRelativePath = rootfile.attribute(forName: "full-path")?.stringValue else {
                return nil
            }
            
            // Parse OPF file for metadata
            let opfPath = tempDir.appendingPathComponent(opfRelativePath)
            let opfData = try Data(contentsOf: opfPath)
            let opfXML = try XMLDocument(data: opfData, options: [])
            
            // Extract metadata using XPath (without namespace prefix for simplicity)
            // EPUB uses Dublin Core, but we'll search without namespace
            let title = try? opfXML.nodes(forXPath: "//*[local-name()='title']").first?.stringValue
            let author = try? opfXML.nodes(forXPath: "//*[local-name()='creator']").first?.stringValue
            let publisher = try? opfXML.nodes(forXPath: "//*[local-name()='publisher']").first?.stringValue
            let publicationDate = try? opfXML.nodes(forXPath: "//*[local-name()='date']").first?.stringValue
            let language = try? opfXML.nodes(forXPath: "//*[local-name()='language']").first?.stringValue
            let description = try? opfXML.nodes(forXPath: "//*[local-name()='description']").first?.stringValue
            
            // Try to find ISBN in identifier elements
            var isbn: String? = nil
            if let identifiers = try? opfXML.nodes(forXPath: "//*[local-name()='identifier']") {
                for identifier in identifiers {
                    if let element = identifier as? XMLElement,
                       let scheme = element.attribute(forName: "scheme")?.stringValue?.lowercased(),
                       scheme.contains("isbn") {
                        isbn = element.stringValue
                        break
                    }
                    // Also check opf:scheme attribute
                    if let element = identifier as? XMLElement,
                       let value = element.stringValue,
                       value.uppercased().contains("ISBN") {
                        isbn = value
                        break
                    }
                }
            }
            
            return EbookMetadata(
                title: title,
                author: author,
                publisher: publisher,
                publicationDate: publicationDate,
                isbn: isbn,
                language: language,
                description: description,
                pageCount: nil  // EPUB doesn't have fixed page count
            )
            
        } catch {
            print("Error extracting EPUB metadata: \(error)")
            return nil
        }
    }
    
    private static func extractEbookMetadataViaMDItem(from url: URL) -> EbookMetadata? {
        guard let mdItem = MDItemCreateWithURL(kCFAllocatorDefault, url as CFURL) else {
            return nil
        }
        
        let title = MDItemCopyAttribute(mdItem, kMDItemTitle) as? String
        let authors = MDItemCopyAttribute(mdItem, kMDItemAuthors) as? [String]
        let author = authors?.joined(separator: ", ")
        let publisher = MDItemCopyAttribute(mdItem, kMDItemPublishers) as? [String]
        let language = MDItemCopyAttribute(mdItem, kMDItemLanguages) as? [String]
        let description = MDItemCopyAttribute(mdItem, kMDItemDescription) as? String
        let pageCount = MDItemCopyAttribute(mdItem, kMDItemNumberOfPages) as? Int
        
        return EbookMetadata(
            title: title,
            author: author,
            publisher: publisher?.first,
            publicationDate: nil,
            isbn: nil,
            language: language?.first,
            description: description,
            pageCount: pageCount
        )
    }

    // MARK: - Code File Metadata Extraction
    private static func extractCodeMetadata(from url: URL) -> CodeMetadata? {
        let ext = url.pathExtension.lowercased()
        
        // Check if it's a code file
        guard let language = languageFromExtension(ext) else {
            return nil
        }
        
        // Limit file size to avoid reading huge files (5MB limit)
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int64,
              fileSize < 5 * 1024 * 1024 else {
            return nil
        }
        
        // Try to read the file
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            return nil
        }
        
        // Detect encoding
        let encoding = detectEncoding(data: data)
        
        // Count lines
        let lines = content.components(separatedBy: .newlines)
        let lineCount = lines.count
        
        // Analyze lines
        var codeLines = 0
        var commentLines = 0
        var blankLines = 0
        var inMultiLineComment = false
        
        let commentSyntax = getCommentSyntax(for: language)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Check for blank lines
            if trimmed.isEmpty {
                blankLines += 1
                continue
            }
            
            // Check for multi-line comments
            if let multiStart = commentSyntax.multiLineStart, let multiEnd = commentSyntax.multiLineEnd {
                if trimmed.contains(multiStart) {
                    inMultiLineComment = true
                }
                if inMultiLineComment {
                    commentLines += 1
                    if trimmed.contains(multiEnd) {
                        inMultiLineComment = false
                    }
                    continue
                }
            }
            
            // Check for single-line comments
            var isComment = false
            for prefix in commentSyntax.singleLine {
                if trimmed.hasPrefix(prefix) {
                    commentLines += 1
                    isComment = true
                    break
                }
            }
            
            if !isComment {
                codeLines += 1
            }
        }
        
        return CodeMetadata(
            language: language,
            lineCount: lineCount,
            codeLines: codeLines,
            commentLines: commentLines,
            blankLines: blankLines,
            encoding: encoding
        )
    }
    
    private static func languageFromExtension(_ ext: String) -> String? {
        let languageMap: [String: String] = [
            // C-family
            "c": "C", "h": "C",
            "cpp": "C++", "cc": "C++", "cxx": "C++", "hpp": "C++", "hxx": "C++",
            "m": "Objective-C", "mm": "Objective-C++",
            "cs": "C#",
            // Modern languages
            "swift": "Swift",
            "rs": "Rust",
            "go": "Go",
            "kt": "Kotlin", "kts": "Kotlin",
            "dart": "Dart",
            // Scripting
            "py": "Python", "pyw": "Python",
            "rb": "Ruby",
            "php": "PHP",
            "pl": "Perl", "pm": "Perl",
            "sh": "Shell", "bash": "Bash", "zsh": "Zsh",
            // JVM
            "java": "Java",
            "scala": "Scala",
            "groovy": "Groovy",
            // Web
            "js": "JavaScript", "mjs": "JavaScript",
            "ts": "TypeScript", "tsx": "TypeScript",
            "jsx": "JSX",
            "html": "HTML", "htm": "HTML",
            "css": "CSS",
            "scss": "SCSS", "sass": "Sass",
            "less": "Less",
            "vue": "Vue",
            // Data/Config
            "json": "JSON",
            "yaml": "YAML", "yml": "YAML",
            "xml": "XML",
            "toml": "TOML",
            "ini": "INI",
            // Other
            "md": "Markdown", "markdown": "Markdown",
            "sql": "SQL",
            "r": "R",
            "lua": "Lua",
            "vim": "Vim Script",
            "el": "Emacs Lisp", "elisp": "Emacs Lisp"
        ]
        
        return languageMap[ext]
    }
    
    private struct CommentSyntax {
        let singleLine: [String]
        let multiLineStart: String?
        let multiLineEnd: String?
    }
    
    private static func getCommentSyntax(for language: String) -> CommentSyntax {
        switch language {
        case "C", "C++", "Objective-C", "Objective-C++", "C#", "Swift", "JavaScript", "TypeScript", "JSX", "Java", "Kotlin", "Scala", "Groovy", "Rust", "Go", "Dart", "PHP":
            return CommentSyntax(singleLine: ["//"], multiLineStart: "/*", multiLineEnd: "*/")
        case "Python", "Ruby", "Shell", "Bash", "Zsh", "Perl", "YAML", "TOML", "INI", "R":
            return CommentSyntax(singleLine: ["#"], multiLineStart: nil, multiLineEnd: nil)
        case "HTML", "XML":
            return CommentSyntax(singleLine: [], multiLineStart: "<!--", multiLineEnd: "-->")
        case "CSS", "SCSS", "Sass", "Less":
            return CommentSyntax(singleLine: ["//"], multiLineStart: "/*", multiLineEnd: "*/")
        case "Lua":
            return CommentSyntax(singleLine: ["--"], multiLineStart: "--[[", multiLineEnd: "]]")
        case "SQL":
            return CommentSyntax(singleLine: ["--"], multiLineStart: "/*", multiLineEnd: "*/")
        case "Vim Script":
            return CommentSyntax(singleLine: ["\""], multiLineStart: nil, multiLineEnd: nil)
        case "Emacs Lisp":
            return CommentSyntax(singleLine: [";"], multiLineStart: nil, multiLineEnd: nil)
        default:
            return CommentSyntax(singleLine: ["//", "#"], multiLineStart: "/*", multiLineEnd: "*/")
        }
    }
    
    private static func detectEncoding(data: Data) -> String {
        // Try UTF-8
        if String(data: data, encoding: .utf8) != nil {
            return "UTF-8"
        }
        // Try ASCII
        if String(data: data, encoding: .ascii) != nil {
            return "ASCII"
        }
        // Try other encodings
        if String(data: data, encoding: .utf16) != nil {
            return "UTF-16"
        }
        if String(data: data, encoding: .isoLatin1) != nil {
            return "ISO-8859-1"
        }
        return "Unknown"
    }
    
    private static func extractFontMetadata(from url: URL) -> FontMetadata? {
        let fontExtensions = ["ttf", "otf", "ttc", "otc", "woff", "woff2", "pfb", "pfm", "fon"]
        let ext = url.pathExtension.lowercased()
        guard fontExtensions.contains(ext) else { return nil }
        
        // Create CGDataProvider from URL
        guard let dataProvider = CGDataProvider(url: url as CFURL) else { return nil }
        
        // Create CGFont from data provider
        guard let cgFont = CGFont(dataProvider) else { return nil }
        
        // Create CTFont for easier metadata access
        let ctFont = CTFontCreateWithGraphicsFont(cgFont, 12.0, nil, nil)
        
        // Extract font name (full name)
        let fontName = CTFontCopyFullName(ctFont) as String?
        
        // Extract font family
        let fontFamily = CTFontCopyFamilyName(ctFont) as String?
        
        // Extract font style
        let fontStyle = CTFontCopyName(ctFont, kCTFontStyleNameKey) as String?
        
        // Extract version
        let version = CTFontCopyName(ctFont, kCTFontVersionNameKey) as String?
        
        // Extract designer
        let designer = CTFontCopyName(ctFont, kCTFontDesignerNameKey) as String?
        
        // Extract copyright
        let copyright = CTFontCopyName(ctFont, kCTFontCopyrightNameKey) as String?
        
        // Get glyph count
        let glyphCount = CTFontGetGlyphCount(ctFont)
        
        return FontMetadata(
            fontName: fontName,
            fontFamily: fontFamily,
            fontStyle: fontStyle,
            version: version,
            designer: designer,
            copyright: copyright,
            glyphCount: glyphCount > 0 ? Int(glyphCount) : nil
        )
    }
    
    private static func extractDiskImageMetadata(from url: URL) -> DiskImageMetadata? {
        let diskImageExtensions = ["dmg", "iso", "img", "cdr", "toast", "sparseimage", "sparsebundle"]
        let ext = url.pathExtension.lowercased()
        guard diskImageExtensions.contains(ext) else { return nil }
        
        // Use hdiutil to get disk image information
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["imageinfo", url.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            guard process.terminationStatus == 0 else { return nil }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return nil }
            
            var format: String?
            var totalSize: Int64?
            var compressedSize: Int64?
            var compressionRatio: String?
            var isEncrypted: Bool?
            var partitionScheme: String?
            var fileSystem: String?
            
            // Parse hdiutil output
            let lines = output.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                
                // Format
                if trimmed.hasPrefix("Format:") {
                    format = trimmed.replacingOccurrences(of: "Format:", with: "").trimmingCharacters(in: .whitespaces)
                }
                
                // Total size
                if trimmed.hasPrefix("Total Bytes:") || trimmed.hasPrefix("Size Information:") {
                    if let sizeStr = trimmed.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces),
                       let size = Int64(sizeStr.components(separatedBy: .whitespaces).first ?? "") {
                        totalSize = size
                    }
                }
                
                // Compressed size
                if trimmed.hasPrefix("Compressed Bytes:") || trimmed.hasPrefix("Compressed:") {
                    if let sizeStr = trimmed.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces),
                       let size = Int64(sizeStr.components(separatedBy: .whitespaces).first ?? "") {
                        compressedSize = size
                    }
                }
                
                // Encryption
                if trimmed.contains("Encrypted:") || trimmed.contains("encrypted") {
                    isEncrypted = trimmed.contains("yes") || trimmed.contains("true")
                }
                
                // Partition scheme
                if trimmed.hasPrefix("Partition Scheme:") || trimmed.contains("partition-scheme") {
                    partitionScheme = trimmed.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
                }
                
                // File system
                if trimmed.hasPrefix("Format Description:") {
                    let description = trimmed.replacingOccurrences(of: "Format Description:", with: "").trimmingCharacters(in: .whitespaces)
                    if description.contains("HFS+") {
                        fileSystem = "HFS+"
                    } else if description.contains("APFS") {
                        fileSystem = "APFS"
                    } else if description.contains("ISO") {
                        fileSystem = "ISO 9660"
                    } else if description.contains("FAT") {
                        fileSystem = "FAT32"
                    }
                }
            }
            
            // Calculate compression ratio if both sizes are available
            if let total = totalSize, let compressed = compressedSize, compressed > 0 {
                let ratio = Double(total) / Double(compressed)
                compressionRatio = String(format: "%.1f:1", ratio)
            }
            
            // If encryption info not found, assume not encrypted
            if isEncrypted == nil {
                isEncrypted = false
            }
            
            return DiskImageMetadata(
                format: format,
                totalSize: totalSize,
                compressedSize: compressedSize,
                compressionRatio: compressionRatio,
                isEncrypted: isEncrypted,
                partitionScheme: partitionScheme,
                fileSystem: fileSystem
            )
        } catch {
            return nil
        }
    }
    
    private static func extractVectorGraphicsMetadata(from url: URL) -> VectorGraphicsMetadata? {
        let vectorExtensions = ["svg", "svgz", "eps", "ai", "pdf"]
        let ext = url.pathExtension.lowercased()
        guard vectorExtensions.contains(ext) else { return nil }
        
        var format: String?
        var dimensions: String?
        var viewBox: String?
        var elementCount: Int?
        var colorMode: String?
        var creator: String?
        var version: String?
        
        if ext == "svg" || ext == "svgz" {
            // Parse SVG file
            do {
                let data: Data
                if ext == "svgz" {
                    // Decompress gzipped SVG
                    guard let compressedData = try? Data(contentsOf: url),
                          let decompressedData = try? (compressedData as NSData).decompressed(using: .zlib) as Data else {
                        return nil
                    }
                    data = decompressedData
                } else {
                    data = try Data(contentsOf: url)
                }
                
                guard let xmlString = String(data: data, encoding: .utf8) else { return nil }
                
                format = "SVG"
                
                // Extract SVG version
                if let versionRange = xmlString.range(of: #"version="([^"]+)""#, options: .regularExpression) {
                    let versionString = String(xmlString[versionRange])
                    if let match = versionString.range(of: #""([^"]+)""#, options: .regularExpression) {
                        version = String(versionString[match]).replacingOccurrences(of: "\"", with: "")
                    }
                }
                
                // Extract viewBox
                if let viewBoxRange = xmlString.range(of: #"viewBox="([^"]+)""#, options: .regularExpression) {
                    let viewBoxString = String(xmlString[viewBoxRange])
                    if let match = viewBoxString.range(of: #""([^"]+)""#, options: .regularExpression) {
                        viewBox = String(viewBoxString[match]).replacingOccurrences(of: "\"", with: "")
                    }
                }
                
                // Extract width and height
                var width: String?
                var height: String?
                if let widthRange = xmlString.range(of: #"width="([^"]+)""#, options: .regularExpression) {
                    let widthString = String(xmlString[widthRange])
                    if let match = widthString.range(of: #""([^"]+)""#, options: .regularExpression) {
                        width = String(widthString[match]).replacingOccurrences(of: "\"", with: "")
                    }
                }
                if let heightRange = xmlString.range(of: #"height="([^"]+)""#, options: .regularExpression) {
                    let heightString = String(xmlString[heightRange])
                    if let match = heightString.range(of: #""([^"]+)""#, options: .regularExpression) {
                        height = String(heightString[match]).replacingOccurrences(of: "\"", with: "")
                    }
                }
                if let w = width, let h = height {
                    dimensions = "\(w) × \(h)"
                }
                
                // Count elements (paths, circles, rects, etc.)
                let pathCount = xmlString.components(separatedBy: "<path").count - 1
                let circleCount = xmlString.components(separatedBy: "<circle").count - 1
                let rectCount = xmlString.components(separatedBy: "<rect").count - 1
                let ellipseCount = xmlString.components(separatedBy: "<ellipse").count - 1
                let polygonCount = xmlString.components(separatedBy: "<polygon").count - 1
                let polylineCount = xmlString.components(separatedBy: "<polyline").count - 1
                elementCount = pathCount + circleCount + rectCount + ellipseCount + polygonCount + polylineCount
                
                // Extract creator/generator
                if let creatorRange = xmlString.range(of: #"<dc:creator>([^<]+)</dc:creator>"#, options: .regularExpression) {
                    let creatorString = String(xmlString[creatorRange])
                    creator = creatorString.replacingOccurrences(of: "<dc:creator>", with: "").replacingOccurrences(of: "</dc:creator>", with: "")
                } else if let generatorRange = xmlString.range(of: #"generator="([^"]+)""#, options: .regularExpression) {
                    let generatorString = String(xmlString[generatorRange])
                    if let match = generatorString.range(of: #""([^"]+)""#, options: .regularExpression) {
                        creator = String(generatorString[match]).replacingOccurrences(of: "\"", with: "")
                    }
                }
                
            } catch {
                return nil
            }
        } else if ext == "eps" || ext == "ai" {
            // Parse EPS/AI file
            guard let data = try? Data(contentsOf: url),
                  let content = String(data: data.prefix(4096), encoding: .utf8) else {
                return nil
            }
            
            format = ext == "ai" ? "Adobe Illustrator" : "EPS"
            
            // Extract BoundingBox
            if let bboxRange = content.range(of: #"%%BoundingBox:\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)"#, options: .regularExpression) {
                let bboxString = String(content[bboxRange])
                let components = bboxString.components(separatedBy: .whitespaces).compactMap { Int($0) }
                if components.count >= 4 {
                    let width = components[2] - components[0]
                    let height = components[3] - components[1]
                    dimensions = "\(width) × \(height) pt"
                }
            }
            
            // Extract Creator
            if let creatorRange = content.range(of: #"%%Creator:\s*(.+)"#, options: .regularExpression) {
                let creatorLine = String(content[creatorRange])
                creator = creatorLine.replacingOccurrences(of: "%%Creator:", with: "").trimmingCharacters(in: .whitespaces)
            }
            
            // Detect color mode
            if content.contains("CMYK") || content.contains("setcmykcolor") {
                colorMode = "CMYK"
            } else if content.contains("RGB") || content.contains("setrgbcolor") {
                colorMode = "RGB"
            }
        }
        
        return VectorGraphicsMetadata(
            format: format,
            dimensions: dimensions,
            viewBox: viewBox,
            elementCount: elementCount,
            colorMode: colorMode,
            creator: creator,
            version: version
        )
    }

    // MARK: - Helper Functions
    private static func fourCCToString(_ value: FourCharCode) -> String {
        let bytes: [CChar] = [
            CChar((value >> 24) & 0xFF),
            CChar((value >> 16) & 0xFF),
            CChar((value >> 8) & 0xFF),
            CChar(value & 0xFF),
            0
        ]
        return String(cString: bytes)
    }
}
