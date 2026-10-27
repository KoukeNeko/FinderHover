//
//  PreviewSamples.swift
//  FinderHover
//
//  Sample files rendered by the settings preview, one per display section.
//

import Foundation

enum PreviewSamples {
    /// The sample whose popup best shows the given display section's fields.
    static func fileInfo(for sectionID: String) -> FileInfo {
        switch sectionID {
        case "settings.display.exif", "settings.display.imageExtended.title": return photo
        case "settings.display.video": return video
        case "settings.display.audio": return audio
        case "settings.display.pdf": return pdf
        case "settings.display.office": return office
        case "settings.display.archive": return archive
        case "settings.display.ebook": return ebook
        case "settings.display.code": return code
        case "settings.display.font.title": return font
        case "settings.display.diskImage.title": return diskImage
        case "settings.display.vectorGraphics.title": return vector
        case "settings.display.subtitle.title": return subtitle
        case "settings.display.html.title": return html
        case "settings.display.markdown.title": return markdown
        case "settings.display.config.title": return config
        case "settings.display.psd.title": return psd
        case "settings.display.executable.title": return executable
        case "settings.display.appBundle.title": return appBundle
        case "settings.display.sqlite.title": return sqlite
        case "settings.display.git.title": return git
        default: return notes
        }
    }

    static let photo = make(
        "DSC03757.ARW", folder: "Pictures/2026/新潟", size: 21_600_000,
        exif: EXIFData(camera: "SONY ILCE-7C", lens: "28-70mm F2.8 DG DN | Contemporary 021", focalLength: "28mm",
                       aperture: "ƒ/4.0", shutterSpeed: "1/15", iso: "ISO 500", dateTaken: "2026/9/2 21:33",
                       imageSize: "3936 × 2624", colorSpace: "RGB", gpsLocation: "37.704765°N, 138.827619°E",
                       colorProfile: "Display P3", bitDepth: 14, hasHDRGainMap: nil, hdrFormat: nil),
        imageExtended: ImageExtendedMetadata(copyright: "© 2026 doeshing", creator: "doeshing", keywords: "新潟, 夜景",
                                             rating: 4, creatorTool: "ILCE-7C v2.00", description: nil, headline: nil))

    static let video = make(
        "新潟花火.mov", folder: "Movies", size: 1_240_000_000,
        video: VideoMetadata(duration: "12:48", resolution: "3840×2160", codec: "HEVC", frameRate: "59.94 fps",
                             bitrate: "48.2 Mbps", videoTracks: 1, audioTracks: 1, hdrFormat: "HLG", colorPrimaries: "BT.2020",
                             transferFunction: "HLG", chapterCount: nil, subtitleTracks: nil, attachmentCount: nil,
                             containerFormat: "QuickTime"))

    static let audio = make(
        "03 月光.mp3", folder: "Music/德布西", size: 11_900_000,
        audio: AudioMetadata(title: "月光", artist: "德布西", album: "貝加馬斯克組曲", albumArtist: "德布西", genre: "古典",
                             year: "1905", duration: "5:12", bitrate: "320 kbps", sampleRate: "44.1 kHz", channels: "立體聲"))

    static let pdf = make(
        "attention-is-all-you-need.pdf", folder: "Documents/論文", size: 2_200_000,
        pdf: PDFMetadata(title: "Attention Is All You Need", author: "Ashish Vaswani, Noam Shazeer, Niki Parmar, et al.",
                         subject: "Neural machine translation", creator: "LaTeX with hyperref", producer: "pdfTeX-1.40.25",
                         creationDate: "2017/6/12 15:12", modificationDate: "2023/8/2 09:40", pageCount: 15,
                         pageSize: "Letter", version: "1.5", isEncrypted: false, keywords: "transformer, attention, NLP"))

    static let office = make(
        "Q3 規劃提案.docx", folder: "Documents/工作", size: 1_200_000,
        office: OfficeMetadata(title: "Q3 規劃", author: "陳德生", subject: "人力與時程", keywords: "規劃, Q3",
                               comment: "送審版", lastModifiedBy: "陳德生", creationDate: "2026/7/1 10:12",
                               modificationDate: "2026/10/22 18:40", pageCount: 12, wordCount: 3482, sheetCount: nil,
                               slideCount: nil, company: "FinderHover", category: "企劃"))

    static let archive = make(
        "Photos-2026-backup.zip", folder: "Backups", size: 8_200_000_000,
        archive: ArchiveMetadata(format: "ZIP", fileCount: 1284, uncompressedSize: 21_600_000_000,
                                 compressionRatio: 62.0, isEncrypted: true, comment: nil))

    static let ebook = make(
        "小王子.epub", folder: "Books", size: 3_400_000,
        ebook: EbookMetadata(title: "小王子", author: "安托萬·德·聖-修伯里", publisher: "時報出版", publicationDate: "2015",
                             isbn: "9789571362915", language: "zh-Hant", description: "一位來自 B612 小行星的王子遊歷各星球的故事。",
                             pageCount: 128))

    static let code = make(
        "HoverContentView.swift", folder: "Documents/GitHub/FinderHover/FinderHover/UI/Windows", size: 72_000,
        code: CodeMetadata(language: "Swift", lineCount: 1504, codeLines: 1290, commentLines: 64, blankLines: 150, encoding: "UTF-8"))

    static let font = make(
        "SF-Pro-Rounded-Bold.otf", folder: "Library/Fonts", size: 2_100_000,
        font: FontMetadata(fontName: "SF Pro Rounded Bold", fontFamily: "SF Pro Rounded", fontStyle: "Bold",
                           version: "20.0d7e3", designer: "Apple Inc.", copyright: "© 2015–2026 Apple Inc.", glyphCount: 9412))

    static let diskImage = make(
        "FinderHover-v1.10.0-beta.1.dmg", folder: "Downloads", size: 2_300_000,
        diskImage: DiskImageMetadata(format: "UDZO", totalSize: 16_000_000, compressedSize: 2_300_000, compressionRatio: 7.0,
                                     isEncrypted: false, partitionScheme: "GUID", fileSystem: "APFS"))

    static let vector = make(
        "logo.svg", folder: "Documents/設計", size: 18_000,
        vector: VectorGraphicsMetadata(format: "SVG", dimensions: "1024 × 1024", viewBox: "0 0 1024 1024", elementCount: 6,
                                       colorMode: "RGB", creator: "Figma", version: "1.1"))

    static let subtitle = make(
        "新潟花火.zh-Hant.srt", folder: "Movies", size: 42_000,
        subtitle: SubtitleMetadata(format: "SRT", encoding: "UTF-8", entryCount: 412, duration: "12:31", language: "zh-Hant",
                                   frameRate: nil, hasFormatting: false))

    static let html = make(
        "index.html", folder: "Documents/GitHub/FinderHover/website", size: 24_000,
        html: HTMLMetadata(title: "FinderHover — 在 Finder 懸停即可查看檔案資訊", description: "macOS 選單列工具，懸停即顯示檔案中繼資料。",
                           charset: "utf-8", ogTitle: "FinderHover", ogDescription: nil, ogImage: "og-card.png",
                           twitterCard: "summary_large_image", keywords: "macOS, Finder", author: "KoukeNeko", language: "zh-Hant"))

    static let markdown = make(
        "README.md", folder: "Documents/GitHub/FinderHover", size: 13_000,
        markdown: MarkdownMetadata(hasFrontmatter: false, frontmatterFormat: nil, title: "FinderHover", wordCount: 1453,
                                   headingCount: 33, linkCount: 11, imageCount: 2, codeBlockCount: 3))

    static let config = make(
        "package.json", folder: "Documents/GitHub/FinderHover/website", size: 1_800,
        config: ConfigMetadata(format: "JSON", isValid: true, keyCount: 42, maxDepth: 3, hasComments: false, encoding: "UTF-8"))

    static let psd = make(
        "海報.psd", folder: "Documents/設計", size: 186_000_000,
        psd: PSDMetadata(layerCount: 48, colorMode: "RGB", bitDepth: 16, resolution: "300 DPI", hasTransparency: true,
                         dimensions: "7016 × 9933"))

    static let executable = make(
        "ffmpeg", folder: "../../opt/homebrew/bin", size: 412_000,
        executable: ExecutableMetadata(architecture: "arm64", isCodeSigned: true, signingAuthority: "adhoc", minimumOS: "14.0",
                                       sdkVersion: "15.0", fileType: "Mach-O Executable"))

    static let appBundle = make(
        "FinderHover.app", folder: "../../Applications", size: 14_800_000, isDirectory: true,
        appBundle: AppBundleMetadata(bundleID: "dev.koukeneko.FinderHover", version: "1.10.0-beta.1", buildNumber: "47",
                                     minimumOS: "14.0", category: "工具程式", copyright: "© 2026 KoukeNeko",
                                     isCodeSigned: true, hasEntitlements: true))

    static let sqlite = make(
        "library.sqlite", folder: "Library/Application Support/FinderHover", size: 5_400_000,
        sqlite: SQLiteMetadata(tableCount: 12, indexCount: 18, triggerCount: 2, viewCount: 3, totalRows: 48_213,
                               schemaVersion: 7, pageSize: 4096, encoding: "UTF-8"))

    static let git = make(
        "FinderHover", folder: "Documents/GitHub", size: 0, isDirectory: true, itemCount: 26,
        git: GitMetadata(branchCount: 15, currentBranch: "beta", commitCount: 424, lastCommitDate: "2026-10-25",
                         lastCommitMessage: "fix(extractors): close remaining git and output-size gaps",
                         remoteURL: "https://github.com/KoukeNeko/FinderHover.git", hasUncommittedChanges: false, tagCount: 45))

    static let notes = make("會議記錄.txt", folder: "Documents/工作", size: 4_000)

    // MARK: Builder

    /// Fills in the attributes every sample shares (dates, owner, system and volume info).
    private static func make(
        _ name: String,
        folder: String,
        size: Int64,
        isDirectory: Bool = false,
        itemCount: Int? = nil,
        exif: EXIFData? = nil,
        video: VideoMetadata? = nil,
        audio: AudioMetadata? = nil,
        pdf: PDFMetadata? = nil,
        office: OfficeMetadata? = nil,
        archive: ArchiveMetadata? = nil,
        ebook: EbookMetadata? = nil,
        code: CodeMetadata? = nil,
        font: FontMetadata? = nil,
        diskImage: DiskImageMetadata? = nil,
        vector: VectorGraphicsMetadata? = nil,
        subtitle: SubtitleMetadata? = nil,
        html: HTMLMetadata? = nil,
        imageExtended: ImageExtendedMetadata? = nil,
        markdown: MarkdownMetadata? = nil,
        config: ConfigMetadata? = nil,
        psd: PSDMetadata? = nil,
        executable: ExecutableMetadata? = nil,
        appBundle: AppBundleMetadata? = nil,
        sqlite: SQLiteMetadata? = nil,
        git: GitMetadata? = nil
    ) -> FileInfo {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let path = home.appendingPathComponent(folder).appendingPathComponent(name).standardizedFileURL.path
        let created = Date(timeIntervalSince1970: 1_788_415_320)   // 2026-09-03 14:02
        let modified = Date(timeIntervalSince1970: 1_788_415_320)
        let ext = (name as NSString).pathExtension
        let system = SystemMetadata(
            finderTags: nil, whereFroms: nil, quarantineInfo: nil,
            linkInfo: LinkInfo(isSymlink: false, symlinkTarget: nil, hardLinkCount: 1),
            usageStats: UsageStats(useCount: 10, lastUsedDate: "2026/10/24 14:41"),
            iCloudStatus: nil, finderComment: nil,
            uti: isDirectory ? "public.folder" : "public.data",
            extendedAttributes: nil, aliasTarget: nil, isAliasFile: false)
        let volume = FileSystemAdvancedMetadata(
            allocatedSize: size, attributeModDate: nil, resourceForkSize: nil, dataForkSize: nil,
            volumeName: "Macintosh HD", volumeFormat: "APFS", volumeAvailable: 97_300_000_000, volumeTotal: 994_700_000_000,
            spotlightIndexed: true, fileProviderName: nil, fileProviderStatus: nil)

        return FileInfo(
            name: name, path: path, size: size, modificationDate: modified, creationDate: created,
            fileType: isDirectory ? "NSFileTypeDirectory" : "NSFileTypeRegular", isDirectory: isDirectory,
            fileExtension: ext.isEmpty ? nil : ext, lastAccessDate: modified, permissions: "644", owner: NSUserName(),
            isReadable: true, isWritable: true, isExecutable: executable != nil, itemCount: itemCount, isHidden: false,
            exifData: exif, videoMetadata: video, audioMetadata: audio, pdfMetadata: pdf, officeMetadata: office,
            archiveMetadata: archive, ebookMetadata: ebook, codeMetadata: code, fontMetadata: font,
            diskImageMetadata: diskImage, vectorGraphicsMetadata: vector, subtitleMetadata: subtitle,
            htmlMetadata: html, imageExtendedMetadata: imageExtended, markdownMetadata: markdown,
            configMetadata: config, psdMetadata: psd, executableMetadata: executable, appBundleMetadata: appBundle,
            sqliteMetadata: sqlite, gitMetadata: git, systemMetadata: system, fileSystemAdvancedMetadata: volume,
            model3DMetadata: nil, xcodeProjectMetadata: nil, analysisNotice: nil)
    }
}
