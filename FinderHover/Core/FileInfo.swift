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
import SQLite3

// MARK: - Process Timeout Helper

/// Runs a Process with a timeout to prevent indefinite blocking
/// - Parameters:
///   - process: The Process to run
///   - timeout: Maximum time in seconds to wait for completion
/// - Returns: true if process completed within timeout, false if timed out or failed
private func runProcessWithTimeout(_ process: Process, timeout: TimeInterval = 5.0) -> Bool {
    do {
        try process.run()
    } catch {
        return false
    }

    let deadline = Date().addingTimeInterval(timeout)

    while process.isRunning {
        if Date() > deadline {
            process.terminate()
            Logger.warning("Process timed out after \(timeout)s: \(process.executableURL?.path ?? "unknown")", subsystem: .fileSystem)
            return false
        }
        Thread.sleep(forTimeInterval: 0.05)
    }

    return process.terminationStatus == 0
}

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

// MARK: - HTML Metadata Structure
struct HTMLMetadata {
    let title: String?
    let description: String?
    let charset: String?
    let ogTitle: String?           // Open Graph title
    let ogDescription: String?     // Open Graph description
    let ogImage: String?           // Open Graph image URL
    let twitterCard: String?       // Twitter card type
    let keywords: String?
    let author: String?
    let language: String?

    var hasData: Bool {
        return title != nil || description != nil || charset != nil ||
               ogTitle != nil || ogDescription != nil || ogImage != nil ||
               twitterCard != nil || keywords != nil || author != nil || language != nil
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

// MARK: - Markdown Metadata Structure
struct MarkdownMetadata {
    let hasFrontmatter: Bool?
    let frontmatterFormat: String? // YAML, TOML, JSON
    let title: String?             // From frontmatter or first H1
    let wordCount: Int?
    let headingCount: Int?
    let linkCount: Int?
    let imageCount: Int?
    let codeBlockCount: Int?

    var hasData: Bool {
        return hasFrontmatter != nil || frontmatterFormat != nil || title != nil ||
               wordCount != nil || headingCount != nil || linkCount != nil ||
               imageCount != nil || codeBlockCount != nil
    }
}

// MARK: - Config File Metadata Structure (JSON/YAML/TOML)
struct ConfigMetadata {
    let format: String?            // JSON, YAML, TOML
    let isValid: Bool?
    let keyCount: Int?
    let maxDepth: Int?
    let hasComments: Bool?         // YAML/TOML only
    let encoding: String?

    var hasData: Bool {
        return format != nil || isValid != nil || keyCount != nil ||
               maxDepth != nil || hasComments != nil || encoding != nil
    }
}

// MARK: - PSD Metadata Structure
struct PSDMetadata {
    let layerCount: Int?
    let colorMode: String?         // RGB, CMYK, Grayscale, etc.
    let bitDepth: Int?
    let resolution: String?        // e.g., "300 DPI"
    let hasTransparency: Bool?
    let dimensions: String?

    var hasData: Bool {
        return layerCount != nil || colorMode != nil || bitDepth != nil ||
               resolution != nil || hasTransparency != nil || dimensions != nil
    }
}

// MARK: - Executable Metadata Structure
struct ExecutableMetadata {
    let architecture: String?      // arm64, x86_64, Universal
    let isCodeSigned: Bool?
    let signingAuthority: String?
    let minimumOS: String?
    let sdkVersion: String?
    let fileType: String?          // Mach-O, dylib, etc.

    var hasData: Bool {
        return architecture != nil || isCodeSigned != nil || signingAuthority != nil ||
               minimumOS != nil || sdkVersion != nil || fileType != nil
    }
}

// MARK: - App Bundle Metadata Structure
struct AppBundleMetadata {
    let bundleID: String?
    let version: String?
    let buildNumber: String?
    let minimumOS: String?
    let category: String?
    let copyright: String?
    let isCodeSigned: Bool?
    let hasEntitlements: Bool?

    var hasData: Bool {
        return bundleID != nil || version != nil || buildNumber != nil ||
               minimumOS != nil || category != nil || copyright != nil ||
               isCodeSigned != nil || hasEntitlements != nil
    }
}

// MARK: - SQLite Metadata Structure
struct SQLiteMetadata {
    let tableCount: Int?
    let indexCount: Int?
    let triggerCount: Int?
    let viewCount: Int?
    let totalRows: Int?
    let schemaVersion: Int?
    let pageSize: Int?
    let encoding: String?

    var hasData: Bool {
        return tableCount != nil || indexCount != nil || triggerCount != nil ||
               viewCount != nil || totalRows != nil || schemaVersion != nil ||
               pageSize != nil || encoding != nil
    }
}

// MARK: - Git Repository Metadata Structure
struct GitMetadata {
    let branchCount: Int?
    let currentBranch: String?
    let commitCount: Int?
    let lastCommitDate: String?
    let lastCommitMessage: String?
    let remoteURL: String?
    let hasUncommittedChanges: Bool?
    let tagCount: Int?

    var hasData: Bool {
        return branchCount != nil || currentBranch != nil || commitCount != nil ||
               lastCommitDate != nil || lastCommitMessage != nil || remoteURL != nil ||
               hasUncommittedChanges != nil || tagCount != nil
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

    // Subtitle metadata
    let subtitleMetadata: SubtitleMetadata?

    // HTML metadata
    let htmlMetadata: HTMLMetadata?

    // Extended image metadata (IPTC/XMP)
    let imageExtendedMetadata: ImageExtendedMetadata?

    // Markdown metadata
    let markdownMetadata: MarkdownMetadata?

    // Config file metadata (JSON/YAML/TOML)
    let configMetadata: ConfigMetadata?

    // PSD metadata
    let psdMetadata: PSDMetadata?

    // Executable metadata
    let executableMetadata: ExecutableMetadata?

    // App bundle metadata
    let appBundleMetadata: AppBundleMetadata?

    // SQLite metadata
    let sqliteMetadata: SQLiteMetadata?

    // Git repository metadata
    let gitMetadata: GitMetadata?

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

    /// Generates a thumbnail asynchronously with cancellation support
    /// - Parameters:
    ///   - completion: Called with the generated thumbnail image, or nil if failed/cancelled
    /// - Returns: The QLThumbnailGenerator.Request that can be used to cancel the generation
    @discardableResult
    func generateThumbnailAsync(completion: @escaping (NSImage?) -> Void) -> QLThumbnailGenerator.Request {
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

        return request
    }

    /// Cancels a pending thumbnail generation request
    static func cancelThumbnailGeneration(_ request: QLThumbnailGenerator.Request) {
        QLThumbnailGenerator.shared.cancel(request)
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

            // Extract metadata based on file type
            // Note: PDF can be either a document or vector graphics, check page count to determine
            var pdfMetadata: PDFMetadata? = nil
            var vectorGraphicsMetadata: VectorGraphicsMetadata? = nil

            if url.pathExtension.lowercased() == "pdf" {
                // Extract PDF metadata first
                let metadata = extractPDFMetadata(from: url)

                // If PDF has multiple pages or has text content, treat as document
                // Otherwise, treat as vector graphics
                if let pageCount = metadata?.pageCount, pageCount > 1 {
                    pdfMetadata = metadata
                } else if metadata?.title != nil || metadata?.author != nil {
                    // Has document metadata, treat as document
                    pdfMetadata = metadata
                } else {
                    // Single page PDF with no document metadata, could be vector graphics
                    // Try to extract as vector graphics
                    vectorGraphicsMetadata = extractVectorGraphicsMetadata(from: url)
                    // If no vector graphics metadata found, fall back to PDF metadata
                    if vectorGraphicsMetadata == nil {
                        pdfMetadata = metadata
                    }
                }
            } else {
                // Not a PDF, extract normally
                pdfMetadata = extractPDFMetadata(from: url)
                vectorGraphicsMetadata = extractVectorGraphicsMetadata(from: url)
            }

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

            // Extract Subtitle metadata
            let subtitleMetadata = extractSubtitleMetadata(from: url)

            // Extract HTML metadata
            let htmlMetadata = extractHTMLMetadata(from: url)

            // Extract extended image metadata (IPTC/XMP)
            let imageExtendedMetadata = extractImageExtendedMetadata(from: url)

            // Extract Markdown metadata
            let markdownMetadata = extractMarkdownMetadata(from: url)

            // Extract Config file metadata (JSON/YAML/TOML)
            let configMetadata = extractConfigMetadata(from: url)

            // Extract PSD metadata
            let psdMetadata2 = extractPSDMetadata(from: url)

            // Extract Executable metadata
            let executableMetadata = extractExecutableMetadata(from: url)

            // Extract App Bundle metadata
            let appBundleMetadata = extractAppBundleMetadata(from: url)

            // Extract SQLite metadata
            let sqliteMetadata = extractSQLiteMetadata(from: url)

            // Extract Git repository metadata
            let gitMetadata = extractGitMetadata(from: url)

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
                vectorGraphicsMetadata: vectorGraphicsMetadata,
                subtitleMetadata: subtitleMetadata,
                htmlMetadata: htmlMetadata,
                imageExtendedMetadata: imageExtendedMetadata,
                markdownMetadata: markdownMetadata,
                configMetadata: configMetadata,
                psdMetadata: psdMetadata2,
                executableMetadata: executableMetadata,
                appBundleMetadata: appBundleMetadata,
                sqliteMetadata: sqliteMetadata,
                gitMetadata: gitMetadata
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

            if runProcessWithTimeout(process, timeout: 3.0) {
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
            }

            // Check for encryption
            let listProcess = Process()
            listProcess.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            listProcess.arguments = ["-Z", "-1", url.path]

            let listPipe = Pipe()
            let errorPipe = Pipe()
            listProcess.standardOutput = listPipe
            listProcess.standardError = errorPipe

            // Run and check - if it fails, might be encrypted
            if !runProcessWithTimeout(listProcess, timeout: 3.0) {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                if let errorOutput = String(data: errorData, encoding: .utf8),
                   errorOutput.contains("password") || errorOutput.contains("encrypted") {
                    isEncrypted = true
                }
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

            if runProcessWithTimeout(process, timeout: 5.0) {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let files = output.components(separatedBy: .newlines).filter { !$0.isEmpty && !$0.hasSuffix("/") }
                    fileCount = files.count
                }
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

        guard runProcessWithTimeout(process, timeout: 5.0) else {
            return nil
        }

        do {
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
            // Data/Config (XML only - JSON/YAML/TOML/INI use config metadata instead)
            "xml": "XML",
            // Other (Markdown uses dedicated markdown metadata instead)
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

        guard runProcessWithTimeout(process, timeout: 5.0) else { return nil }

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
    }

    private static func extractVectorGraphicsMetadata(from url: URL) -> VectorGraphicsMetadata? {
        // Note: PDF is handled separately in FileInfo.from() to avoid overlap with PDF document metadata
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

    private static func extractSubtitleMetadata(from url: URL) -> SubtitleMetadata? {
        let subtitleExtensions = ["srt", "vtt", "ass", "ssa", "sub", "sbv", "lrc"]
        let ext = url.pathExtension.lowercased()
        guard subtitleExtensions.contains(ext) else { return nil }

        var format: String?
        var encoding: String?
        var entryCount: Int?
        var duration: String?
        var language: String?
        var frameRate: String?
        var hasFormatting: Bool?

        // Read file content
        guard let data = try? Data(contentsOf: url) else { return nil }

        // Detect encoding
        var usedEncoding: String.Encoding = .utf8
        if let detectedString = String(data: data, encoding: .utf8) {
            encoding = "UTF-8"
            usedEncoding = .utf8
        } else if let detectedString = String(data: data, encoding: .utf16) {
            encoding = "UTF-16"
            usedEncoding = .utf16
        } else if let detectedString = String(data: data, encoding: .isoLatin1) {
            encoding = "ISO-8859-1"
            usedEncoding = .isoLatin1
        } else {
            encoding = "Unknown"
        }

        guard let content = String(data: data, encoding: usedEncoding) else { return nil }

        let lines = content.components(separatedBy: .newlines)

        switch ext {
        case "srt":
            format = "SubRip (SRT)"
            // Count entries (lines that are just numbers)
            let entryLines = lines.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.isEmpty && trimmed.allSatisfy { $0.isNumber }
            }
            entryCount = entryLines.count

            // Find last timestamp to calculate duration
            if let lastTimeline = lines.last(where: { $0.contains("-->") }) {
                let components = lastTimeline.components(separatedBy: "-->")
                if components.count == 2 {
                    let endTime = components[1].trimmingCharacters(in: .whitespaces)
                    duration = endTime.components(separatedBy: ",").first
                }
            }

            // Check for formatting tags
            hasFormatting = content.contains("<b>") || content.contains("<i>") || content.contains("<u>")

        case "vtt":
            format = "WebVTT"
            // Count cues (lines with -->)
            entryCount = lines.filter { $0.contains("-->") }.count

            // Extract language from header
            if let langLine = lines.first(where: { $0.hasPrefix("Language:") }) {
                language = langLine.replacingOccurrences(of: "Language:", with: "").trimmingCharacters(in: .whitespaces)
            }

            // Find last timestamp
            if let lastTimeline = lines.last(where: { $0.contains("-->") }) {
                let components = lastTimeline.components(separatedBy: "-->")
                if components.count == 2 {
                    let endTime = components[1].trimmingCharacters(in: .whitespaces)
                    duration = endTime.components(separatedBy: ".").first
                }
            }

            hasFormatting = content.contains("<b>") || content.contains("<i>") || content.contains("<c.")

        case "ass", "ssa":
            format = ext == "ass" ? "Advanced SubStation Alpha" : "SubStation Alpha"

            // Count dialogue lines
            entryCount = lines.filter { $0.hasPrefix("Dialogue:") }.count

            // Extract PlayResX and PlayResY
            if let resXLine = lines.first(where: { $0.hasPrefix("PlayResX:") }),
               let resYLine = lines.first(where: { $0.hasPrefix("PlayResY:") }) {
                let resX = resXLine.replacingOccurrences(of: "PlayResX:", with: "").trimmingCharacters(in: .whitespaces)
                let resY = resYLine.replacingOccurrences(of: "PlayResY:", with: "").trimmingCharacters(in: .whitespaces)
            }

            // Find last dialogue timestamp
            if let lastDialogue = lines.last(where: { $0.hasPrefix("Dialogue:") }) {
                let parts = lastDialogue.components(separatedBy: ",")
                if parts.count > 2 {
                    duration = parts[2].trimmingCharacters(in: .whitespaces)
                }
            }

            hasFormatting = true // ASS/SSA always have rich formatting

        case "sub":
            format = "MicroDVD"
            // Count frame-based entries
            let frameLines = lines.filter { line in
                line.hasPrefix("{") && line.contains("}{")
            }
            entryCount = frameLines.count

            // Try to extract frame rate from first line
            if let firstLine = frameLines.first {
                let pattern = #"\{(\d+)\}\{(\d+)\}"#
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    if let match = regex.firstMatch(in: firstLine, range: NSRange(firstLine.startIndex..., in: firstLine)) {
                        if let endFrameRange = Range(match.range(at: 2), in: firstLine) {
                            let endFrame = firstLine[endFrameRange]
                            // Common assumption: 25 fps
                            frameRate = "25 fps"
                        }
                    }
                }
            }

            hasFormatting = content.contains("{Y:") || content.contains("{y:")

        case "sbv":
            format = "YouTube SBV"
            entryCount = lines.filter { $0.contains(",") && $0.contains(":") && !$0.contains(" ") }.count

            if let lastTimeline = lines.last(where: { $0.contains(",") && $0.contains(":") && !$0.contains(" ") }) {
                let components = lastTimeline.components(separatedBy: ",")
                if components.count == 2 {
                    duration = components[1].trimmingCharacters(in: .whitespaces)
                }
            }

            hasFormatting = false

        case "lrc":
            format = "LRC (Lyrics)"
            entryCount = lines.filter { $0.hasPrefix("[") && $0.contains("]") }.count

            // Extract metadata
            if let titleLine = lines.first(where: { $0.hasPrefix("[ti:") }) {
                // Title metadata available
            }
            if let langLine = lines.first(where: { $0.hasPrefix("[la:") }) {
                language = langLine.replacingOccurrences(of: "[la:", with: "").replacingOccurrences(of: "]", with: "")
            }

            hasFormatting = false

        default:
            return nil
        }

        return SubtitleMetadata(
            format: format,
            encoding: encoding,
            entryCount: entryCount,
            duration: duration,
            language: language,
            frameRate: frameRate,
            hasFormatting: hasFormatting
        )
    }

    // MARK: - HTML Metadata Extraction
    private static func extractHTMLMetadata(from url: URL) -> HTMLMetadata? {
        let htmlExtensions = ["html", "htm", "xhtml"]
        let ext = url.pathExtension.lowercased()
        guard htmlExtensions.contains(ext) else { return nil }

        // Limit file size to 64KB for performance
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int64,
              fileSize < 64 * 1024 else {
            return nil
        }

        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            return nil
        }

        var title: String?
        var description: String?
        var charset: String?
        var ogTitle: String?
        var ogDescription: String?
        var ogImage: String?
        var twitterCard: String?
        var keywords: String?
        var author: String?
        var language: String?

        // Extract <title>
        if let titleRange = content.range(of: #"<title[^>]*>([^<]+)</title>"#, options: .regularExpression) {
            let titleTag = String(content[titleRange])
            if let innerRange = titleTag.range(of: #">([^<]+)<"#, options: .regularExpression) {
                title = String(titleTag[innerRange]).trimmingCharacters(in: CharacterSet(charactersIn: "><"))
            }
        }

        // Extract meta tags
        let metaPattern = #"<meta\s+[^>]*>"#
        if let regex = try? NSRegularExpression(pattern: metaPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
            for match in matches {
                if let range = Range(match.range, in: content) {
                    let metaTag = String(content[range]).lowercased()
                    let originalTag = String(content[range])

                    // Helper to extract content attribute
                    func extractContent(from tag: String) -> String? {
                        if let contentRange = tag.range(of: #"content="([^"]+)""#, options: .regularExpression) {
                            let contentStr = String(tag[contentRange])
                            return contentStr.replacingOccurrences(of: "content=\"", with: "").replacingOccurrences(of: "\"", with: "")
                        }
                        if let contentRange = tag.range(of: #"content='([^']+)'"#, options: .regularExpression) {
                            let contentStr = String(tag[contentRange])
                            return contentStr.replacingOccurrences(of: "content='", with: "").replacingOccurrences(of: "'", with: "")
                        }
                        return nil
                    }

                    // Description
                    if metaTag.contains("name=\"description\"") || metaTag.contains("name='description'") {
                        description = extractContent(from: originalTag)
                    }

                    // Charset
                    if metaTag.contains("charset=") {
                        if let charsetRange = metaTag.range(of: #"charset="?([^"\s>]+)"?"#, options: .regularExpression) {
                            charset = String(metaTag[charsetRange]).replacingOccurrences(of: "charset=", with: "").replacingOccurrences(of: "\"", with: "")
                        }
                    }

                    // Keywords
                    if metaTag.contains("name=\"keywords\"") || metaTag.contains("name='keywords'") {
                        keywords = extractContent(from: originalTag)
                    }

                    // Author
                    if metaTag.contains("name=\"author\"") || metaTag.contains("name='author'") {
                        author = extractContent(from: originalTag)
                    }

                    // Open Graph
                    if metaTag.contains("property=\"og:title\"") || metaTag.contains("property='og:title'") {
                        ogTitle = extractContent(from: originalTag)
                    }
                    if metaTag.contains("property=\"og:description\"") || metaTag.contains("property='og:description'") {
                        ogDescription = extractContent(from: originalTag)
                    }
                    if metaTag.contains("property=\"og:image\"") || metaTag.contains("property='og:image'") {
                        ogImage = extractContent(from: originalTag)
                    }

                    // Twitter Card
                    if metaTag.contains("name=\"twitter:card\"") || metaTag.contains("name='twitter:card'") {
                        twitterCard = extractContent(from: originalTag)
                    }
                }
            }
        }

        // Extract language from <html lang="">
        if let langRange = content.range(of: #"<html[^>]*\slang="([^"]+)""#, options: .regularExpression) {
            let langTag = String(content[langRange])
            if let innerRange = langTag.range(of: #"lang="([^"]+)""#, options: .regularExpression) {
                language = String(langTag[innerRange]).replacingOccurrences(of: "lang=\"", with: "").replacingOccurrences(of: "\"", with: "")
            }
        }

        let metadata = HTMLMetadata(
            title: title,
            description: description,
            charset: charset,
            ogTitle: ogTitle,
            ogDescription: ogDescription,
            ogImage: ogImage,
            twitterCard: twitterCard,
            keywords: keywords,
            author: author,
            language: language
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Extended Image Metadata Extraction (IPTC/XMP)
    private static func extractImageExtendedMetadata(from url: URL) -> ImageExtendedMetadata? {
        let imageExtensions = ["jpg", "jpeg", "png", "tiff", "tif", "heic", "heif", "raw", "cr2", "nef", "arw", "dng"]
        guard let ext = url.pathExtension.lowercased() as String?,
              imageExtensions.contains(ext) else {
            return nil
        }

        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return nil
        }

        // Extract IPTC dictionary
        let iptcDict = imageProperties[kCGImagePropertyIPTCDictionary as String] as? [String: Any]

        // Extract TIFF dictionary for additional info
        let tiffDict = imageProperties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]

        var copyright: String?
        var creator: String?
        var keywords: String?
        var rating: Int?
        var creatorTool: String?
        var description: String?
        var headline: String?

        // IPTC fields
        if let iptc = iptcDict {
            copyright = iptc[kCGImagePropertyIPTCCopyrightNotice as String] as? String
            headline = iptc[kCGImagePropertyIPTCHeadline as String] as? String
            description = iptc[kCGImagePropertyIPTCCaptionAbstract as String] as? String

            if let keywordsArray = iptc[kCGImagePropertyIPTCKeywords as String] as? [String] {
                keywords = keywordsArray.joined(separator: ", ")
            }

            if let byline = iptc[kCGImagePropertyIPTCByline as String] as? [String] {
                creator = byline.joined(separator: ", ")
            }
        }

        // TIFF fields
        if let tiff = tiffDict {
            if copyright == nil {
                copyright = tiff[kCGImagePropertyTIFFCopyright as String] as? String
            }
            creatorTool = tiff[kCGImagePropertyTIFFSoftware as String] as? String
        }

        // Try to get rating from various sources
        if let ratingValue = imageProperties["Rating"] as? Int {
            rating = ratingValue
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

    // MARK: - Markdown Metadata Extraction
    private static func extractMarkdownMetadata(from url: URL) -> MarkdownMetadata? {
        let markdownExtensions = ["md", "markdown", "mdown", "mkd"]
        let ext = url.pathExtension.lowercased()
        guard markdownExtensions.contains(ext) else { return nil }

        // Limit file size to 1MB
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int64,
              fileSize < 1024 * 1024 else {
            return nil
        }

        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        var hasFrontmatter: Bool? = nil
        var frontmatterFormat: String? = nil
        var title: String? = nil
        var wordCount: Int? = nil
        var headingCount: Int? = nil
        var linkCount: Int? = nil
        var imageCount: Int? = nil
        var codeBlockCount: Int? = nil

        let lines = content.components(separatedBy: .newlines)

        // Check for frontmatter
        if lines.first == "---" {
            hasFrontmatter = true
            frontmatterFormat = "YAML"
            // Try to extract title from frontmatter
            var inFrontmatter = true
            for (index, line) in lines.enumerated() {
                if index == 0 { continue }
                if line == "---" {
                    inFrontmatter = false
                    continue
                }
                if inFrontmatter && line.hasPrefix("title:") {
                    title = line.replacingOccurrences(of: "title:", with: "").trimmingCharacters(in: .whitespaces)
                    title = title?.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                }
            }
        } else if lines.first == "+++" {
            hasFrontmatter = true
            frontmatterFormat = "TOML"
        } else if lines.first == "{" {
            hasFrontmatter = true
            frontmatterFormat = "JSON"
        } else {
            hasFrontmatter = false
        }

        // If no title from frontmatter, try first H1
        if title == nil {
            if let h1Line = lines.first(where: { $0.hasPrefix("# ") }) {
                title = h1Line.replacingOccurrences(of: "# ", with: "")
            }
        }

        // Count words (excluding code blocks and frontmatter)
        var inCodeBlock = false
        var inFrontmatterBlock = hasFrontmatter == true
        var words = 0
        var headings = 0
        var codeBlocks = 0

        for (index, line) in lines.enumerated() {
            // Skip frontmatter
            if inFrontmatterBlock {
                if (frontmatterFormat == "YAML" && line == "---" && index > 0) ||
                   (frontmatterFormat == "TOML" && line == "+++") {
                    inFrontmatterBlock = false
                }
                continue
            }

            // Track code blocks
            if line.hasPrefix("```") || line.hasPrefix("~~~") {
                if !inCodeBlock {
                    codeBlocks += 1
                }
                inCodeBlock.toggle()
                continue
            }

            if !inCodeBlock {
                // Count headings
                if line.hasPrefix("#") {
                    headings += 1
                }

                // Count words
                let lineWords = line.split(separator: " ").count
                words += lineWords
            }
        }

        wordCount = words
        headingCount = headings
        codeBlockCount = codeBlocks

        // Count links: [text](url) pattern
        let linkPattern = #"\[([^\]]+)\]\([^)]+\)"#
        if let regex = try? NSRegularExpression(pattern: linkPattern) {
            linkCount = regex.numberOfMatches(in: content, range: NSRange(content.startIndex..., in: content))
        }

        // Count images: ![alt](url) pattern
        let imagePattern = #"!\[([^\]]*)\]\([^)]+\)"#
        if let regex = try? NSRegularExpression(pattern: imagePattern) {
            imageCount = regex.numberOfMatches(in: content, range: NSRange(content.startIndex..., in: content))
        }

        let metadata = MarkdownMetadata(
            hasFrontmatter: hasFrontmatter,
            frontmatterFormat: frontmatterFormat,
            title: title,
            wordCount: wordCount,
            headingCount: headingCount,
            linkCount: linkCount,
            imageCount: imageCount,
            codeBlockCount: codeBlockCount
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Config File Metadata Extraction (JSON/YAML/TOML)
    private static func extractConfigMetadata(from url: URL) -> ConfigMetadata? {
        let ext = url.pathExtension.lowercased()
        let configExtensions = ["json", "yaml", "yml", "toml"]
        guard configExtensions.contains(ext) else { return nil }

        // Limit file size to 1MB
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int64,
              fileSize < 1024 * 1024 else {
            return nil
        }

        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        var format: String?
        var isValid: Bool?
        var keyCount: Int?
        var maxDepth: Int?
        var hasComments: Bool?
        let encoding = "UTF-8"

        switch ext {
        case "json":
            format = "JSON"
            // Validate JSON
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    isValid = true
                    keyCount = countJSONKeys(json)
                    maxDepth = calculateJSONDepth(json)
                } else if let _ = try JSONSerialization.jsonObject(with: data) as? [Any] {
                    isValid = true
                    keyCount = 0 // Array at root
                    maxDepth = 1
                }
            } catch {
                isValid = false
            }
            hasComments = false // JSON doesn't support comments

        case "yaml", "yml":
            format = "YAML"
            // Basic YAML validation - check for common patterns
            let lines = content.components(separatedBy: .newlines)
            let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            // Count keys (lines with "key:")
            let keyLines = nonEmptyLines.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.hasPrefix("#") && trimmed.contains(":") && !trimmed.hasPrefix("-")
            }
            keyCount = keyLines.count

            // Check for comments
            hasComments = nonEmptyLines.contains { $0.trimmingCharacters(in: .whitespaces).hasPrefix("#") }

            // Calculate depth by indentation
            var maxIndent = 0
            for line in nonEmptyLines {
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("#") { continue }
                let indent = line.prefix(while: { $0 == " " || $0 == "\t" }).count
                maxIndent = max(maxIndent, indent)
            }
            maxDepth = (maxIndent / 2) + 1

            // Basic validation
            isValid = !content.isEmpty && keyCount! > 0

        case "toml":
            format = "TOML"
            let lines = content.components(separatedBy: .newlines)
            let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            // Count keys
            let keyLines = nonEmptyLines.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.hasPrefix("#") && !trimmed.hasPrefix("[") && trimmed.contains("=")
            }
            keyCount = keyLines.count

            // Count sections for depth
            let sectionLines = nonEmptyLines.filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("[") }
            let maxSectionDepth = sectionLines.map { line -> Int in
                let dots = line.filter { $0 == "." }.count
                return dots + 1
            }.max() ?? 1
            maxDepth = maxSectionDepth

            // Check for comments
            hasComments = nonEmptyLines.contains { $0.trimmingCharacters(in: .whitespaces).hasPrefix("#") }

            // Basic validation
            isValid = !content.isEmpty

        default:
            return nil
        }

        let metadata = ConfigMetadata(
            format: format,
            isValid: isValid,
            keyCount: keyCount,
            maxDepth: maxDepth,
            hasComments: hasComments,
            encoding: encoding
        )

        return metadata.hasData ? metadata : nil
    }

    // Helper function to count JSON keys recursively
    private static func countJSONKeys(_ dict: [String: Any]) -> Int {
        var count = dict.keys.count
        for value in dict.values {
            if let nestedDict = value as? [String: Any] {
                count += countJSONKeys(nestedDict)
            } else if let array = value as? [Any] {
                for item in array {
                    if let nestedDict = item as? [String: Any] {
                        count += countJSONKeys(nestedDict)
                    }
                }
            }
        }
        return count
    }

    // Helper function to calculate JSON depth
    private static func calculateJSONDepth(_ dict: [String: Any]) -> Int {
        var maxChildDepth = 0
        for value in dict.values {
            if let nestedDict = value as? [String: Any] {
                maxChildDepth = max(maxChildDepth, calculateJSONDepth(nestedDict))
            } else if let array = value as? [Any] {
                for item in array {
                    if let nestedDict = item as? [String: Any] {
                        maxChildDepth = max(maxChildDepth, calculateJSONDepth(nestedDict))
                    }
                }
            }
        }
        return maxChildDepth + 1
    }

    // MARK: - PSD Metadata Extraction
    private static func extractPSDMetadata(from url: URL) -> PSDMetadata? {
        let psdExtensions = ["psd", "psb"]
        let ext = url.pathExtension.lowercased()
        guard psdExtensions.contains(ext) else { return nil }

        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            return nil
        }

        // PSD file format: https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/
        // Header is 26 bytes
        guard data.count >= 26 else { return nil }

        // Check magic number "8BPS"
        let magic = data.prefix(4)
        guard String(data: magic, encoding: .ascii) == "8BPS" else { return nil }

        var layerCount: Int?
        var colorMode: String?
        var bitDepth: Int?
        var dimensions: String?
        var hasTransparency: Bool?

        // Version (2 bytes at offset 4)
        let version = data.subdata(in: 4..<6).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }

        // Channels (2 bytes at offset 12)
        let channels = data.subdata(in: 12..<14).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        hasTransparency = channels > 3 // More than RGB means alpha channel

        // Height (4 bytes at offset 14)
        let height = data.subdata(in: 14..<18).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }

        // Width (4 bytes at offset 18)
        let width = data.subdata(in: 18..<22).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }

        dimensions = "\(width) × \(height)"

        // Bit depth (2 bytes at offset 22)
        let depth = data.subdata(in: 22..<24).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        bitDepth = Int(depth)

        // Color mode (2 bytes at offset 24)
        let mode = data.subdata(in: 24..<26).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        switch mode {
        case 0: colorMode = "Bitmap"
        case 1: colorMode = "Grayscale"
        case 2: colorMode = "Indexed"
        case 3: colorMode = "RGB"
        case 4: colorMode = "CMYK"
        case 7: colorMode = "Multichannel"
        case 8: colorMode = "Duotone"
        case 9: colorMode = "Lab"
        default: colorMode = "Unknown"
        }

        // Layer count requires parsing more of the file structure
        // For simplicity, we'll use the channel count as an approximation
        // or try to find layer info section

        let metadata = PSDMetadata(
            layerCount: layerCount,
            colorMode: colorMode,
            bitDepth: bitDepth,
            resolution: nil, // Would require parsing image resources section
            hasTransparency: hasTransparency,
            dimensions: dimensions
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Executable Metadata Extraction
    private static func extractExecutableMetadata(from url: URL) -> ExecutableMetadata? {
        // Check if file is executable
        let fileManager = FileManager.default
        guard fileManager.isExecutableFile(atPath: url.path) else { return nil }

        // Skip directories and known non-executable extensions
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue else {
            return nil
        }

        // Skip script files (already handled by code metadata)
        let scriptExtensions = ["sh", "bash", "zsh", "py", "rb", "pl", "js", "ts"]
        if scriptExtensions.contains(url.pathExtension.lowercased()) {
            return nil
        }

        var architecture: String?
        var isCodeSigned: Bool?
        var signingAuthority: String?
        var minimumOS: String?
        var sdkVersion: String?
        var fileType: String?

        // Use file command to detect file type
        let fileProcess = Process()
        fileProcess.executableURL = URL(fileURLWithPath: "/usr/bin/file")
        fileProcess.arguments = ["-b", url.path]
        let filePipe = Pipe()
        fileProcess.standardOutput = filePipe
        fileProcess.standardError = Pipe()

        if runProcessWithTimeout(fileProcess, timeout: 3.0) {
            let fileData = filePipe.fileHandleForReading.readDataToEndOfFile()
            if let fileOutput = String(data: fileData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                // Check if it's a Mach-O binary
                if fileOutput.contains("Mach-O") {
                    if fileOutput.contains("universal") || fileOutput.contains("fat") {
                        architecture = "Universal"
                    } else if fileOutput.contains("arm64") {
                        architecture = "arm64"
                    } else if fileOutput.contains("x86_64") {
                        architecture = "x86_64"
                    }

                    if fileOutput.contains("executable") {
                        fileType = "Mach-O Executable"
                    } else if fileOutput.contains("dynamically linked shared library") {
                        fileType = "Dynamic Library"
                    } else if fileOutput.contains("bundle") {
                        fileType = "Mach-O Bundle"
                    }
                } else {
                    // Not a Mach-O binary
                    return nil
                }
            }
        }

        // Check code signature using codesign
        let codesignProcess = Process()
        codesignProcess.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        codesignProcess.arguments = ["-dv", url.path]
        let codesignPipe = Pipe()
        let codesignErrorPipe = Pipe()
        codesignProcess.standardOutput = codesignPipe
        codesignProcess.standardError = codesignErrorPipe

        if runProcessWithTimeout(codesignProcess, timeout: 3.0) {
            let errorData = codesignErrorPipe.fileHandleForReading.readDataToEndOfFile()
            if let errorOutput = String(data: errorData, encoding: .utf8) {
                isCodeSigned = !errorOutput.contains("not signed")

                // Extract signing authority
                if let authorityRange = errorOutput.range(of: #"Authority=([^\n]+)"#, options: .regularExpression) {
                    signingAuthority = String(errorOutput[authorityRange])
                        .replacingOccurrences(of: "Authority=", with: "")
                        .trimmingCharacters(in: .whitespaces)
                }
            }
        } else {
            isCodeSigned = false
        }

        // Use otool to get SDK and minimum OS version
        let otoolProcess = Process()
        otoolProcess.executableURL = URL(fileURLWithPath: "/usr/bin/otool")
        otoolProcess.arguments = ["-l", url.path]
        let otoolPipe = Pipe()
        otoolProcess.standardOutput = otoolPipe
        otoolProcess.standardError = Pipe()

        if runProcessWithTimeout(otoolProcess, timeout: 3.0) {
            let otoolData = otoolPipe.fileHandleForReading.readDataToEndOfFile()
            if let otoolOutput = String(data: otoolData, encoding: .utf8) {
                // Extract minimum OS version
                if let minVersionRange = otoolOutput.range(of: #"minos\s+([\d.]+)"#, options: .regularExpression) {
                    let match = String(otoolOutput[minVersionRange])
                    minimumOS = match.components(separatedBy: .whitespaces).last
                }

                // Extract SDK version
                if let sdkRange = otoolOutput.range(of: #"sdk\s+([\d.]+)"#, options: .regularExpression) {
                    let match = String(otoolOutput[sdkRange])
                    sdkVersion = match.components(separatedBy: .whitespaces).last
                }
            }
        }

        let metadata = ExecutableMetadata(
            architecture: architecture,
            isCodeSigned: isCodeSigned,
            signingAuthority: signingAuthority,
            minimumOS: minimumOS,
            sdkVersion: sdkVersion,
            fileType: fileType
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - App Bundle Metadata Extraction
    private static func extractAppBundleMetadata(from url: URL) -> AppBundleMetadata? {
        // Check if it's a .app bundle
        guard url.pathExtension.lowercased() == "app" else { return nil }

        // Check if it's a directory (bundle)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }

        // Read Info.plist
        let infoPlistPath = url.appendingPathComponent("Contents/Info.plist")
        guard let plistData = try? Data(contentsOf: infoPlistPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }

        var bundleID: String?
        var version: String?
        var buildNumber: String?
        var minimumOS: String?
        var category: String?
        var copyright: String?
        var isCodeSigned: Bool?
        var hasEntitlements: Bool?

        bundleID = plist["CFBundleIdentifier"] as? String
        version = plist["CFBundleShortVersionString"] as? String
        buildNumber = plist["CFBundleVersion"] as? String
        minimumOS = plist["LSMinimumSystemVersion"] as? String
        category = plist["LSApplicationCategoryType"] as? String
        copyright = plist["NSHumanReadableCopyright"] as? String

        // Check code signature
        let codesignProcess = Process()
        codesignProcess.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        codesignProcess.arguments = ["-dv", url.path]
        let codesignPipe = Pipe()
        codesignProcess.standardOutput = codesignPipe
        codesignProcess.standardError = codesignPipe

        if runProcessWithTimeout(codesignProcess, timeout: 3.0) {
            let data = codesignPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                isCodeSigned = !output.contains("not signed")
            }
        }

        // Check for entitlements
        let entitlementsProcess = Process()
        entitlementsProcess.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        entitlementsProcess.arguments = ["-d", "--entitlements", "-", url.path]
        let entitlementsPipe = Pipe()
        entitlementsProcess.standardOutput = entitlementsPipe
        entitlementsProcess.standardError = Pipe()

        if runProcessWithTimeout(entitlementsProcess, timeout: 3.0) {
            let data = entitlementsPipe.fileHandleForReading.readDataToEndOfFile()
            hasEntitlements = data.count > 100 // Has meaningful entitlements data
        }

        let metadata = AppBundleMetadata(
            bundleID: bundleID,
            version: version,
            buildNumber: buildNumber,
            minimumOS: minimumOS,
            category: category,
            copyright: copyright,
            isCodeSigned: isCodeSigned,
            hasEntitlements: hasEntitlements
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - SQLite Metadata Extraction
    private static func extractSQLiteMetadata(from url: URL) -> SQLiteMetadata? {
        let sqliteExtensions = ["db", "sqlite", "sqlite3", "db3"]
        let ext = url.pathExtension.lowercased()
        guard sqliteExtensions.contains(ext) else { return nil }

        // Check SQLite magic number
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              data.count >= 16 else {
            return nil
        }

        let magic = String(data: data.prefix(16), encoding: .utf8)
        guard magic?.hasPrefix("SQLite format") == true else {
            return nil
        }

        var db: OpaquePointer?

        // Open database in read-only mode
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return nil
        }

        defer {
            sqlite3_close(db)
        }

        var tableCount: Int?
        var indexCount: Int?
        var triggerCount: Int?
        var viewCount: Int?
        var totalRows: Int?
        var schemaVersion: Int?
        var pageSize: Int?
        var encoding: String?

        // Helper function to execute a single-value query
        func queryInt(_ sql: String) -> Int? {
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return nil
            }
            defer { sqlite3_finalize(statement) }

            if sqlite3_step(statement) == SQLITE_ROW {
                return Int(sqlite3_column_int64(statement, 0))
            }
            return nil
        }

        func queryString(_ sql: String) -> String? {
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return nil
            }
            defer { sqlite3_finalize(statement) }

            if sqlite3_step(statement) == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    return String(cString: cString)
                }
            }
            return nil
        }

        // Query metadata using SQLite3 C API
        tableCount = queryInt("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
        indexCount = queryInt("SELECT COUNT(*) FROM sqlite_master WHERE type='index'")
        triggerCount = queryInt("SELECT COUNT(*) FROM sqlite_master WHERE type='trigger'")
        viewCount = queryInt("SELECT COUNT(*) FROM sqlite_master WHERE type='view'")
        schemaVersion = queryInt("PRAGMA schema_version")
        pageSize = queryInt("PRAGMA page_size")
        encoding = queryString("PRAGMA encoding")

        // Skip row count - can be slow on large databases
        totalRows = nil

        let metadata = SQLiteMetadata(
            tableCount: tableCount,
            indexCount: indexCount,
            triggerCount: triggerCount,
            viewCount: viewCount,
            totalRows: totalRows,
            schemaVersion: schemaVersion,
            pageSize: pageSize,
            encoding: encoding
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Git Repository Metadata Extraction
    private static func extractGitMetadata(from url: URL) -> GitMetadata? {
        // Check if this is a directory containing .git
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }

        let gitDir = url.appendingPathComponent(".git")
        guard FileManager.default.fileExists(atPath: gitDir.path) else {
            return nil
        }

        var branchCount: Int?
        var currentBranch: String?
        var commitCount: Int?
        var lastCommitDate: String?
        var lastCommitMessage: String?
        var remoteURL: String?
        var hasUncommittedChanges: Bool?
        var tagCount: Int?

        // Get current branch
        let branchProcess = Process()
        branchProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        branchProcess.arguments = ["-C", url.path, "branch", "--show-current"]
        let branchPipe = Pipe()
        branchProcess.standardOutput = branchPipe
        branchProcess.standardError = Pipe()

        if runProcessWithTimeout(branchProcess, timeout: 3.0) {
            let data = branchPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                currentBranch = output
            }
        }

        // Get branch count
        let branchCountProcess = Process()
        branchCountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        branchCountProcess.arguments = ["-C", url.path, "branch", "-a"]
        let branchCountPipe = Pipe()
        branchCountProcess.standardOutput = branchCountPipe
        branchCountProcess.standardError = Pipe()

        if runProcessWithTimeout(branchCountProcess, timeout: 3.0) {
            let data = branchCountPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                branchCount = output.components(separatedBy: .newlines).filter { !$0.isEmpty }.count
            }
        }

        // Get commit count
        let commitCountProcess = Process()
        commitCountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        commitCountProcess.arguments = ["-C", url.path, "rev-list", "--count", "HEAD"]
        let commitCountPipe = Pipe()
        commitCountProcess.standardOutput = commitCountPipe
        commitCountProcess.standardError = Pipe()

        if runProcessWithTimeout(commitCountProcess, timeout: 3.0) {
            let data = commitCountPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                commitCount = Int(output)
            }
        }

        // Get last commit info
        let logProcess = Process()
        logProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        logProcess.arguments = ["-C", url.path, "log", "-1", "--format=%ci|%s"]
        let logPipe = Pipe()
        logProcess.standardOutput = logPipe
        logProcess.standardError = Pipe()

        if runProcessWithTimeout(logProcess, timeout: 3.0) {
            let data = logPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                let parts = output.components(separatedBy: "|")
                if parts.count >= 1 {
                    lastCommitDate = parts[0]
                }
                if parts.count >= 2 {
                    lastCommitMessage = parts[1]
                }
            }
        }

        // Get remote URL
        let remoteProcess = Process()
        remoteProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        remoteProcess.arguments = ["-C", url.path, "remote", "get-url", "origin"]
        let remotePipe = Pipe()
        remoteProcess.standardOutput = remotePipe
        remoteProcess.standardError = Pipe()

        if runProcessWithTimeout(remoteProcess, timeout: 3.0) {
            let data = remotePipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                remoteURL = output
            }
        }

        // Check for uncommitted changes
        let statusProcess = Process()
        statusProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        statusProcess.arguments = ["-C", url.path, "status", "--porcelain"]
        let statusPipe = Pipe()
        statusProcess.standardOutput = statusPipe
        statusProcess.standardError = Pipe()

        if runProcessWithTimeout(statusProcess, timeout: 3.0) {
            let data = statusPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                hasUncommittedChanges = !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }

        // Get tag count
        let tagProcess = Process()
        tagProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        tagProcess.arguments = ["-C", url.path, "tag"]
        let tagPipe = Pipe()
        tagProcess.standardOutput = tagPipe
        tagProcess.standardError = Pipe()

        if runProcessWithTimeout(tagProcess, timeout: 3.0) {
            let data = tagPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                tagCount = output.components(separatedBy: .newlines).filter { !$0.isEmpty }.count
            }
        }

        let metadata = GitMetadata(
            branchCount: branchCount,
            currentBranch: currentBranch,
            commitCount: commitCount,
            lastCommitDate: lastCommitDate,
            lastCommitMessage: lastCommitMessage,
            remoteURL: remoteURL,
            hasUncommittedChanges: hasUncommittedChanges,
            tagCount: tagCount
        )

        return metadata.hasData ? metadata : nil
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
