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

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedModificationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modificationDate)
    }

    var formattedLastAccessDate: String {
        guard let date = lastAccessDate else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedCreationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
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
        let size = CGSize(width: 128, height: 128)
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
                    itemCount = nil
                }
            }

            // Check if hidden (starts with .)
            let isHidden = url.lastPathComponent.hasPrefix(".")

            // Get last access date (may not be available on all file systems)
            let lastAccessDate = attributes[.modificationDate] as? Date

            // Extract EXIF data for image files
            let exifData = extractEXIFData(from: url)

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
                exifData: exifData
            )
        } catch {
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
            // Format: "YYYY:MM:DD HH:MM:SS"
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            if let date = formatter.date(from: dateString) {
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                dateTaken = formatter.string(from: date)
            } else {
                dateTaken = dateString
            }
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
}
