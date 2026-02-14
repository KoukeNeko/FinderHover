//
//  FileInfo.swift
//  FinderHover
//
//  File metadata model
//

import Foundation
import AppKit
import QuickLookThumbnailing

// MARK: - FileInfo Structure

struct FileInfo {
    enum AnalysisNotice: String, Hashable {
        case largeFileProtection

        var localizedText: String {
            switch self {
            case .largeFileProtection:
                return "hover.analysisNotice.largeFileProtection".localized
            }
        }
    }

    struct MetadataExtractionPolicy {
        let enableLargeFileProtection: Bool
        let largeFileThresholds: Constants.LargeFileThresholds

        static let `default` = MetadataExtractionPolicy(
            enableLargeFileProtection: Constants.Defaults.enableLargeFileProtection,
            largeFileThresholds: Constants.Performance.largeFileThresholds
        )

        static func from(settings: AppSettings) -> MetadataExtractionPolicy {
            MetadataExtractionPolicy(
                enableLargeFileProtection: settings.enableLargeFileProtection,
                largeFileThresholds: Constants.Performance.largeFileThresholds
            )
        }
    }

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

    // System metadata (tags, quarantine, links, etc.)
    let systemMetadata: SystemMetadata?

    // File system advanced metadata (volume info, allocated size, etc.)
    let fileSystemAdvancedMetadata: FileSystemAdvancedMetadata?

    // 3D model metadata
    let model3DMetadata: Model3DMetadata?

    // Xcode project metadata
    let xcodeProjectMetadata: XcodeProjectMetadata?

    // Analysis status hint shown in hover view
    let analysisNotice: AnalysisNotice?

    // MARK: - Computed Properties

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

    // MARK: - Thumbnail Generation

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

        QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnail, _, _ in
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

    // MARK: - Factory Method

    static func from(path: String) -> FileInfo? {
        from(path: path, policy: .default)
    }

    static func from(path: String, policy: MetadataExtractionPolicy) -> FileInfo? {
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
            var analysisNotices = Set<AnalysisNotice>()

            // Extract metadata using the new Extractor modules
            let exifData = MediaExtractor.extractEXIFData(from: url)
            let videoMetadata = MediaExtractor.extractVideoMetadata(from: url)
            let audioMetadata = MediaExtractor.extractAudioMetadata(from: url)
            let imageExtendedMetadata = MediaExtractor.extractImageExtendedMetadata(from: url)

            // Handle PDF/Vector graphics logic
            var pdfMetadata: PDFMetadata? = nil
            var vectorGraphicsMetadata: VectorGraphicsMetadata? = nil

            if url.pathExtension.lowercased() == "pdf" {
                let metadata = DocumentExtractor.extractPDFMetadata(from: url)

                if let pageCount = metadata?.pageCount, pageCount > 1 {
                    pdfMetadata = metadata
                } else if metadata?.title != nil || metadata?.author != nil {
                    pdfMetadata = metadata
                } else {
                    vectorGraphicsMetadata = GraphicsExtractor.extractVectorGraphicsMetadata(
                        from: url,
                        policy: policy,
                        noticeRecorder: { analysisNotices.insert($0) }
                    )
                    if vectorGraphicsMetadata == nil {
                        pdfMetadata = metadata
                    }
                }
            } else {
                pdfMetadata = DocumentExtractor.extractPDFMetadata(from: url)
                vectorGraphicsMetadata = GraphicsExtractor.extractVectorGraphicsMetadata(
                    from: url,
                    policy: policy,
                    noticeRecorder: { analysisNotices.insert($0) }
                )
            }

            // Document metadata
            let officeMetadata = DocumentExtractor.extractOfficeMetadata(from: url)
            let ebookMetadata = DocumentExtractor.extractEbookMetadata(from: url)
            let markdownMetadata = DocumentExtractor.extractMarkdownMetadata(from: url)
            let htmlMetadata = DocumentExtractor.extractHTMLMetadata(from: url)
            let configMetadata = DocumentExtractor.extractConfigMetadata(from: url)

            // Developer metadata
            let codeMetadata = DeveloperExtractor.extractCodeMetadata(from: url)
            let gitMetadata = DeveloperExtractor.extractGitMetadata(from: url)
            let xcodeProjectMetadata = DeveloperExtractor.extractXcodeProjectMetadata(
                from: url,
                policy: policy,
                noticeRecorder: { analysisNotices.insert($0) }
            )
            let executableMetadata = DeveloperExtractor.extractExecutableMetadata(from: url)
            let appBundleMetadata = DeveloperExtractor.extractAppBundleMetadata(from: url)
            let sqliteMetadata = DeveloperExtractor.extractSQLiteMetadata(from: url)

            // Graphics metadata
            let psdMetadata = GraphicsExtractor.extractPSDMetadata(from: url)
            let model3DMetadata = GraphicsExtractor.extractModel3DMetadata(
                from: url,
                policy: policy,
                noticeRecorder: { analysisNotices.insert($0) }
            )

            // Archive metadata
            let archiveMetadata = ArchiveExtractor.extractArchiveMetadata(from: url)
            let diskImageMetadata = ArchiveExtractor.extractDiskImageMetadata(from: url)

            // Text metadata
            let fontMetadata = TextExtractor.extractFontMetadata(from: url)
            let subtitleMetadata = TextExtractor.extractSubtitleMetadata(
                from: url,
                policy: policy,
                noticeRecorder: { analysisNotices.insert($0) }
            )

            // System metadata
            let systemMetadata = SystemExtractor.extractSystemMetadata(from: url)
            let fileSystemAdvancedMetadata = SystemExtractor.extractFileSystemAdvancedMetadata(from: url)

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
                psdMetadata: psdMetadata,
                executableMetadata: executableMetadata,
                appBundleMetadata: appBundleMetadata,
                sqliteMetadata: sqliteMetadata,
                gitMetadata: gitMetadata,
                systemMetadata: systemMetadata,
                fileSystemAdvancedMetadata: fileSystemAdvancedMetadata,
                model3DMetadata: model3DMetadata,
                xcodeProjectMetadata: xcodeProjectMetadata,
                analysisNotice: analysisNotices.contains(.largeFileProtection) ? .largeFileProtection : nil
            )
        } catch {
            Logger.error("Failed to read file attributes: \(path)", error: error, subsystem: .fileSystem)
            return nil
        }
    }
}
