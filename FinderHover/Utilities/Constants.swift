//
//  Constants.swift
//  FinderHover
//
//  Centralized constants to eliminate magic numbers throughout the codebase
//

import Foundation
import CoreGraphics

/// Application-wide constants
enum Constants {

    // MARK: - Mouse Tracking
    enum MouseTracking {
        /// Debounce delay for hover detection (milliseconds)
        /// This prevents showing the window on brief mouse movements
        static let hoverDebounceDelay: Int = 300

        /// Timer interval for checking if file is being renamed (seconds)
        /// Checks frequently to quickly hide window when renaming starts
        static let renamingCheckInterval: TimeInterval = 0.1
    }

    // MARK: - Performance
    enum Performance {
        /// Throttle interval for hide checks on mouse move (milliseconds)
        static let hoverHideThrottleMs: Int = 100

        /// Delay before retrying timed-out accessibility calls (milliseconds)
        static let accessibilityRetryDelayMs: Int = 120

        /// File size thresholds for protection mode
        static let largeFileThresholds = LargeFileThresholds(
            subtitleBytes: 2 * 1024 * 1024,
            vectorTextBytes: 2 * 1024 * 1024,
            modelTextBytes: 8 * 1024 * 1024,
            xcodeProjectBytes: 6 * 1024 * 1024
        )
    }

    struct LargeFileThresholds {
        let subtitleBytes: Int64
        let vectorTextBytes: Int64
        let modelTextBytes: Int64
        let xcodeProjectBytes: Int64
    }

    // MARK: - Window Layout
    enum WindowLayout {
        /// Temporary container height for size calculation
        /// Large enough to accommodate any reasonable content
        static let tempContainerHeight: CGFloat = 5000

        /// Default corner radius for macOS style windows
        static let macOSCornerRadius: CGFloat = 10

        /// Corner radius for Windows style windows (no rounding)
        static let windowsCornerRadius: CGFloat = 0

        /// Border width for macOS style with blur effect
        static let macOSBorderWidth: CGFloat = 0.5

        /// Minimum padding from screen edge
        static let screenEdgePadding: CGFloat = 10
    }

    // MARK: - Thumbnail Generation
    enum Thumbnail {
        /// Standard thumbnail size for file icons
        static let standardSize: CGFloat = 128

        /// Compact mode icon size
        static let compactIconSize: CGFloat = 32

        /// Normal mode icon size
        static let normalIconSize: CGFloat = 48
    }

    // MARK: - Version Compatibility
    enum Compatibility {
        /// macOS version where blur effect behavior changed
        /// Versions <= 15.x require special workaround for corner radius
        static let blurLayoutChangeVersion: Int = 15

        /// macOS version where Liquid Glass (.glassEffect) is available
        static let liquidGlassVersion: Int = 26
    }

    // MARK: - License Management
    enum License {
        /// Trial duration in days
        static let trialDurationDays: Int = 30

        /// How often to re-verify license online (in days)
        static let reverificationIntervalDays: Int = 7
    }

    // MARK: - Settings Defaults
    enum Defaults {
        /// Default hover delay in seconds
        static let hoverDelay: Double = 0.1

        /// Default window opacity (0.0 - 1.0)
        static let windowOpacity: Double = 0.98

        /// Default window maximum width in points
        static let windowMaxWidth: Double = 400

        /// Default font size in points
        static let fontSize: Double = 11

        /// Default window offset from cursor (horizontal)
        static let windowOffsetX: Double = 15

        /// Default window offset from cursor (vertical)
        static let windowOffsetY: Double = 15

        /// Default auto-hide behavior
        static let autoHideEnabled: Bool = true

        /// Default launch at login behavior
        static let launchAtLogin: Bool = false

        /// Default blur effect enabled
        static let enableBlur: Bool = true

        /// Default Liquid Glass effect enabled (macOS 26+ only)
        static let enableLiquidGlass: Bool = true

        /// Default compact mode
        static let compactMode: Bool = false

        /// Default large file protection mode
        static let enableLargeFileProtection: Bool = true

        /// Default show creation date
        static let showCreationDate: Bool = true

        /// Default show modification date
        static let showModificationDate: Bool = true

        /// Default show file size
        static let showFileSize: Bool = true

        /// Default show file type
        static let showFileType: Bool = true

        /// Default show file path
        static let showFilePath: Bool = true

        /// Default show icon
        static let showIcon: Bool = true

        /// Default show last access date
        static let showLastAccessDate: Bool = false

        /// Default show permissions
        static let showPermissions: Bool = false

        /// Default show owner
        static let showOwner: Bool = false

        /// Default show item count
        static let showItemCount: Bool = true

        /// Default show EXIF
        static let showEXIF: Bool = true

        /// Default show EXIF camera
        static let showEXIFCamera: Bool = true

        /// Default show EXIF lens
        static let showEXIFLens: Bool = true

        /// Default show EXIF settings
        static let showEXIFSettings: Bool = true

        /// Default show EXIF date taken
        static let showEXIFDateTaken: Bool = true

        /// Default show EXIF dimensions
        static let showEXIFDimensions: Bool = true

        /// Default show EXIF GPS
        static let showEXIFGPS: Bool = false

        /// Default show video
        static let showVideo: Bool = true

        /// Default show video duration
        static let showVideoDuration: Bool = true

        /// Default show video resolution
        static let showVideoResolution: Bool = true

        /// Default show video codec
        static let showVideoCodec: Bool = true

        /// Default show video frame rate
        static let showVideoFrameRate: Bool = true

        /// Default show video bitrate
        static let showVideoBitrate: Bool = true

        /// Default show video HDR
        static let showVideoHDR: Bool = true

        /// Default show audio
        static let showAudio: Bool = true

        /// Default show audio title
        static let showAudioTitle: Bool = true

        /// Default show audio artist
        static let showAudioArtist: Bool = true

        /// Default show audio album
        static let showAudioAlbum: Bool = true

        /// Default show audio genre
        static let showAudioGenre: Bool = true

        /// Default show audio year
        static let showAudioYear: Bool = true

        /// Default show audio duration
        static let showAudioDuration: Bool = true

        /// Default show audio bitrate
        static let showAudioBitrate: Bool = true

        /// Default show audio sample rate
        static let showAudioSampleRate: Bool = true

        /// Default show PDF metadata
        static let showPDF: Bool = true

        /// Default show PDF page count
        static let showPDFPageCount: Bool = true

        /// Default show PDF page size
        static let showPDFPageSize: Bool = true

        /// Default show PDF version
        static let showPDFVersion: Bool = true

        /// Default show PDF title
        static let showPDFTitle: Bool = true

        /// Default show PDF author
        static let showPDFAuthor: Bool = true

        /// Default show PDF subject
        static let showPDFSubject: Bool = true

        /// Default show PDF creator
        static let showPDFCreator: Bool = true

        /// Default show PDF producer
        static let showPDFProducer: Bool = true

        /// Default show PDF creation date
        static let showPDFCreationDate: Bool = true

        /// Default show PDF modification date
        static let showPDFModificationDate: Bool = true

        /// Default show PDF keywords
        static let showPDFKeywords: Bool = true

        /// Default show PDF encrypted status
        static let showPDFEncrypted: Bool = true

        /// Default show Office metadata
        static let showOffice: Bool = true

        /// Default show Office document title
        static let showOfficeTitle: Bool = true

        /// Default show Office document author
        static let showOfficeAuthor: Bool = true

        /// Default show Office document subject
        static let showOfficeSubject: Bool = true

        /// Default show Office document keywords
        static let showOfficeKeywords: Bool = true

        /// Default show Office document comment
        static let showOfficeComment: Bool = true

        /// Default show Office document last modified by
        static let showOfficeLastModifiedBy: Bool = false

        /// Default show Office document creation date
        static let showOfficeCreationDate: Bool = true

        /// Default show Office document modification date
        static let showOfficeModificationDate: Bool = true

        /// Default show Office document page count (Word)
        static let showOfficePageCount: Bool = true

        /// Default show Office document word count (Word)
        static let showOfficeWordCount: Bool = true

        /// Default show Office document sheet count (Excel)
        static let showOfficeSheetCount: Bool = true

        /// Default show Office document slide count (PowerPoint)
        static let showOfficeSlideCount: Bool = true

        /// Default show Office document company
        static let showOfficeCompany: Bool = false

        /// Default show Office document category
        static let showOfficeCategory: Bool = false

        /// Default show Archive metadata
        static let showArchive: Bool = true

        /// Default show Archive format
        static let showArchiveFormat: Bool = true

        /// Default show Archive file count
        static let showArchiveFileCount: Bool = true

        /// Default show Archive uncompressed size
        static let showArchiveUncompressedSize: Bool = true

        /// Default show Archive compression ratio
        static let showArchiveCompressionRatio: Bool = true

        /// Default show Archive encrypted status
        static let showArchiveEncrypted: Bool = true

        // MARK: - E-book Display Defaults
        /// Default show E-book section
        static let showEbook: Bool = true

        /// Default show E-book title
        static let showEbookTitle: Bool = true

        /// Default show E-book author
        static let showEbookAuthor: Bool = true

        /// Default show E-book publisher
        static let showEbookPublisher: Bool = true

        /// Default show E-book publication date
        static let showEbookPublicationDate: Bool = true

        /// Default show E-book ISBN
        static let showEbookISBN: Bool = true

        /// Default show E-book language
        static let showEbookLanguage: Bool = true

        /// Default show E-book description
        static let showEbookDescription: Bool = true

        /// Default show E-book page count
        static let showEbookPageCount: Bool = true

        // MARK: - Code File Display Defaults
        /// Default show Code section
        static let showCode: Bool = true

        /// Default show Code language
        static let showCodeLanguage: Bool = true

        /// Default show Code line count
        static let showCodeLineCount: Bool = true

        /// Default show Code lines
        static let showCodeLines: Bool = true

        /// Default show Code comment lines
        static let showCodeCommentLines: Bool = true

        /// Default show Code blank lines
        static let showCodeBlankLines: Bool = true

        /// Default show Code encoding
        static let showCodeEncoding: Bool = true
        
        // Font metadata defaults
        /// Default show Font information
        static let showFont: Bool = true
        
        /// Default show Font name
        static let showFontName: Bool = true
        
        /// Default show Font family
        static let showFontFamily: Bool = true
        
        /// Default show Font style
        static let showFontStyle: Bool = true
        
        /// Default show Font version
        static let showFontVersion: Bool = true
        
        /// Default show Font designer
        static let showFontDesigner: Bool = true
        
        /// Default show Font copyright
        static let showFontCopyright: Bool = true
        
        /// Default show Font glyph count
        static let showFontGlyphCount: Bool = true
        
        // Disk Image metadata defaults
        /// Default show Disk Image information
        static let showDiskImage: Bool = true
        
        /// Default show Disk Image format
        static let showDiskImageFormat: Bool = true
        
        /// Default show Disk Image total size
        static let showDiskImageTotalSize: Bool = true
        
        /// Default show Disk Image compressed size
        static let showDiskImageCompressedSize: Bool = true
        
        /// Default show Disk Image compression ratio
        static let showDiskImageCompressionRatio: Bool = true
        
        /// Default show Disk Image encrypted status
        static let showDiskImageEncrypted: Bool = true
        
        /// Default show Disk Image partition scheme
        static let showDiskImagePartitionScheme: Bool = true
        
        /// Default show Disk Image file system
        static let showDiskImageFileSystem: Bool = true
        
        /// Default show Vector Graphics info
        static let showVectorGraphics: Bool = true
        
        /// Default show Vector Graphics format
        static let showVectorGraphicsFormat: Bool = true
        
        /// Default show Vector Graphics dimensions
        static let showVectorGraphicsDimensions: Bool = true
        
        /// Default show Vector Graphics viewBox
        static let showVectorGraphicsViewBox: Bool = true
        
        /// Default show Vector Graphics element count
        static let showVectorGraphicsElementCount: Bool = true
        
        /// Default show Vector Graphics color mode
        static let showVectorGraphicsColorMode: Bool = true
        
        /// Default show Vector Graphics creator
        static let showVectorGraphicsCreator: Bool = true
        
        /// Default show Vector Graphics version
        static let showVectorGraphicsVersion: Bool = true
        
        /// Default show Subtitle info
        static let showSubtitle: Bool = true
        
        /// Default show Subtitle format
        static let showSubtitleFormat: Bool = true
        
        /// Default show Subtitle encoding
        static let showSubtitleEncoding: Bool = true
        
        /// Default show Subtitle entry count
        static let showSubtitleEntryCount: Bool = true
        
        /// Default show Subtitle duration
        static let showSubtitleDuration: Bool = true
        
        /// Default show Subtitle language
        static let showSubtitleLanguage: Bool = true
        
        /// Default show Subtitle frame rate
        static let showSubtitleFrameRate: Bool = true
        
        /// Default show Subtitle formatting
        static let showSubtitleFormatting: Bool = true

        // MARK: - HTML Metadata Defaults
        /// Default show HTML information
        static let showHTML: Bool = true

        /// Default show HTML title
        static let showHTMLTitle: Bool = true

        /// Default show HTML description
        static let showHTMLDescription: Bool = true

        /// Default show HTML charset
        static let showHTMLCharset: Bool = true

        /// Default show HTML Open Graph
        static let showHTMLOpenGraph: Bool = true

        /// Default show HTML Twitter Card
        static let showHTMLTwitterCard: Bool = true

        /// Default show HTML keywords
        static let showHTMLKeywords: Bool = true

        /// Default show HTML author
        static let showHTMLAuthor: Bool = true

        /// Default show HTML language
        static let showHTMLLanguage: Bool = true

        // MARK: - Extended Image Metadata Defaults (IPTC/XMP)
        /// Default show extended image information
        static let showImageExtended: Bool = true

        /// Default show image copyright
        static let showImageCopyright: Bool = true

        /// Default show image creator
        static let showImageCreator: Bool = true

        /// Default show image keywords
        static let showImageKeywords: Bool = true

        /// Default show image rating
        static let showImageRating: Bool = true

        /// Default show image creator tool
        static let showImageCreatorTool: Bool = true

        /// Default show image description
        static let showImageDescription: Bool = true

        /// Default show image headline
        static let showImageHeadline: Bool = true

        // MARK: - Markdown Metadata Defaults
        /// Default show Markdown information
        static let showMarkdown: Bool = true

        /// Default show Markdown frontmatter
        static let showMarkdownFrontmatter: Bool = true

        /// Default show Markdown title
        static let showMarkdownTitle: Bool = true

        /// Default show Markdown word count
        static let showMarkdownWordCount: Bool = true

        /// Default show Markdown heading count
        static let showMarkdownHeadingCount: Bool = true

        /// Default show Markdown link count
        static let showMarkdownLinkCount: Bool = true

        /// Default show Markdown image count
        static let showMarkdownImageCount: Bool = true

        /// Default show Markdown code block count
        static let showMarkdownCodeBlockCount: Bool = true

        // MARK: - Config File Metadata Defaults (JSON/YAML/TOML)
        /// Default show Config information
        static let showConfig: Bool = true

        /// Default show Config format
        static let showConfigFormat: Bool = true

        /// Default show Config valid status
        static let showConfigValid: Bool = true

        /// Default show Config key count
        static let showConfigKeyCount: Bool = true

        /// Default show Config max depth
        static let showConfigMaxDepth: Bool = true

        /// Default show Config has comments
        static let showConfigHasComments: Bool = true

        /// Default show Config encoding
        static let showConfigEncoding: Bool = true

        // MARK: - PSD Metadata Defaults
        /// Default show PSD information
        static let showPSD: Bool = true

        /// Default show PSD layer count
        static let showPSDLayerCount: Bool = true

        /// Default show PSD color mode
        static let showPSDColorMode: Bool = true

        /// Default show PSD bit depth
        static let showPSDBitDepth: Bool = true

        /// Default show PSD resolution
        static let showPSDResolution: Bool = true

        /// Default show PSD transparency
        static let showPSDTransparency: Bool = true

        /// Default show PSD dimensions
        static let showPSDDimensions: Bool = true

        // MARK: - Executable Metadata Defaults
        /// Default show Executable information
        static let showExecutable: Bool = true

        /// Default show Executable architecture
        static let showExecutableArchitecture: Bool = true

        /// Default show Executable code signed
        static let showExecutableCodeSigned: Bool = true

        /// Default show Executable signing authority
        static let showExecutableSigningAuthority: Bool = true

        /// Default show Executable minimum OS
        static let showExecutableMinimumOS: Bool = true

        /// Default show Executable SDK version
        static let showExecutableSDKVersion: Bool = true

        /// Default show Executable file type
        static let showExecutableFileType: Bool = true

        // MARK: - App Bundle Metadata Defaults
        /// Default show App Bundle information
        static let showAppBundle: Bool = true

        /// Default show App Bundle ID
        static let showAppBundleID: Bool = true

        /// Default show App Bundle version
        static let showAppBundleVersion: Bool = true

        /// Default show App Bundle build number
        static let showAppBundleBuildNumber: Bool = true

        /// Default show App Bundle minimum OS
        static let showAppBundleMinimumOS: Bool = true

        /// Default show App Bundle category
        static let showAppBundleCategory: Bool = true

        /// Default show App Bundle copyright
        static let showAppBundleCopyright: Bool = true

        /// Default show App Bundle code signed
        static let showAppBundleCodeSigned: Bool = true

        /// Default show App Bundle entitlements
        static let showAppBundleEntitlements: Bool = true

        // MARK: - SQLite Metadata Defaults
        /// Default show SQLite information
        static let showSQLite: Bool = true

        /// Default show SQLite table count
        static let showSQLiteTableCount: Bool = true

        /// Default show SQLite index count
        static let showSQLiteIndexCount: Bool = true

        /// Default show SQLite trigger count
        static let showSQLiteTriggerCount: Bool = true

        /// Default show SQLite view count
        static let showSQLiteViewCount: Bool = true

        /// Default show SQLite total rows
        static let showSQLiteTotalRows: Bool = true

        /// Default show SQLite schema version
        static let showSQLiteSchemaVersion: Bool = true

        /// Default show SQLite page size
        static let showSQLitePageSize: Bool = true

        /// Default show SQLite encoding
        static let showSQLiteEncoding: Bool = true

        // MARK: - Git Repository Metadata Defaults
        /// Default show Git information
        static let showGit: Bool = true

        /// Default show Git branch count
        static let showGitBranchCount: Bool = true

        /// Default show Git current branch
        static let showGitCurrentBranch: Bool = true

        /// Default show Git commit count
        static let showGitCommitCount: Bool = true

        /// Default show Git last commit date
        static let showGitLastCommitDate: Bool = true

        /// Default show Git last commit message
        static let showGitLastCommitMessage: Bool = true

        /// Default show Git remote URL
        static let showGitRemoteURL: Bool = true

        /// Default show Git uncommitted changes
        static let showGitUncommittedChanges: Bool = true

        /// Default show Git tag count
        static let showGitTagCount: Bool = true

        // MARK: - System Metadata Defaults
        /// Default show system metadata
        static let showSystemMetadata: Bool = true

        /// Default show Finder tags
        static let showFinderTags: Bool = true

        /// Default show where froms (download source)
        static let showWhereFroms: Bool = true

        /// Default show quarantine info
        static let showQuarantineInfo: Bool = true

        /// Default show link info
        static let showLinkInfo: Bool = true

        /// Default show usage stats
        static let showUsageStats: Bool = true

        /// Default show iCloud status
        static let showiCloudStatus: Bool = true

        /// Default show Finder comment
        static let showFinderComment: Bool = true

        /// Default show UTI
        static let showUTI: Bool = true

        /// Default show extended attributes
        static let showExtendedAttributes: Bool = false

        /// Default show alias target
        static let showAliasTarget: Bool = true

        /// Default follow cursor
        static let followCursor: Bool = true
    }

}
