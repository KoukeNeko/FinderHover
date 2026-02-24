//
//  MetadataReader.swift
//  FinderHoverSyncExt
//
//  Lightweight, self-contained file metadata reader for the Finder Sync Extension.
//  All operations must complete synchronously and quickly because
//  menu(for:) is called on Finder's main thread.
//

import Foundation
import ImageIO
import AVFoundation
import PDFKit
import CoreText
import CoreServices
import Security

// MARK: - Value Objects

struct ExtensionFileMetadata {
    // Basic
    let typeLabel: String?
    let sizeLabel: String?
    let creationDateLabel: String?
    let modificationDateLabel: String?
    let lastAccessDateLabel: String?
    let permissionsLabel: String?
    let ownerLabel: String?

    // Type-specific
    let exifLabels: [String]
    let videoLabels: [String]
    let audioLabels: [String]
    let pdfLabels: [String]
    let fontLabels: [String]
    let appLabels: [String]
    let systemLabels: [String]

    // File path (displayed at the very bottom)
    let filePathLabel: String?
}

// MARK: - Reader

enum MetadataReader {

    // MARK: - Public Interface

    static func read(url: URL) -> ExtensionFileMetadata {
        let rv = fetchResourceValues(for: url)
        let isDirectory = rv.isDirectory ?? false
        let fileSize = rv.fileSize.map { Int64($0) } ?? 0

        return ExtensionFileMetadata(
            typeLabel: buildTypeLabel(rv: rv, isDirectory: isDirectory, url: url),
            sizeLabel: buildSizeLabel(url: url, fileSize: fileSize, isDirectory: isDirectory),
            creationDateLabel: rv.creationDate.flatMap { label("ext.label.created", date: $0) },
            modificationDateLabel: rv.contentModificationDate.flatMap { label("ext.label.modified", date: $0) },
            lastAccessDateLabel: ExtensionSettings.showLastAccessDate
                ? readLastAccessDate(url: url) : nil,
            permissionsLabel: ExtensionSettings.showPermissions
                ? buildPermissionsLabel(url: url) : nil,
            ownerLabel: ExtensionSettings.showOwner
                ? buildOwnerLabel(url: url) : nil,
            exifLabels: buildEXIFLabels(for: url),
            videoLabels: buildVideoLabels(for: url),
            audioLabels: buildAudioLabels(for: url),
            pdfLabels: buildPDFLabels(for: url),
            fontLabels: buildFontLabels(for: url),
            appLabels: buildAppBundleLabels(for: url),
            systemLabels: buildSystemLabels(for: url),
            filePathLabel: ExtensionSettings.showFilePath
                ? label("ext.label.filePath", value: url.path) : nil
        )
    }

    static func readFileSize(url: URL) -> Int64? {
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let size = values.fileSize else { return nil }
        return Int64(size)
    }

    // MARK: - Resource Values

    private static func fetchResourceValues(for url: URL) -> URLResourceValues {
        let keys: Set<URLResourceKey> = [
            .fileSizeKey, .isDirectoryKey, .creationDateKey,
            .contentModificationDateKey, .localizedTypeDescriptionKey,
            .localizedNameKey
        ]
        return (try? url.resourceValues(forKeys: keys)) ?? URLResourceValues()
    }

    // MARK: - Helpers

    private static func label(_ key: String, value: String) -> String {
        "\(NSLocalizedString(key, comment: ""))\t\(value)"
    }

    private static func label(_ key: String, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return label(key, value: formatter.string(from: date))
    }

    private static func formatDuration(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    // MARK: - Basic Labels

    private static func buildTypeLabel(rv: URLResourceValues, isDirectory: Bool, url: URL) -> String? {
        guard ExtensionSettings.showFileType else { return nil }
        let kind: String
        if let k = rv.localizedTypeDescription, !k.isEmpty {
            kind = k
        } else if isDirectory {
            kind = NSLocalizedString("ext.fileType.folder", comment: "")
        } else {
            let ext = url.pathExtension.uppercased()
            kind = ext.isEmpty
                ? NSLocalizedString("ext.fileType.file", comment: "")
                : "\(ext) \(NSLocalizedString("ext.fileType.file", comment: ""))"
        }
        return label("ext.label.type", value: kind)
    }

    private static func buildSizeLabel(url: URL, fileSize: Int64, isDirectory: Bool) -> String? {
        guard ExtensionSettings.showFileSize else { return nil }
        if isDirectory {
            if ExtensionSettings.showItemCount, let count = countDirectoryItems(url: url) {
                let unit = NSLocalizedString("ext.label.itemUnit", comment: "")
                return label("ext.label.size", value: "\(count) \(unit)")
            }
            return nil
        }
        return label("ext.label.size", value: ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
    }

    private static func countDirectoryItems(url: URL) -> Int? {
        try? FileManager.default.contentsOfDirectory(atPath: url.path).count
    }

    // MARK: - Last Access Date (via Spotlight)

    private static func readLastAccessDate(url: URL) -> String? {
        guard let mdItem = MDItemCreateWithURL(nil, url as CFURL),
              let date = MDItemCopyAttribute(mdItem, kMDItemLastUsedDate) as? Date else { return nil }
        return label("ext.label.lastAccess", date: date)
    }

    // MARK: - Permissions

    private static func buildPermissionsLabel(url: URL) -> String? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let posix = attrs[.posixPermissions] as? Int else { return nil }
        let mode = UInt16(posix)
        let rwx = { (r: Bool, w: Bool, x: Bool) -> String in
            "\(r ? "r" : "-")\(w ? "w" : "-")\(x ? "x" : "-")"
        }
        let perms = rwx(mode & 0o400 != 0, mode & 0o200 != 0, mode & 0o100 != 0)
                   + rwx(mode & 0o040 != 0, mode & 0o020 != 0, mode & 0o010 != 0)
                   + rwx(mode & 0o004 != 0, mode & 0o002 != 0, mode & 0o001 != 0)
        let octal = String(format: "%o", posix)
        return label("ext.label.permissions", value: "\(perms) (\(octal))")
    }

    // MARK: - Owner

    private static func buildOwnerLabel(url: URL) -> String? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let owner = attrs[.ownerAccountName] as? String else { return nil }
        return label("ext.label.owner", value: owner)
    }

    // MARK: - EXIF / Photo

    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "tiff", "tif", "heic", "heif",
        "raw", "cr2", "nef", "arw", "dng", "webp", "avif", "gif", "bmp"
    ]

    private static func buildEXIFLabels(for url: URL) -> [String] {
        guard ExtensionSettings.showEXIF,
              imageExtensions.contains(url.pathExtension.lowercased()),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
        else { return [] }

        var labels: [String] = []
        let tiff = props[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        let exif = props[kCGImagePropertyExifDictionary as String] as? [String: Any]
        let gps = props[kCGImagePropertyGPSDictionary as String] as? [String: Any]
        let iptc = props[kCGImagePropertyIPTCDictionary as String] as? [String: Any]

        // Camera
        if ExtensionSettings.showEXIFCamera {
            let make = tiff?[kCGImagePropertyTIFFMake as String] as? String ?? ""
            let model = tiff?[kCGImagePropertyTIFFModel as String] as? String ?? ""
            let camera = model.isEmpty ? make : (make.isEmpty ? model :
                (model.localizedCaseInsensitiveContains(make) ? model : "\(make) \(model)"))
            if !camera.isEmpty {
                labels.append(label("ext.label.camera", value: camera))
            }
        }

        // Lens
        if ExtensionSettings.showEXIFLens,
           let lens = exif?[kCGImagePropertyExifLensModel as String] as? String {
            labels.append(label("ext.label.lens", value: lens))
        }

        // Camera settings (focal length, aperture, shutter speed, ISO)
        if ExtensionSettings.showEXIFSettings {
            var settings: [String] = []
            if let f = exif?[kCGImagePropertyExifFocalLength as String] as? Double {
                settings.append(String(format: "%.0fmm", f))
            }
            if let a = exif?[kCGImagePropertyExifFNumber as String] as? Double {
                settings.append(String(format: "f/%.1g", a))
            }
            if let t = exif?[kCGImagePropertyExifExposureTime as String] as? Double {
                if t >= 1 { settings.append(String(format: "%.1fs", t)) }
                else { settings.append("1/\(Int(round(1.0 / t)))s") }
            }
            if let isoArr = exif?[kCGImagePropertyExifISOSpeedRatings as String] as? [Int],
               let iso = isoArr.first {
                settings.append("ISO \(iso)")
            }
            if !settings.isEmpty {
                labels.append(label("ext.label.settings", value: settings.joined(separator: "  ")))
            }
        }

        // Date taken
        if ExtensionSettings.showEXIFDateTaken,
           let dateStr = exif?[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            labels.append(label("ext.label.dateTaken", value: dateStr))
        }

        // Dimensions
        if ExtensionSettings.showEXIFDimensions,
           let w = props[kCGImagePropertyPixelWidth as String] as? Int,
           let h = props[kCGImagePropertyPixelHeight as String] as? Int {
            labels.append(label("ext.label.dimensions", value: "\(w) × \(h)"))
        }

        // Color profile
        if ExtensionSettings.showEXIFColorProfile,
           let profile = props[kCGImagePropertyProfileName as String] as? String {
            labels.append(label("ext.label.colorProfile", value: profile))
        }

        // Bit depth
        if ExtensionSettings.showEXIFBitDepth,
           let depth = props[kCGImagePropertyDepth as String] as? Int {
            labels.append(label("ext.label.bitDepth", value: "\(depth)-bit"))
        }

        // GPS
        if ExtensionSettings.showEXIFGPS,
           let lat = gps?[kCGImagePropertyGPSLatitude as String] as? Double,
           let latRef = gps?[kCGImagePropertyGPSLatitudeRef as String] as? String,
           let lon = gps?[kCGImagePropertyGPSLongitude as String] as? Double,
           let lonRef = gps?[kCGImagePropertyGPSLongitudeRef as String] as? String {
            let latVal = latRef == "S" ? -lat : lat
            let lonVal = lonRef == "W" ? -lon : lon
            labels.append(label("ext.label.gps", value: String(format: "%.4f, %.4f", latVal, lonVal)))
        }

        // Extended image info (IPTC)
        if ExtensionSettings.showImageExtended {
            if ExtensionSettings.showImageCopyright,
               let cr = iptc?[kCGImagePropertyIPTCCopyrightNotice as String] as? String {
                labels.append(label("ext.label.copyright", value: cr))
            }
            if ExtensionSettings.showImageCreator,
               let by = iptc?[kCGImagePropertyIPTCByline as String] as? [String],
               let first = by.first {
                labels.append(label("ext.label.creator", value: first))
            }
            if ExtensionSettings.showImageRating,
               let mdItem = MDItemCreateWithURL(nil, url as CFURL),
               let rating = MDItemCopyAttribute(mdItem, "kMDItemStarRating" as CFString) as? Int,
               rating > 0 {
                labels.append(label("ext.label.rating", value: String(repeating: "★", count: rating)))
            }
        }

        return labels
    }

    // MARK: - Video

    private static let videoExtensions: Set<String> = [
        "mp4", "mov", "m4v", "avi", "mkv", "webm", "flv", "wmv", "ts", "mts"
    ]

    private static func buildVideoLabels(for url: URL) -> [String] {
        guard ExtensionSettings.showVideo,
              videoExtensions.contains(url.pathExtension.lowercased())
        else { return [] }

        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
        var labels: [String] = []

        // Duration
        if ExtensionSettings.showVideoDuration {
            let sec = CMTimeGetSeconds(asset.duration)
            if sec.isFinite && sec > 0 {
                labels.append(label("ext.label.duration", value: formatDuration(Int(sec))))
            }
        }

        let videoTrack = asset.tracks(withMediaType: .video).first

        // Resolution
        if ExtensionSettings.showVideoResolution, let track = videoTrack {
            let size = track.naturalSize.applying(track.preferredTransform)
            let w = Int(abs(size.width))
            let h = Int(abs(size.height))
            if w > 0 && h > 0 {
                labels.append(label("ext.label.resolution", value: "\(w) × \(h)"))
            }
        }

        // Codec
        if ExtensionSettings.showVideoCodec, let track = videoTrack,
           let fdAny = track.formatDescriptions.first {
            let fd = fdAny as! CMFormatDescription
            let subType = CMFormatDescriptionGetMediaSubType(fd)
            let codec = fourCCString(subType)
            labels.append(label("ext.label.codec", value: codec))
        }

        // Frame rate
        if ExtensionSettings.showVideoFrameRate, let track = videoTrack {
            let fps = track.nominalFrameRate
            if fps > 0 {
                labels.append(label("ext.label.frameRate", value: String(format: "%.2f fps", fps)))
            }
        }

        // Bitrate
        if ExtensionSettings.showVideoBitrate, let track = videoTrack {
            let kbps = track.estimatedDataRate / 1000
            if kbps > 0 {
                let formatted = kbps > 1000
                    ? String(format: "%.1f Mbps", kbps / 1000)
                    : String(format: "%.0f kbps", kbps)
                labels.append(label("ext.label.bitrate", value: formatted))
            }
        }

        // HDR
        if ExtensionSettings.showVideoHDR, let track = videoTrack,
           let fdAny = track.formatDescriptions.first {
            let fd = fdAny as! CMFormatDescription
            if let tf = CMFormatDescriptionGetExtension(fd, extensionKey: kCMFormatDescriptionExtension_TransferFunction) as? String {
                if tf == "SMPTE-ST-2084-PQ" {
                    labels.append(label("ext.label.hdr", value: "HDR10 (PQ)"))
                } else if tf == "ITU_R_2100_HLG" || tf == "HLG" {
                    labels.append(label("ext.label.hdr", value: "HLG"))
                }
            }
        }

        // Container format
        if ExtensionSettings.showVideoContainerFormat {
            let ext = url.pathExtension.uppercased()
            let formatMap = ["MP4": "MPEG-4", "MOV": "QuickTime", "MKV": "Matroska",
                             "WEBM": "WebM", "AVI": "AVI", "FLV": "Flash Video",
                             "WMV": "Windows Media", "TS": "MPEG-TS", "MTS": "AVCHD"]
            if let fmt = formatMap[ext] {
                labels.append(label("ext.label.containerFormat", value: fmt))
            }
        }

        return labels
    }

    private static func fourCCString(_ code: FourCharCode) -> String {
        let chars = [
            Character(UnicodeScalar((code >> 24) & 0xFF)!),
            Character(UnicodeScalar((code >> 16) & 0xFF)!),
            Character(UnicodeScalar((code >> 8) & 0xFF)!),
            Character(UnicodeScalar(code & 0xFF)!)
        ]
        let raw = String(chars).trimmingCharacters(in: .whitespaces)
        let humanNames = ["avc1": "H.264", "hvc1": "H.265 (HEVC)", "hev1": "H.265 (HEVC)",
                          "vp09": "VP9", "av01": "AV1", "ap4h": "Apple ProRes 4444",
                          "apch": "Apple ProRes 422 HQ", "apcn": "Apple ProRes 422"]
        return humanNames[raw] ?? raw
    }

    // MARK: - Audio

    private static let audioExtensions: Set<String> = [
        "mp3", "m4a", "aac", "wav", "flac", "aiff", "aif", "ogg", "opus", "wma", "alac"
    ]

    private static func buildAudioLabels(for url: URL) -> [String] {
        guard ExtensionSettings.showAudio,
              audioExtensions.contains(url.pathExtension.lowercased())
        else { return [] }

        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
        var labels: [String] = []
        let meta = asset.commonMetadata

        func metaValue(_ id: AVMetadataIdentifier) -> String? {
            AVMetadataItem.metadataItems(from: meta, filteredByIdentifier: id).first?.stringValue
        }

        // Title
        if ExtensionSettings.showAudioTitle, let v = metaValue(.commonIdentifierTitle) {
            labels.append(label("ext.label.audioTitle", value: v))
        }
        // Artist
        if ExtensionSettings.showAudioArtist, let v = metaValue(.commonIdentifierArtist) {
            labels.append(label("ext.label.audioArtist", value: v))
        }
        // Album
        if ExtensionSettings.showAudioAlbum, let v = metaValue(.commonIdentifierAlbumName) {
            labels.append(label("ext.label.audioAlbum", value: v))
        }
        // Genre
        if ExtensionSettings.showAudioGenre, let v = metaValue(.commonIdentifierType) {
            labels.append(label("ext.label.audioGenre", value: v))
        }
        // Year
        if ExtensionSettings.showAudioYear, let v = metaValue(.commonIdentifierCreationDate) {
            labels.append(label("ext.label.audioYear", value: v))
        }
        // Duration
        if ExtensionSettings.showAudioDuration {
            let sec = CMTimeGetSeconds(asset.duration)
            if sec.isFinite && sec > 0 {
                labels.append(label("ext.label.duration", value: formatDuration(Int(sec))))
            }
        }
        // Bitrate & sample rate from audio track
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            if ExtensionSettings.showAudioBitrate {
                let kbps = audioTrack.estimatedDataRate / 1000
                if kbps > 0 {
                    labels.append(label("ext.label.bitrate", value: String(format: "%.0f kbps", kbps)))
                }
            }
            if ExtensionSettings.showAudioSampleRate,
               let fdAny = audioTrack.formatDescriptions.first {
                let fd = fdAny as! CMFormatDescription
                if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fd) {
                    let sr = asbd.pointee.mSampleRate
                    if sr > 0 {
                        let formatted = sr.truncatingRemainder(dividingBy: 1000) == 0
                            ? String(format: "%.0f kHz", sr / 1000)
                            : String(format: "%.1f kHz", sr / 1000)
                        labels.append(label("ext.label.sampleRate", value: formatted))
                    }
                }
            }
        }

        return labels
    }

    // MARK: - PDF

    private static func buildPDFLabels(for url: URL) -> [String] {
        guard ExtensionSettings.showPDF,
              url.pathExtension.lowercased() == "pdf",
              let pdf = PDFDocument(url: url)
        else { return [] }

        var labels: [String] = []
        let attrs = pdf.documentAttributes ?? [:]

        // Page count
        if ExtensionSettings.showPDFPageCount, pdf.pageCount > 0 {
            let unit = NSLocalizedString("ext.label.pageUnit", comment: "")
            labels.append(label("ext.label.pageCount", value: "\(pdf.pageCount) \(unit)"))
        }

        // Page size
        if ExtensionSettings.showPDFPageSize, let page = pdf.page(at: 0) {
            let bounds = page.bounds(for: .mediaBox)
            let wIn = bounds.width / 72.0
            let hIn = bounds.height / 72.0
            let sizeName = detectPageSize(wIn: wIn, hIn: hIn)
            let dims = String(format: "%.0f × %.0f pt", bounds.width, bounds.height)
            labels.append(label("ext.label.pageSize", value: sizeName.map { "\(dims) (\($0))" } ?? dims))
        }

        // Version
        if ExtensionSettings.showPDFVersion {
            labels.append(label("ext.label.pdfVersion",
                                value: "\(pdf.majorVersion).\(pdf.minorVersion)"))
        }

        // Title
        if ExtensionSettings.showPDFTitle,
           let v = attrs[PDFDocumentAttribute.titleAttribute] as? String, !v.isEmpty {
            labels.append(label("ext.label.pdfTitle", value: v))
        }

        // Author
        if ExtensionSettings.showPDFAuthor,
           let v = attrs[PDFDocumentAttribute.authorAttribute] as? String, !v.isEmpty {
            labels.append(label("ext.label.pdfAuthor", value: v))
        }

        // Encrypted
        if ExtensionSettings.showPDFEncrypted, pdf.isEncrypted {
            labels.append(label("ext.label.pdfEncrypted",
                                value: NSLocalizedString("ext.value.yes", comment: "")))
        }

        return labels
    }

    private static func detectPageSize(wIn: CGFloat, hIn: CGFloat) -> String? {
        let sizes: [(String, CGFloat, CGFloat)] = [
            ("Letter", 8.5, 11), ("A4", 8.27, 11.69), ("A5", 5.83, 8.27),
            ("A3", 11.69, 16.54), ("Legal", 8.5, 14), ("Tabloid", 11, 17)
        ]
        let (w, h) = (min(wIn, hIn), max(wIn, hIn))
        for (name, sw, sh) in sizes {
            if abs(w - min(sw, sh)) < 0.1 && abs(h - max(sw, sh)) < 0.1 { return name }
        }
        return nil
    }

    // MARK: - Font

    private static let fontExtensions: Set<String> = [
        "ttf", "otf", "ttc", "otc", "woff", "woff2", "dfont"
    ]

    private static func buildFontLabels(for url: URL) -> [String] {
        guard ExtensionSettings.showFont,
              fontExtensions.contains(url.pathExtension.lowercased())
        else { return [] }

        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let desc = descriptors.first
        else { return [] }

        var labels: [String] = []
        let font = CTFontCreateWithFontDescriptor(desc, 0, nil)

        if ExtensionSettings.showFontName {
            let name = CTFontCopyFullName(font) as String
            if !name.isEmpty { labels.append(label("ext.label.fontName", value: name)) }
        }
        if ExtensionSettings.showFontFamily {
            let family = CTFontCopyFamilyName(font) as String
            if !family.isEmpty { labels.append(label("ext.label.fontFamily", value: family)) }
        }
        if ExtensionSettings.showFontStyle {
            if let style = CTFontDescriptorCopyAttribute(desc, kCTFontStyleNameAttribute) as? String {
                labels.append(label("ext.label.fontStyle", value: style))
            }
        }
        if ExtensionSettings.showFontGlyphCount {
            let count = CTFontGetGlyphCount(font)
            if count > 0 { labels.append(label("ext.label.fontGlyphs", value: "\(count)")) }
        }

        return labels
    }

    // MARK: - App Bundle

    private static func buildAppBundleLabels(for url: URL) -> [String] {
        guard ExtensionSettings.showAppBundle,
              url.pathExtension.lowercased() == "app",
              (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        else { return [] }

        let infoPlistURL = url.appendingPathComponent("Contents/Info.plist")
        guard let plistData = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]
        else { return [] }

        var labels: [String] = []

        if ExtensionSettings.showAppBundleID,
           let bundleID = plist["CFBundleIdentifier"] as? String {
            labels.append(label("ext.label.appBundleID", value: bundleID))
        }
        if ExtensionSettings.showAppBundleVersion,
           let version = plist["CFBundleShortVersionString"] as? String {
            labels.append(label("ext.label.appVersion", value: version))
        }
        if ExtensionSettings.showAppBundleBuildNumber,
           let build = plist["CFBundleVersion"] as? String {
            labels.append(label("ext.label.appBuild", value: build))
        }
        if ExtensionSettings.showAppBundleMinimumOS,
           let minOS = plist["LSMinimumSystemVersion"] as? String {
            labels.append(label("ext.label.appMinOS", value: minOS))
        }
        if ExtensionSettings.showAppBundleCopyright,
           let copyright = plist["NSHumanReadableCopyright"] as? String, !copyright.isEmpty {
            labels.append(label("ext.label.appCopyright", value: copyright))
        }

        // Code signing check via Security framework (fast, no subprocess)
        if ExtensionSettings.showAppBundleCodeSigned {
            let signed = checkCodeSigned(url: url)
            let yesNo = signed
                ? NSLocalizedString("ext.value.yes", comment: "")
                : NSLocalizedString("ext.value.no", comment: "")
            labels.append(label("ext.label.appCodeSigned", value: yesNo))
        }

        // Entitlements check
        if ExtensionSettings.showAppBundleEntitlements {
            let hasEnt = checkHasEntitlements(url: url)
            let yesNo = hasEnt
                ? NSLocalizedString("ext.value.yes", comment: "")
                : NSLocalizedString("ext.value.no", comment: "")
            labels.append(label("ext.label.appEntitlements", value: yesNo))
        }

        return labels
    }

    private static func checkCodeSigned(url: URL) -> Bool {
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, SecCSFlags(), &staticCode) == errSecSuccess,
              let code = staticCode
        else { return false }
        return SecStaticCodeCheckValidity(code, SecCSFlags(), nil) == errSecSuccess
    }

    private static func checkHasEntitlements(url: URL) -> Bool {
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, SecCSFlags(), &staticCode) == errSecSuccess,
              let code = staticCode
        else { return false }
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
              let dict = info as? [String: Any]
        else { return false }
        if let entitlements = dict["entitlements-dict"] as? [String: Any], !entitlements.isEmpty {
            return true
        }
        return false
    }

    // MARK: - System Metadata

    private static func buildSystemLabels(for url: URL) -> [String] {
        guard ExtensionSettings.showSystemMetadata else { return [] }
        var labels: [String] = []
        let path = url.path

        // Finder Tags
        if ExtensionSettings.showFinderTags,
           let rv = try? url.resourceValues(forKeys: [.tagNamesKey]),
           let tags = rv.tagNames, !tags.isEmpty {
            labels.append(label("ext.label.finderTags", value: tags.joined(separator: ", ")))
        }

        // Quarantine info (download date & downloader)
        if ExtensionSettings.showQuarantineInfo {
            var buffer = [CChar](repeating: 0, count: 1024)
            let length = getxattr(path, "com.apple.quarantine", &buffer, 1024, 0, 0)
            if length > 0 {
                let qString = String(cString: buffer)
                let components = qString.split(separator: ";")
                if components.count >= 2,
                   let timestamp = Double(components[1], radix: 16) {
                    let date = Date(timeIntervalSinceReferenceDate: timestamp)
                    labels.append(label("ext.label.downloadDate", date: date))
                }
                if components.count >= 3 {
                    let sourceApp = String(components[2])
                    if !sourceApp.isEmpty {
                        labels.append(label("ext.label.downloader", value: sourceApp))
                    }
                }
            }
        }

        // Where From (download source URL)
        if ExtensionSettings.showWhereFroms,
           let mdItem = MDItemCreateWithURL(nil, url as CFURL),
           let sources = MDItemCopyAttribute(mdItem, kMDItemWhereFroms) as? [String],
           let first = sources.first {
            let display = first.count > 60 ? String(first.prefix(60)) + "…" : first
            labels.append(label("ext.label.whereFrom", value: display))
        }

        // Hard link count
        if ExtensionSettings.showLinkInfo,
           let rv = try? url.resourceValues(forKeys: [.linkCountKey]),
           let linkCount = rv.linkCount, linkCount > 1 {
            labels.append(label("ext.label.hardLinks", value: "\(linkCount)"))
        }

        // Finder comment
        if ExtensionSettings.showFinderComment,
           let mdItem = MDItemCreateWithURL(nil, url as CFURL),
           let comment = MDItemCopyAttribute(mdItem, kMDItemFinderComment) as? String,
           !comment.isEmpty {
            labels.append(label("ext.label.finderComment", value: comment))
        }

        // Usage stats (open count & last used)
        if ExtensionSettings.showUsageStats,
           let mdItem = MDItemCreateWithURL(nil, url as CFURL) {
            if let useCount = MDItemCopyAttribute(mdItem, "kMDItemUseCount" as CFString) as? Int {
                labels.append(label("ext.label.useCount", value: "\(useCount)"))
            }
            if let lastUsed = MDItemCopyAttribute(mdItem, kMDItemLastUsedDate) as? Date {
                labels.append(label("ext.label.lastUsed", date: lastUsed))
            }
        }

        // UTI
        if ExtensionSettings.showUTI,
           let rv = try? url.resourceValues(forKeys: [.contentTypeKey]),
           let uti = rv.contentType {
            labels.append(label("ext.label.uti", value: uti.identifier))
        }

        return labels
    }

    // MARK: - Quarantine Hex Timestamp Parsing

    /// Parse quarantine timestamp from hex string (timeIntervalSinceReferenceDate)
    private static func Double(_ string: Substring, radix: Int) -> Double? {
        guard let intValue = Int(string, radix: radix) else { return nil }
        return Swift.Double(intValue)
    }
}
