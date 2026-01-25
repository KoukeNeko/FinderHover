//
//  AppSettings.swift
//  FinderHover
//
//  User preferences and settings
//

import Foundation
import SwiftUI
import Combine
import AppKit

// MARK: - UI Style Selection
enum UIStyle: String, Codable, CaseIterable, Identifiable {
    case macOS = "macOS"
    case windows = "Windows"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .macOS: return "settings.style.macos".localized
        case .windows: return "settings.style.windows".localized
        }
    }
}

// MARK: - Language Selection
enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case chinese = "zh-Hant"
    case japanese = "ja"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "settings.language.system".localized
        case .english: return "settings.language.english".localized
        case .chinese: return "settings.language.chinese".localized
        case .japanese: return "settings.language.japanese".localized
        }
    }
}

// MARK: - Display Item Types
enum DisplayItem: String, Codable, CaseIterable, Identifiable {
    case fileType = "File Type"
    case fileSize = "File Size"
    case itemCount = "Item Count"
    case creationDate = "Creation Date"
    case modificationDate = "Modification Date"
    case lastAccessDate = "Last Access Date"
    case permissions = "Permissions"
    case owner = "Owner"
    case exif = "Photo Information (EXIF)"
    case video = "Video Information"
    case audio = "Audio Information"
    case pdf = "PDF Information"
    case office = "Office Document Information"
    case archive = "Archive Information"
    case ebook = "E-book Information"
    case code = "Code File Information"
    case font = "Font Information"
    case diskImage = "Disk Image Information"
    case vectorGraphics = "Vector Graphics Information"
    case subtitle = "Subtitle Information"
    case html = "HTML Information"
    case imageExtended = "Extended Image Information"
    case markdown = "Markdown Information"
    case config = "Config File Information"
    case psd = "PSD Information"
    case executable = "Executable Information"
    case appBundle = "App Bundle Information"
    case sqlite = "SQLite Information"
    case git = "Git Repository Information"
    case filePath = "File Path"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .fileType: return "displayItem.fileType".localized
        case .fileSize: return "displayItem.fileSize".localized
        case .itemCount: return "displayItem.itemCount".localized
        case .creationDate: return "displayItem.creationDate".localized
        case .modificationDate: return "displayItem.modificationDate".localized
        case .lastAccessDate: return "displayItem.lastAccessDate".localized
        case .permissions: return "displayItem.permissions".localized
        case .owner: return "displayItem.owner".localized
        case .exif: return "displayItem.exif".localized
        case .video: return "displayItem.video".localized
        case .audio: return "displayItem.audio".localized
        case .pdf: return "displayItem.pdf".localized
        case .office: return "displayItem.office".localized
        case .archive: return "displayItem.archive".localized
        case .ebook: return "displayItem.ebook".localized
        case .code: return "displayItem.code".localized
        case .font: return "displayItem.font".localized
        case .diskImage: return "displayItem.diskImage".localized
        case .vectorGraphics: return "displayItem.vectorGraphics".localized
        case .subtitle: return "displayItem.subtitle".localized
        case .html: return "displayItem.html".localized
        case .imageExtended: return "displayItem.imageExtended".localized
        case .markdown: return "displayItem.markdown".localized
        case .config: return "displayItem.config".localized
        case .psd: return "displayItem.psd".localized
        case .executable: return "displayItem.executable".localized
        case .appBundle: return "displayItem.appBundle".localized
        case .sqlite: return "displayItem.sqlite".localized
        case .git: return "displayItem.git".localized
        case .filePath: return "displayItem.filePath".localized
        }
    }

    var icon: String {
        switch self {
        case .fileType: return IconManager.FileSystem.doc
        case .fileSize: return "archivebox"
        case .itemCount: return "number"
        case .creationDate: return IconManager.Display.calendar
        case .modificationDate: return IconManager.Display.clock
        case .lastAccessDate: return IconManager.Display.eye
        case .permissions: return "lock.shield"
        case .owner: return IconManager.Display.person
        case .exif: return IconManager.Photo.camera
        case .video: return IconManager.Video.video
        case .audio: return IconManager.Audio.music
        case .pdf: return "doc.richtext"
        case .office: return "doc.text.fill"
        case .archive: return "doc.zipper"
        case .ebook: return "book.closed"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .font: return "textformat"
        case .diskImage: return "opticaldiscdrive"
        case .vectorGraphics: return "paintbrush.pointed"
        case .subtitle: return "captions.bubble"
        case .html: return "globe"
        case .imageExtended: return "photo.badge.plus"
        case .markdown: return "text.document"
        case .config: return "gearshape.2"
        case .psd: return "square.3.layers.3d"
        case .executable: return "terminal"
        case .appBundle: return "app.badge"
        case .sqlite: return "cylinder"
        case .git: return "arrow.triangle.branch"
        case .filePath: return IconManager.FileSystem.folder
        }
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // Hover behavior
    @Published var hoverDelay: Double {
        didSet { UserDefaults.standard.set(hoverDelay, forKey: "hoverDelay") }
    }
    @Published var autoHideEnabled: Bool {
        didSet { UserDefaults.standard.set(autoHideEnabled, forKey: "autoHideEnabled") }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            LaunchAtLogin.setEnabled(launchAtLogin)
        }
    }

    // Appearance
    @Published var windowOpacity: Double {
        didSet { UserDefaults.standard.set(windowOpacity, forKey: "windowOpacity") }
    }
    @Published var windowMaxWidth: Double {
        didSet { UserDefaults.standard.set(windowMaxWidth, forKey: "windowMaxWidth") }
    }
    @Published var fontSize: Double {
        didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") }
    }
    @Published var enableBlur: Bool {
        didSet { UserDefaults.standard.set(enableBlur, forKey: "enableBlur") }
    }
    @Published var compactMode: Bool {
        didSet { UserDefaults.standard.set(compactMode, forKey: "compactMode") }
    }

    // Information display
    @Published var showCreationDate: Bool {
        didSet { UserDefaults.standard.set(showCreationDate, forKey: "showCreationDate") }
    }
    @Published var showModificationDate: Bool {
        didSet { UserDefaults.standard.set(showModificationDate, forKey: "showModificationDate") }
    }
    @Published var showFileSize: Bool {
        didSet { UserDefaults.standard.set(showFileSize, forKey: "showFileSize") }
    }
    @Published var showFileType: Bool {
        didSet { UserDefaults.standard.set(showFileType, forKey: "showFileType") }
    }
    @Published var showFilePath: Bool {
        didSet { UserDefaults.standard.set(showFilePath, forKey: "showFilePath") }
    }
    @Published var showIcon: Bool {
        didSet { UserDefaults.standard.set(showIcon, forKey: "showIcon") }
    }

    // Additional information display
    @Published var showLastAccessDate: Bool {
        didSet { UserDefaults.standard.set(showLastAccessDate, forKey: "showLastAccessDate") }
    }
    @Published var showPermissions: Bool {
        didSet { UserDefaults.standard.set(showPermissions, forKey: "showPermissions") }
    }
    @Published var showOwner: Bool {
        didSet { UserDefaults.standard.set(showOwner, forKey: "showOwner") }
    }
    @Published var showItemCount: Bool {
        didSet { UserDefaults.standard.set(showItemCount, forKey: "showItemCount") }
    }

    // EXIF information display
    @Published var showEXIF: Bool {
        didSet { UserDefaults.standard.set(showEXIF, forKey: "showEXIF") }
    }
    @Published var showEXIFCamera: Bool {
        didSet { UserDefaults.standard.set(showEXIFCamera, forKey: "showEXIFCamera") }
    }
    @Published var showEXIFLens: Bool {
        didSet { UserDefaults.standard.set(showEXIFLens, forKey: "showEXIFLens") }
    }
    @Published var showEXIFSettings: Bool {
        didSet { UserDefaults.standard.set(showEXIFSettings, forKey: "showEXIFSettings") }
    }
    @Published var showEXIFDateTaken: Bool {
        didSet { UserDefaults.standard.set(showEXIFDateTaken, forKey: "showEXIFDateTaken") }
    }
    @Published var showEXIFDimensions: Bool {
        didSet { UserDefaults.standard.set(showEXIFDimensions, forKey: "showEXIFDimensions") }
    }
    @Published var showEXIFGPS: Bool {
        didSet { UserDefaults.standard.set(showEXIFGPS, forKey: "showEXIFGPS") }
    }

    // Video information display
    @Published var showVideo: Bool {
        didSet { UserDefaults.standard.set(showVideo, forKey: "showVideo") }
    }
    @Published var showVideoDuration: Bool {
        didSet { UserDefaults.standard.set(showVideoDuration, forKey: "showVideoDuration") }
    }
    @Published var showVideoResolution: Bool {
        didSet { UserDefaults.standard.set(showVideoResolution, forKey: "showVideoResolution") }
    }
    @Published var showVideoCodec: Bool {
        didSet { UserDefaults.standard.set(showVideoCodec, forKey: "showVideoCodec") }
    }
    @Published var showVideoFrameRate: Bool {
        didSet { UserDefaults.standard.set(showVideoFrameRate, forKey: "showVideoFrameRate") }
    }
    @Published var showVideoBitrate: Bool {
        didSet { UserDefaults.standard.set(showVideoBitrate, forKey: "showVideoBitrate") }
    }

    // Audio information display
    @Published var showAudio: Bool {
        didSet { UserDefaults.standard.set(showAudio, forKey: "showAudio") }
    }
    @Published var showAudioTitle: Bool {
        didSet { UserDefaults.standard.set(showAudioTitle, forKey: "showAudioTitle") }
    }
    @Published var showAudioArtist: Bool {
        didSet { UserDefaults.standard.set(showAudioArtist, forKey: "showAudioArtist") }
    }
    @Published var showAudioAlbum: Bool {
        didSet { UserDefaults.standard.set(showAudioAlbum, forKey: "showAudioAlbum") }
    }
    @Published var showAudioGenre: Bool {
        didSet { UserDefaults.standard.set(showAudioGenre, forKey: "showAudioGenre") }
    }
    @Published var showAudioYear: Bool {
        didSet { UserDefaults.standard.set(showAudioYear, forKey: "showAudioYear") }
    }
    @Published var showAudioDuration: Bool {
        didSet { UserDefaults.standard.set(showAudioDuration, forKey: "showAudioDuration") }
    }
    @Published var showAudioBitrate: Bool {
        didSet { UserDefaults.standard.set(showAudioBitrate, forKey: "showAudioBitrate") }
    }
    @Published var showAudioSampleRate: Bool {
        didSet { UserDefaults.standard.set(showAudioSampleRate, forKey: "showAudioSampleRate") }
    }

    // PDF metadata display settings
    @Published var showPDF: Bool {
        didSet { UserDefaults.standard.set(showPDF, forKey: "showPDF") }
    }
    @Published var showPDFPageCount: Bool {
        didSet { UserDefaults.standard.set(showPDFPageCount, forKey: "showPDFPageCount") }
    }
    @Published var showPDFPageSize: Bool {
        didSet { UserDefaults.standard.set(showPDFPageSize, forKey: "showPDFPageSize") }
    }
    @Published var showPDFVersion: Bool {
        didSet { UserDefaults.standard.set(showPDFVersion, forKey: "showPDFVersion") }
    }
    @Published var showPDFTitle: Bool {
        didSet { UserDefaults.standard.set(showPDFTitle, forKey: "showPDFTitle") }
    }
    @Published var showPDFAuthor: Bool {
        didSet { UserDefaults.standard.set(showPDFAuthor, forKey: "showPDFAuthor") }
    }
    @Published var showPDFSubject: Bool {
        didSet { UserDefaults.standard.set(showPDFSubject, forKey: "showPDFSubject") }
    }
    @Published var showPDFCreator: Bool {
        didSet { UserDefaults.standard.set(showPDFCreator, forKey: "showPDFCreator") }
    }
    @Published var showPDFProducer: Bool {
        didSet { UserDefaults.standard.set(showPDFProducer, forKey: "showPDFProducer") }
    }
    @Published var showPDFCreationDate: Bool {
        didSet { UserDefaults.standard.set(showPDFCreationDate, forKey: "showPDFCreationDate") }
    }
    @Published var showPDFModificationDate: Bool {
        didSet { UserDefaults.standard.set(showPDFModificationDate, forKey: "showPDFModificationDate") }
    }
    @Published var showPDFKeywords: Bool {
        didSet { UserDefaults.standard.set(showPDFKeywords, forKey: "showPDFKeywords") }
    }
    @Published var showPDFEncrypted: Bool {
        didSet { UserDefaults.standard.set(showPDFEncrypted, forKey: "showPDFEncrypted") }
    }

    // Office document display settings
    @Published var showOffice: Bool {
        didSet { UserDefaults.standard.set(showOffice, forKey: "showOffice") }
    }
    @Published var showOfficeTitle: Bool {
        didSet { UserDefaults.standard.set(showOfficeTitle, forKey: "showOfficeTitle") }
    }
    @Published var showOfficeAuthor: Bool {
        didSet { UserDefaults.standard.set(showOfficeAuthor, forKey: "showOfficeAuthor") }
    }
    @Published var showOfficeSubject: Bool {
        didSet { UserDefaults.standard.set(showOfficeSubject, forKey: "showOfficeSubject") }
    }
    @Published var showOfficeKeywords: Bool {
        didSet { UserDefaults.standard.set(showOfficeKeywords, forKey: "showOfficeKeywords") }
    }
    @Published var showOfficeComment: Bool {
        didSet { UserDefaults.standard.set(showOfficeComment, forKey: "showOfficeComment") }
    }
    @Published var showOfficeLastModifiedBy: Bool {
        didSet { UserDefaults.standard.set(showOfficeLastModifiedBy, forKey: "showOfficeLastModifiedBy") }
    }
    @Published var showOfficeCreationDate: Bool {
        didSet { UserDefaults.standard.set(showOfficeCreationDate, forKey: "showOfficeCreationDate") }
    }
    @Published var showOfficeModificationDate: Bool {
        didSet { UserDefaults.standard.set(showOfficeModificationDate, forKey: "showOfficeModificationDate") }
    }
    @Published var showOfficePageCount: Bool {
        didSet { UserDefaults.standard.set(showOfficePageCount, forKey: "showOfficePageCount") }
    }
    @Published var showOfficeWordCount: Bool {
        didSet { UserDefaults.standard.set(showOfficeWordCount, forKey: "showOfficeWordCount") }
    }
    @Published var showOfficeSheetCount: Bool {
        didSet { UserDefaults.standard.set(showOfficeSheetCount, forKey: "showOfficeSheetCount") }
    }
    @Published var showOfficeSlideCount: Bool {
        didSet { UserDefaults.standard.set(showOfficeSlideCount, forKey: "showOfficeSlideCount") }
    }
    @Published var showOfficeCompany: Bool {
        didSet { UserDefaults.standard.set(showOfficeCompany, forKey: "showOfficeCompany") }
    }
    @Published var showOfficeCategory: Bool {
        didSet { UserDefaults.standard.set(showOfficeCategory, forKey: "showOfficeCategory") }
    }

    // Archive display settings
    @Published var showArchive: Bool {
        didSet { UserDefaults.standard.set(showArchive, forKey: "showArchive") }
    }
    @Published var showArchiveFormat: Bool {
        didSet { UserDefaults.standard.set(showArchiveFormat, forKey: "showArchiveFormat") }
    }
    @Published var showArchiveFileCount: Bool {
        didSet { UserDefaults.standard.set(showArchiveFileCount, forKey: "showArchiveFileCount") }
    }
    @Published var showArchiveUncompressedSize: Bool {
        didSet { UserDefaults.standard.set(showArchiveUncompressedSize, forKey: "showArchiveUncompressedSize") }
    }
    @Published var showArchiveCompressionRatio: Bool {
        didSet { UserDefaults.standard.set(showArchiveCompressionRatio, forKey: "showArchiveCompressionRatio") }
    }
    @Published var showArchiveEncrypted: Bool {
        didSet { UserDefaults.standard.set(showArchiveEncrypted, forKey: "showArchiveEncrypted") }
    }

    // MARK: - E-book Display Settings
    @Published var showEbook: Bool {
        didSet { UserDefaults.standard.set(showEbook, forKey: "showEbook") }
    }
    @Published var showEbookTitle: Bool {
        didSet { UserDefaults.standard.set(showEbookTitle, forKey: "showEbookTitle") }
    }
    @Published var showEbookAuthor: Bool {
        didSet { UserDefaults.standard.set(showEbookAuthor, forKey: "showEbookAuthor") }
    }
    @Published var showEbookPublisher: Bool {
        didSet { UserDefaults.standard.set(showEbookPublisher, forKey: "showEbookPublisher") }
    }
    @Published var showEbookPublicationDate: Bool {
        didSet { UserDefaults.standard.set(showEbookPublicationDate, forKey: "showEbookPublicationDate") }
    }
    @Published var showEbookISBN: Bool {
        didSet { UserDefaults.standard.set(showEbookISBN, forKey: "showEbookISBN") }
    }
    @Published var showEbookLanguage: Bool {
        didSet { UserDefaults.standard.set(showEbookLanguage, forKey: "showEbookLanguage") }
    }
    @Published var showEbookDescription: Bool {
        didSet { UserDefaults.standard.set(showEbookDescription, forKey: "showEbookDescription") }
    }
    @Published var showEbookPageCount: Bool {
        didSet { UserDefaults.standard.set(showEbookPageCount, forKey: "showEbookPageCount") }
    }

    // MARK: - Code File Display Settings
    @Published var showCode: Bool {
        didSet { UserDefaults.standard.set(showCode, forKey: "showCode") }
    }
    @Published var showCodeLanguage: Bool {
        didSet { UserDefaults.standard.set(showCodeLanguage, forKey: "showCodeLanguage") }
    }
    @Published var showCodeLineCount: Bool {
        didSet { UserDefaults.standard.set(showCodeLineCount, forKey: "showCodeLineCount") }
    }
    @Published var showCodeLines: Bool {
        didSet { UserDefaults.standard.set(showCodeLines, forKey: "showCodeLines") }
    }
    @Published var showCodeCommentLines: Bool {
        didSet { UserDefaults.standard.set(showCodeCommentLines, forKey: "showCodeCommentLines") }
    }
    @Published var showCodeBlankLines: Bool {
        didSet { UserDefaults.standard.set(showCodeBlankLines, forKey: "showCodeBlankLines") }
    }
    @Published var showCodeEncoding: Bool {
        didSet { UserDefaults.standard.set(showCodeEncoding, forKey: "showCodeEncoding") }
    }
    
    // Font metadata toggles
    @Published var showFont: Bool {
        didSet { UserDefaults.standard.set(showFont, forKey: "showFont") }
    }
    @Published var showFontName: Bool {
        didSet { UserDefaults.standard.set(showFontName, forKey: "showFontName") }
    }
    @Published var showFontFamily: Bool {
        didSet { UserDefaults.standard.set(showFontFamily, forKey: "showFontFamily") }
    }
    @Published var showFontStyle: Bool {
        didSet { UserDefaults.standard.set(showFontStyle, forKey: "showFontStyle") }
    }
    @Published var showFontVersion: Bool {
        didSet { UserDefaults.standard.set(showFontVersion, forKey: "showFontVersion") }
    }
    @Published var showFontDesigner: Bool {
        didSet { UserDefaults.standard.set(showFontDesigner, forKey: "showFontDesigner") }
    }
    @Published var showFontCopyright: Bool {
        didSet { UserDefaults.standard.set(showFontCopyright, forKey: "showFontCopyright") }
    }
    @Published var showFontGlyphCount: Bool {
        didSet { UserDefaults.standard.set(showFontGlyphCount, forKey: "showFontGlyphCount") }
    }
    
    // Disk Image metadata toggles
    @Published var showDiskImage: Bool {
        didSet { UserDefaults.standard.set(showDiskImage, forKey: "showDiskImage") }
    }
    @Published var showDiskImageFormat: Bool {
        didSet { UserDefaults.standard.set(showDiskImageFormat, forKey: "showDiskImageFormat") }
    }
    @Published var showDiskImageTotalSize: Bool {
        didSet { UserDefaults.standard.set(showDiskImageTotalSize, forKey: "showDiskImageTotalSize") }
    }
    @Published var showDiskImageCompressedSize: Bool {
        didSet { UserDefaults.standard.set(showDiskImageCompressedSize, forKey: "showDiskImageCompressedSize") }
    }
    @Published var showDiskImageCompressionRatio: Bool {
        didSet { UserDefaults.standard.set(showDiskImageCompressionRatio, forKey: "showDiskImageCompressionRatio") }
    }
    @Published var showDiskImageEncrypted: Bool {
        didSet { UserDefaults.standard.set(showDiskImageEncrypted, forKey: "showDiskImageEncrypted") }
    }
    @Published var showDiskImagePartitionScheme: Bool {
        didSet { UserDefaults.standard.set(showDiskImagePartitionScheme, forKey: "showDiskImagePartitionScheme") }
    }
    @Published var showDiskImageFileSystem: Bool {
        didSet { UserDefaults.standard.set(showDiskImageFileSystem, forKey: "showDiskImageFileSystem") }
    }
    
    // Vector Graphics metadata
    @Published var showVectorGraphics: Bool {
        didSet { UserDefaults.standard.set(showVectorGraphics, forKey: "showVectorGraphics") }
    }
    @Published var showVectorGraphicsFormat: Bool {
        didSet { UserDefaults.standard.set(showVectorGraphicsFormat, forKey: "showVectorGraphicsFormat") }
    }
    @Published var showVectorGraphicsDimensions: Bool {
        didSet { UserDefaults.standard.set(showVectorGraphicsDimensions, forKey: "showVectorGraphicsDimensions") }
    }
    @Published var showVectorGraphicsViewBox: Bool {
        didSet { UserDefaults.standard.set(showVectorGraphicsViewBox, forKey: "showVectorGraphicsViewBox") }
    }
    @Published var showVectorGraphicsElementCount: Bool {
        didSet { UserDefaults.standard.set(showVectorGraphicsElementCount, forKey: "showVectorGraphicsElementCount") }
    }
    @Published var showVectorGraphicsColorMode: Bool {
        didSet { UserDefaults.standard.set(showVectorGraphicsColorMode, forKey: "showVectorGraphicsColorMode") }
    }
    @Published var showVectorGraphicsCreator: Bool {
        didSet { UserDefaults.standard.set(showVectorGraphicsCreator, forKey: "showVectorGraphicsCreator") }
    }
    @Published var showVectorGraphicsVersion: Bool {
        didSet { UserDefaults.standard.set(showVectorGraphicsVersion, forKey: "showVectorGraphicsVersion") }
    }
    
    // Subtitle metadata
    @Published var showSubtitle: Bool {
        didSet { UserDefaults.standard.set(showSubtitle, forKey: "showSubtitle") }
    }
    @Published var showSubtitleFormat: Bool {
        didSet { UserDefaults.standard.set(showSubtitleFormat, forKey: "showSubtitleFormat") }
    }
    @Published var showSubtitleEncoding: Bool {
        didSet { UserDefaults.standard.set(showSubtitleEncoding, forKey: "showSubtitleEncoding") }
    }
    @Published var showSubtitleEntryCount: Bool {
        didSet { UserDefaults.standard.set(showSubtitleEntryCount, forKey: "showSubtitleEntryCount") }
    }
    @Published var showSubtitleDuration: Bool {
        didSet { UserDefaults.standard.set(showSubtitleDuration, forKey: "showSubtitleDuration") }
    }
    @Published var showSubtitleLanguage: Bool {
        didSet { UserDefaults.standard.set(showSubtitleLanguage, forKey: "showSubtitleLanguage") }
    }
    @Published var showSubtitleFrameRate: Bool {
        didSet { UserDefaults.standard.set(showSubtitleFrameRate, forKey: "showSubtitleFrameRate") }
    }
    @Published var showSubtitleFormatting: Bool {
        didSet { UserDefaults.standard.set(showSubtitleFormatting, forKey: "showSubtitleFormatting") }
    }

    // MARK: - HTML Metadata
    @Published var showHTML: Bool {
        didSet { UserDefaults.standard.set(showHTML, forKey: "showHTML") }
    }
    @Published var showHTMLTitle: Bool {
        didSet { UserDefaults.standard.set(showHTMLTitle, forKey: "showHTMLTitle") }
    }
    @Published var showHTMLDescription: Bool {
        didSet { UserDefaults.standard.set(showHTMLDescription, forKey: "showHTMLDescription") }
    }
    @Published var showHTMLCharset: Bool {
        didSet { UserDefaults.standard.set(showHTMLCharset, forKey: "showHTMLCharset") }
    }
    @Published var showHTMLOpenGraph: Bool {
        didSet { UserDefaults.standard.set(showHTMLOpenGraph, forKey: "showHTMLOpenGraph") }
    }
    @Published var showHTMLTwitterCard: Bool {
        didSet { UserDefaults.standard.set(showHTMLTwitterCard, forKey: "showHTMLTwitterCard") }
    }
    @Published var showHTMLKeywords: Bool {
        didSet { UserDefaults.standard.set(showHTMLKeywords, forKey: "showHTMLKeywords") }
    }
    @Published var showHTMLAuthor: Bool {
        didSet { UserDefaults.standard.set(showHTMLAuthor, forKey: "showHTMLAuthor") }
    }
    @Published var showHTMLLanguage: Bool {
        didSet { UserDefaults.standard.set(showHTMLLanguage, forKey: "showHTMLLanguage") }
    }

    // MARK: - Extended Image Metadata (IPTC/XMP)
    @Published var showImageExtended: Bool {
        didSet { UserDefaults.standard.set(showImageExtended, forKey: "showImageExtended") }
    }
    @Published var showImageCopyright: Bool {
        didSet { UserDefaults.standard.set(showImageCopyright, forKey: "showImageCopyright") }
    }
    @Published var showImageCreator: Bool {
        didSet { UserDefaults.standard.set(showImageCreator, forKey: "showImageCreator") }
    }
    @Published var showImageKeywords: Bool {
        didSet { UserDefaults.standard.set(showImageKeywords, forKey: "showImageKeywords") }
    }
    @Published var showImageRating: Bool {
        didSet { UserDefaults.standard.set(showImageRating, forKey: "showImageRating") }
    }
    @Published var showImageCreatorTool: Bool {
        didSet { UserDefaults.standard.set(showImageCreatorTool, forKey: "showImageCreatorTool") }
    }
    @Published var showImageDescription: Bool {
        didSet { UserDefaults.standard.set(showImageDescription, forKey: "showImageDescription") }
    }
    @Published var showImageHeadline: Bool {
        didSet { UserDefaults.standard.set(showImageHeadline, forKey: "showImageHeadline") }
    }

    // MARK: - Markdown Metadata
    @Published var showMarkdown: Bool {
        didSet { UserDefaults.standard.set(showMarkdown, forKey: "showMarkdown") }
    }
    @Published var showMarkdownFrontmatter: Bool {
        didSet { UserDefaults.standard.set(showMarkdownFrontmatter, forKey: "showMarkdownFrontmatter") }
    }
    @Published var showMarkdownTitle: Bool {
        didSet { UserDefaults.standard.set(showMarkdownTitle, forKey: "showMarkdownTitle") }
    }
    @Published var showMarkdownWordCount: Bool {
        didSet { UserDefaults.standard.set(showMarkdownWordCount, forKey: "showMarkdownWordCount") }
    }
    @Published var showMarkdownHeadingCount: Bool {
        didSet { UserDefaults.standard.set(showMarkdownHeadingCount, forKey: "showMarkdownHeadingCount") }
    }
    @Published var showMarkdownLinkCount: Bool {
        didSet { UserDefaults.standard.set(showMarkdownLinkCount, forKey: "showMarkdownLinkCount") }
    }
    @Published var showMarkdownImageCount: Bool {
        didSet { UserDefaults.standard.set(showMarkdownImageCount, forKey: "showMarkdownImageCount") }
    }
    @Published var showMarkdownCodeBlockCount: Bool {
        didSet { UserDefaults.standard.set(showMarkdownCodeBlockCount, forKey: "showMarkdownCodeBlockCount") }
    }

    // MARK: - Config File Metadata (JSON/YAML/TOML)
    @Published var showConfig: Bool {
        didSet { UserDefaults.standard.set(showConfig, forKey: "showConfig") }
    }
    @Published var showConfigFormat: Bool {
        didSet { UserDefaults.standard.set(showConfigFormat, forKey: "showConfigFormat") }
    }
    @Published var showConfigValid: Bool {
        didSet { UserDefaults.standard.set(showConfigValid, forKey: "showConfigValid") }
    }
    @Published var showConfigKeyCount: Bool {
        didSet { UserDefaults.standard.set(showConfigKeyCount, forKey: "showConfigKeyCount") }
    }
    @Published var showConfigMaxDepth: Bool {
        didSet { UserDefaults.standard.set(showConfigMaxDepth, forKey: "showConfigMaxDepth") }
    }
    @Published var showConfigHasComments: Bool {
        didSet { UserDefaults.standard.set(showConfigHasComments, forKey: "showConfigHasComments") }
    }
    @Published var showConfigEncoding: Bool {
        didSet { UserDefaults.standard.set(showConfigEncoding, forKey: "showConfigEncoding") }
    }

    // MARK: - PSD Metadata
    @Published var showPSD: Bool {
        didSet { UserDefaults.standard.set(showPSD, forKey: "showPSD") }
    }
    @Published var showPSDLayerCount: Bool {
        didSet { UserDefaults.standard.set(showPSDLayerCount, forKey: "showPSDLayerCount") }
    }
    @Published var showPSDColorMode: Bool {
        didSet { UserDefaults.standard.set(showPSDColorMode, forKey: "showPSDColorMode") }
    }
    @Published var showPSDBitDepth: Bool {
        didSet { UserDefaults.standard.set(showPSDBitDepth, forKey: "showPSDBitDepth") }
    }
    @Published var showPSDResolution: Bool {
        didSet { UserDefaults.standard.set(showPSDResolution, forKey: "showPSDResolution") }
    }
    @Published var showPSDTransparency: Bool {
        didSet { UserDefaults.standard.set(showPSDTransparency, forKey: "showPSDTransparency") }
    }
    @Published var showPSDDimensions: Bool {
        didSet { UserDefaults.standard.set(showPSDDimensions, forKey: "showPSDDimensions") }
    }

    // MARK: - Executable Metadata
    @Published var showExecutable: Bool {
        didSet { UserDefaults.standard.set(showExecutable, forKey: "showExecutable") }
    }
    @Published var showExecutableArchitecture: Bool {
        didSet { UserDefaults.standard.set(showExecutableArchitecture, forKey: "showExecutableArchitecture") }
    }
    @Published var showExecutableCodeSigned: Bool {
        didSet { UserDefaults.standard.set(showExecutableCodeSigned, forKey: "showExecutableCodeSigned") }
    }
    @Published var showExecutableSigningAuthority: Bool {
        didSet { UserDefaults.standard.set(showExecutableSigningAuthority, forKey: "showExecutableSigningAuthority") }
    }
    @Published var showExecutableMinimumOS: Bool {
        didSet { UserDefaults.standard.set(showExecutableMinimumOS, forKey: "showExecutableMinimumOS") }
    }
    @Published var showExecutableSDKVersion: Bool {
        didSet { UserDefaults.standard.set(showExecutableSDKVersion, forKey: "showExecutableSDKVersion") }
    }
    @Published var showExecutableFileType: Bool {
        didSet { UserDefaults.standard.set(showExecutableFileType, forKey: "showExecutableFileType") }
    }

    // MARK: - App Bundle Metadata
    @Published var showAppBundle: Bool {
        didSet { UserDefaults.standard.set(showAppBundle, forKey: "showAppBundle") }
    }
    @Published var showAppBundleID: Bool {
        didSet { UserDefaults.standard.set(showAppBundleID, forKey: "showAppBundleID") }
    }
    @Published var showAppBundleVersion: Bool {
        didSet { UserDefaults.standard.set(showAppBundleVersion, forKey: "showAppBundleVersion") }
    }
    @Published var showAppBundleBuildNumber: Bool {
        didSet { UserDefaults.standard.set(showAppBundleBuildNumber, forKey: "showAppBundleBuildNumber") }
    }
    @Published var showAppBundleMinimumOS: Bool {
        didSet { UserDefaults.standard.set(showAppBundleMinimumOS, forKey: "showAppBundleMinimumOS") }
    }
    @Published var showAppBundleCategory: Bool {
        didSet { UserDefaults.standard.set(showAppBundleCategory, forKey: "showAppBundleCategory") }
    }
    @Published var showAppBundleCopyright: Bool {
        didSet { UserDefaults.standard.set(showAppBundleCopyright, forKey: "showAppBundleCopyright") }
    }
    @Published var showAppBundleCodeSigned: Bool {
        didSet { UserDefaults.standard.set(showAppBundleCodeSigned, forKey: "showAppBundleCodeSigned") }
    }
    @Published var showAppBundleEntitlements: Bool {
        didSet { UserDefaults.standard.set(showAppBundleEntitlements, forKey: "showAppBundleEntitlements") }
    }

    // MARK: - SQLite Metadata
    @Published var showSQLite: Bool {
        didSet { UserDefaults.standard.set(showSQLite, forKey: "showSQLite") }
    }
    @Published var showSQLiteTableCount: Bool {
        didSet { UserDefaults.standard.set(showSQLiteTableCount, forKey: "showSQLiteTableCount") }
    }
    @Published var showSQLiteIndexCount: Bool {
        didSet { UserDefaults.standard.set(showSQLiteIndexCount, forKey: "showSQLiteIndexCount") }
    }
    @Published var showSQLiteTriggerCount: Bool {
        didSet { UserDefaults.standard.set(showSQLiteTriggerCount, forKey: "showSQLiteTriggerCount") }
    }
    @Published var showSQLiteViewCount: Bool {
        didSet { UserDefaults.standard.set(showSQLiteViewCount, forKey: "showSQLiteViewCount") }
    }
    @Published var showSQLiteTotalRows: Bool {
        didSet { UserDefaults.standard.set(showSQLiteTotalRows, forKey: "showSQLiteTotalRows") }
    }
    @Published var showSQLiteSchemaVersion: Bool {
        didSet { UserDefaults.standard.set(showSQLiteSchemaVersion, forKey: "showSQLiteSchemaVersion") }
    }
    @Published var showSQLitePageSize: Bool {
        didSet { UserDefaults.standard.set(showSQLitePageSize, forKey: "showSQLitePageSize") }
    }
    @Published var showSQLiteEncoding: Bool {
        didSet { UserDefaults.standard.set(showSQLiteEncoding, forKey: "showSQLiteEncoding") }
    }

    // MARK: - Git Repository Metadata
    @Published var showGit: Bool {
        didSet { UserDefaults.standard.set(showGit, forKey: "showGit") }
    }
    @Published var showGitBranchCount: Bool {
        didSet { UserDefaults.standard.set(showGitBranchCount, forKey: "showGitBranchCount") }
    }
    @Published var showGitCurrentBranch: Bool {
        didSet { UserDefaults.standard.set(showGitCurrentBranch, forKey: "showGitCurrentBranch") }
    }
    @Published var showGitCommitCount: Bool {
        didSet { UserDefaults.standard.set(showGitCommitCount, forKey: "showGitCommitCount") }
    }
    @Published var showGitLastCommitDate: Bool {
        didSet { UserDefaults.standard.set(showGitLastCommitDate, forKey: "showGitLastCommitDate") }
    }
    @Published var showGitLastCommitMessage: Bool {
        didSet { UserDefaults.standard.set(showGitLastCommitMessage, forKey: "showGitLastCommitMessage") }
    }
    @Published var showGitRemoteURL: Bool {
        didSet { UserDefaults.standard.set(showGitRemoteURL, forKey: "showGitRemoteURL") }
    }
    @Published var showGitUncommittedChanges: Bool {
        didSet { UserDefaults.standard.set(showGitUncommittedChanges, forKey: "showGitUncommittedChanges") }
    }
    @Published var showGitTagCount: Bool {
        didSet { UserDefaults.standard.set(showGitTagCount, forKey: "showGitTagCount") }
    }

    // Display order
    @Published var displayOrder: [DisplayItem] {
        didSet {
            if let encoded = try? JSONEncoder().encode(displayOrder) {
                UserDefaults.standard.set(encoded, forKey: "displayOrder")
            }
        }
    }

    // Window behavior
    @Published var followCursor: Bool {
        didSet { UserDefaults.standard.set(followCursor, forKey: "followCursor") }
    }
    @Published var windowOffsetX: Double {
        didSet { UserDefaults.standard.set(windowOffsetX, forKey: "windowOffsetX") }
    }
    @Published var windowOffsetY: Double {
        didSet { UserDefaults.standard.set(windowOffsetY, forKey: "windowOffsetY") }
    }

    // UI Style preference
    @Published var uiStyle: UIStyle {
        didSet {
            UserDefaults.standard.set(uiStyle.rawValue, forKey: "uiStyle")
        }
    }

    // Language preference
    @Published var preferredLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(preferredLanguage.rawValue, forKey: "preferredLanguage")
            applyLanguagePreference()
        }
    }

    // Update preferences
    @Published var includePrereleases: Bool {
        didSet { UserDefaults.standard.set(includePrereleases, forKey: "includePrereleases") }
    }

    private init() {
        // Load display order or use default
        if let data = UserDefaults.standard.data(forKey: "displayOrder"),
           var decoded = try? JSONDecoder().decode([DisplayItem].self, from: data) {
            // Migration: Add new items if they don't exist
            if !decoded.contains(.video) {
                if let exifIndex = decoded.firstIndex(of: .exif) {
                    decoded.insert(.video, at: exifIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.video, at: filePathIndex)
                } else {
                    decoded.append(.video)
                }
            }
            if !decoded.contains(.audio) {
                if let videoIndex = decoded.firstIndex(of: .video) {
                    decoded.insert(.audio, at: videoIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.audio, at: filePathIndex)
                } else {
                    decoded.append(.audio)
                }
            }
            if !decoded.contains(.pdf) {
                if let audioIndex = decoded.firstIndex(of: .audio) {
                    decoded.insert(.pdf, at: audioIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.pdf, at: filePathIndex)
                } else {
                    decoded.append(.pdf)
                }
            }
            if !decoded.contains(.office) {
                if let pdfIndex = decoded.firstIndex(of: .pdf) {
                    decoded.insert(.office, at: pdfIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.office, at: filePathIndex)
                } else {
                    decoded.append(.office)
                }
            }
            if !decoded.contains(.archive) {
                if let officeIndex = decoded.firstIndex(of: .office) {
                    decoded.insert(.archive, at: officeIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.archive, at: filePathIndex)
                } else {
                    decoded.append(.archive)
                }
            }
            if !decoded.contains(.ebook) {
                if let archiveIndex = decoded.firstIndex(of: .archive) {
                    decoded.insert(.ebook, at: archiveIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.ebook, at: filePathIndex)
                } else {
                    decoded.append(.ebook)
                }
            }
            if !decoded.contains(.code) {
                if let ebookIndex = decoded.firstIndex(of: .ebook) {
                    decoded.insert(.code, at: ebookIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.code, at: filePathIndex)
                } else {
                    decoded.append(.code)
                }
            }
            if !decoded.contains(.font) {
                if let codeIndex = decoded.firstIndex(of: .code) {
                    decoded.insert(.font, at: codeIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.font, at: filePathIndex)
                } else {
                    decoded.append(.font)
                }
            }
            if !decoded.contains(.diskImage) {
                if let fontIndex = decoded.firstIndex(of: .font) {
                    decoded.insert(.diskImage, at: fontIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.diskImage, at: filePathIndex)
                } else {
                    decoded.append(.diskImage)
                }
            }
            if !decoded.contains(.vectorGraphics) {
                if let diskImageIndex = decoded.firstIndex(of: .diskImage) {
                    decoded.insert(.vectorGraphics, at: diskImageIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.vectorGraphics, at: filePathIndex)
                } else {
                    decoded.append(.vectorGraphics)
                }
            }
            if !decoded.contains(.subtitle) {
                if let vectorGraphicsIndex = decoded.firstIndex(of: .vectorGraphics) {
                    decoded.insert(.subtitle, at: vectorGraphicsIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.subtitle, at: filePathIndex)
                } else {
                    decoded.append(.subtitle)
                }
            }
            // Migration for new metadata types
            if !decoded.contains(.html) {
                if let subtitleIndex = decoded.firstIndex(of: .subtitle) {
                    decoded.insert(.html, at: subtitleIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.html, at: filePathIndex)
                } else {
                    decoded.append(.html)
                }
            }
            if !decoded.contains(.imageExtended) {
                if let htmlIndex = decoded.firstIndex(of: .html) {
                    decoded.insert(.imageExtended, at: htmlIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.imageExtended, at: filePathIndex)
                } else {
                    decoded.append(.imageExtended)
                }
            }
            if !decoded.contains(.markdown) {
                if let imageExtendedIndex = decoded.firstIndex(of: .imageExtended) {
                    decoded.insert(.markdown, at: imageExtendedIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.markdown, at: filePathIndex)
                } else {
                    decoded.append(.markdown)
                }
            }
            if !decoded.contains(.config) {
                if let markdownIndex = decoded.firstIndex(of: .markdown) {
                    decoded.insert(.config, at: markdownIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.config, at: filePathIndex)
                } else {
                    decoded.append(.config)
                }
            }
            if !decoded.contains(.psd) {
                if let configIndex = decoded.firstIndex(of: .config) {
                    decoded.insert(.psd, at: configIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.psd, at: filePathIndex)
                } else {
                    decoded.append(.psd)
                }
            }
            if !decoded.contains(.executable) {
                if let psdIndex = decoded.firstIndex(of: .psd) {
                    decoded.insert(.executable, at: psdIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.executable, at: filePathIndex)
                } else {
                    decoded.append(.executable)
                }
            }
            if !decoded.contains(.appBundle) {
                if let executableIndex = decoded.firstIndex(of: .executable) {
                    decoded.insert(.appBundle, at: executableIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.appBundle, at: filePathIndex)
                } else {
                    decoded.append(.appBundle)
                }
            }
            if !decoded.contains(.sqlite) {
                if let appBundleIndex = decoded.firstIndex(of: .appBundle) {
                    decoded.insert(.sqlite, at: appBundleIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.sqlite, at: filePathIndex)
                } else {
                    decoded.append(.sqlite)
                }
            }
            if !decoded.contains(.git) {
                if let sqliteIndex = decoded.firstIndex(of: .sqlite) {
                    decoded.insert(.git, at: sqliteIndex + 1)
                } else if let filePathIndex = decoded.firstIndex(of: .filePath) {
                    decoded.insert(.git, at: filePathIndex)
                } else {
                    decoded.append(.git)
                }
            }
            self.displayOrder = decoded
        } else {
            // Default order
            self.displayOrder = [
                .fileType,
                .fileSize,
                .itemCount,
                .creationDate,
                .modificationDate,
                .lastAccessDate,
                .permissions,
                .owner,
                .exif,
                .video,
                .audio,
                .pdf,
                .office,
                .archive,
                .ebook,
                .code,
                .font,
                .diskImage,
                .vectorGraphics,
                .subtitle,
                .html,
                .imageExtended,
                .markdown,
                .config,
                .psd,
                .executable,
                .appBundle,
                .sqlite,
                .git,
                .filePath
            ]
        }

        // Load values from UserDefaults
        self.hoverDelay = UserDefaults.standard.object(forKey: "hoverDelay") as? Double ?? Constants.Defaults.hoverDelay
        self.autoHideEnabled = UserDefaults.standard.object(forKey: "autoHideEnabled") as? Bool ?? Constants.Defaults.autoHideEnabled
        self.launchAtLogin = UserDefaults.standard.object(forKey: "launchAtLogin") as? Bool ?? Constants.Defaults.launchAtLogin
        self.windowOpacity = UserDefaults.standard.object(forKey: "windowOpacity") as? Double ?? Constants.Defaults.windowOpacity
        self.windowMaxWidth = UserDefaults.standard.object(forKey: "windowMaxWidth") as? Double ?? Constants.Defaults.windowMaxWidth
        self.fontSize = UserDefaults.standard.object(forKey: "fontSize") as? Double ?? Constants.Defaults.fontSize
        self.enableBlur = UserDefaults.standard.object(forKey: "enableBlur") as? Bool ?? Constants.Defaults.enableBlur
        self.compactMode = UserDefaults.standard.object(forKey: "compactMode") as? Bool ?? Constants.Defaults.compactMode
        self.showCreationDate = UserDefaults.standard.object(forKey: "showCreationDate") as? Bool ?? Constants.Defaults.showCreationDate
        self.showModificationDate = UserDefaults.standard.object(forKey: "showModificationDate") as? Bool ?? Constants.Defaults.showModificationDate
        self.showFileSize = UserDefaults.standard.object(forKey: "showFileSize") as? Bool ?? Constants.Defaults.showFileSize
        self.showFileType = UserDefaults.standard.object(forKey: "showFileType") as? Bool ?? Constants.Defaults.showFileType
        self.showFilePath = UserDefaults.standard.object(forKey: "showFilePath") as? Bool ?? Constants.Defaults.showFilePath
        self.showIcon = UserDefaults.standard.object(forKey: "showIcon") as? Bool ?? Constants.Defaults.showIcon
        self.showLastAccessDate = UserDefaults.standard.object(forKey: "showLastAccessDate") as? Bool ?? Constants.Defaults.showLastAccessDate
        self.showPermissions = UserDefaults.standard.object(forKey: "showPermissions") as? Bool ?? Constants.Defaults.showPermissions
        self.showOwner = UserDefaults.standard.object(forKey: "showOwner") as? Bool ?? Constants.Defaults.showOwner
        self.showItemCount = UserDefaults.standard.object(forKey: "showItemCount") as? Bool ?? Constants.Defaults.showItemCount
        self.showEXIF = UserDefaults.standard.object(forKey: "showEXIF") as? Bool ?? Constants.Defaults.showEXIF
        self.showEXIFCamera = UserDefaults.standard.object(forKey: "showEXIFCamera") as? Bool ?? Constants.Defaults.showEXIFCamera
        self.showEXIFLens = UserDefaults.standard.object(forKey: "showEXIFLens") as? Bool ?? Constants.Defaults.showEXIFLens
        self.showEXIFSettings = UserDefaults.standard.object(forKey: "showEXIFSettings") as? Bool ?? Constants.Defaults.showEXIFSettings
        self.showEXIFDateTaken = UserDefaults.standard.object(forKey: "showEXIFDateTaken") as? Bool ?? Constants.Defaults.showEXIFDateTaken
        self.showEXIFDimensions = UserDefaults.standard.object(forKey: "showEXIFDimensions") as? Bool ?? Constants.Defaults.showEXIFDimensions
        self.showEXIFGPS = UserDefaults.standard.object(forKey: "showEXIFGPS") as? Bool ?? Constants.Defaults.showEXIFGPS
        self.showVideo = UserDefaults.standard.object(forKey: "showVideo") as? Bool ?? Constants.Defaults.showVideo
        self.showVideoDuration = UserDefaults.standard.object(forKey: "showVideoDuration") as? Bool ?? Constants.Defaults.showVideoDuration
        self.showVideoResolution = UserDefaults.standard.object(forKey: "showVideoResolution") as? Bool ?? Constants.Defaults.showVideoResolution
        self.showVideoCodec = UserDefaults.standard.object(forKey: "showVideoCodec") as? Bool ?? Constants.Defaults.showVideoCodec
        self.showVideoFrameRate = UserDefaults.standard.object(forKey: "showVideoFrameRate") as? Bool ?? Constants.Defaults.showVideoFrameRate
        self.showVideoBitrate = UserDefaults.standard.object(forKey: "showVideoBitrate") as? Bool ?? Constants.Defaults.showVideoBitrate
        self.showAudio = UserDefaults.standard.object(forKey: "showAudio") as? Bool ?? Constants.Defaults.showAudio
        self.showAudioTitle = UserDefaults.standard.object(forKey: "showAudioTitle") as? Bool ?? Constants.Defaults.showAudioTitle
        self.showAudioArtist = UserDefaults.standard.object(forKey: "showAudioArtist") as? Bool ?? Constants.Defaults.showAudioArtist
        self.showAudioAlbum = UserDefaults.standard.object(forKey: "showAudioAlbum") as? Bool ?? Constants.Defaults.showAudioAlbum
        self.showAudioGenre = UserDefaults.standard.object(forKey: "showAudioGenre") as? Bool ?? Constants.Defaults.showAudioGenre
        self.showAudioYear = UserDefaults.standard.object(forKey: "showAudioYear") as? Bool ?? Constants.Defaults.showAudioYear
        self.showAudioDuration = UserDefaults.standard.object(forKey: "showAudioDuration") as? Bool ?? Constants.Defaults.showAudioDuration
        self.showAudioBitrate = UserDefaults.standard.object(forKey: "showAudioBitrate") as? Bool ?? Constants.Defaults.showAudioBitrate
        self.showAudioSampleRate = UserDefaults.standard.object(forKey: "showAudioSampleRate") as? Bool ?? Constants.Defaults.showAudioSampleRate
        self.showPDF = UserDefaults.standard.object(forKey: "showPDF") as? Bool ?? Constants.Defaults.showPDF
        self.showPDFPageCount = UserDefaults.standard.object(forKey: "showPDFPageCount") as? Bool ?? Constants.Defaults.showPDFPageCount
        self.showPDFPageSize = UserDefaults.standard.object(forKey: "showPDFPageSize") as? Bool ?? Constants.Defaults.showPDFPageSize
        self.showPDFVersion = UserDefaults.standard.object(forKey: "showPDFVersion") as? Bool ?? Constants.Defaults.showPDFVersion
        self.showPDFTitle = UserDefaults.standard.object(forKey: "showPDFTitle") as? Bool ?? Constants.Defaults.showPDFTitle
        self.showPDFAuthor = UserDefaults.standard.object(forKey: "showPDFAuthor") as? Bool ?? Constants.Defaults.showPDFAuthor
        self.showPDFSubject = UserDefaults.standard.object(forKey: "showPDFSubject") as? Bool ?? Constants.Defaults.showPDFSubject
        self.showPDFCreator = UserDefaults.standard.object(forKey: "showPDFCreator") as? Bool ?? Constants.Defaults.showPDFCreator
        self.showPDFProducer = UserDefaults.standard.object(forKey: "showPDFProducer") as? Bool ?? Constants.Defaults.showPDFProducer
        self.showPDFCreationDate = UserDefaults.standard.object(forKey: "showPDFCreationDate") as? Bool ?? Constants.Defaults.showPDFCreationDate
        self.showPDFModificationDate = UserDefaults.standard.object(forKey: "showPDFModificationDate") as? Bool ?? Constants.Defaults.showPDFModificationDate
        self.showPDFKeywords = UserDefaults.standard.object(forKey: "showPDFKeywords") as? Bool ?? Constants.Defaults.showPDFKeywords
        self.showPDFEncrypted = UserDefaults.standard.object(forKey: "showPDFEncrypted") as? Bool ?? Constants.Defaults.showPDFEncrypted
        self.showOffice = UserDefaults.standard.object(forKey: "showOffice") as? Bool ?? Constants.Defaults.showOffice
        self.showOfficeTitle = UserDefaults.standard.object(forKey: "showOfficeTitle") as? Bool ?? Constants.Defaults.showOfficeTitle
        self.showOfficeAuthor = UserDefaults.standard.object(forKey: "showOfficeAuthor") as? Bool ?? Constants.Defaults.showOfficeAuthor
        self.showOfficeSubject = UserDefaults.standard.object(forKey: "showOfficeSubject") as? Bool ?? Constants.Defaults.showOfficeSubject
        self.showOfficeKeywords = UserDefaults.standard.object(forKey: "showOfficeKeywords") as? Bool ?? Constants.Defaults.showOfficeKeywords
        self.showOfficeComment = UserDefaults.standard.object(forKey: "showOfficeComment") as? Bool ?? Constants.Defaults.showOfficeComment
        self.showOfficeLastModifiedBy = UserDefaults.standard.object(forKey: "showOfficeLastModifiedBy") as? Bool ?? Constants.Defaults.showOfficeLastModifiedBy
        self.showOfficeCreationDate = UserDefaults.standard.object(forKey: "showOfficeCreationDate") as? Bool ?? Constants.Defaults.showOfficeCreationDate
        self.showOfficeModificationDate = UserDefaults.standard.object(forKey: "showOfficeModificationDate") as? Bool ?? Constants.Defaults.showOfficeModificationDate
        self.showOfficePageCount = UserDefaults.standard.object(forKey: "showOfficePageCount") as? Bool ?? Constants.Defaults.showOfficePageCount
        self.showOfficeWordCount = UserDefaults.standard.object(forKey: "showOfficeWordCount") as? Bool ?? Constants.Defaults.showOfficeWordCount
        self.showOfficeSheetCount = UserDefaults.standard.object(forKey: "showOfficeSheetCount") as? Bool ?? Constants.Defaults.showOfficeSheetCount
        self.showOfficeSlideCount = UserDefaults.standard.object(forKey: "showOfficeSlideCount") as? Bool ?? Constants.Defaults.showOfficeSlideCount
        self.showOfficeCompany = UserDefaults.standard.object(forKey: "showOfficeCompany") as? Bool ?? Constants.Defaults.showOfficeCompany
        self.showOfficeCategory = UserDefaults.standard.object(forKey: "showOfficeCategory") as? Bool ?? Constants.Defaults.showOfficeCategory
        self.showArchive = UserDefaults.standard.object(forKey: "showArchive") as? Bool ?? Constants.Defaults.showArchive
        self.showArchiveFormat = UserDefaults.standard.object(forKey: "showArchiveFormat") as? Bool ?? Constants.Defaults.showArchiveFormat
        self.showArchiveFileCount = UserDefaults.standard.object(forKey: "showArchiveFileCount") as? Bool ?? Constants.Defaults.showArchiveFileCount
        self.showArchiveUncompressedSize = UserDefaults.standard.object(forKey: "showArchiveUncompressedSize") as? Bool ?? Constants.Defaults.showArchiveUncompressedSize
        self.showArchiveCompressionRatio = UserDefaults.standard.object(forKey: "showArchiveCompressionRatio") as? Bool ?? Constants.Defaults.showArchiveCompressionRatio
        self.showArchiveEncrypted = UserDefaults.standard.object(forKey: "showArchiveEncrypted") as? Bool ?? Constants.Defaults.showArchiveEncrypted
        self.showEbook = UserDefaults.standard.object(forKey: "showEbook") as? Bool ?? Constants.Defaults.showEbook
        self.showEbookTitle = UserDefaults.standard.object(forKey: "showEbookTitle") as? Bool ?? Constants.Defaults.showEbookTitle
        self.showEbookAuthor = UserDefaults.standard.object(forKey: "showEbookAuthor") as? Bool ?? Constants.Defaults.showEbookAuthor
        self.showEbookPublisher = UserDefaults.standard.object(forKey: "showEbookPublisher") as? Bool ?? Constants.Defaults.showEbookPublisher
        self.showEbookPublicationDate = UserDefaults.standard.object(forKey: "showEbookPublicationDate") as? Bool ?? Constants.Defaults.showEbookPublicationDate
        self.showEbookISBN = UserDefaults.standard.object(forKey: "showEbookISBN") as? Bool ?? Constants.Defaults.showEbookISBN
        self.showEbookLanguage = UserDefaults.standard.object(forKey: "showEbookLanguage") as? Bool ?? Constants.Defaults.showEbookLanguage
        self.showEbookDescription = UserDefaults.standard.object(forKey: "showEbookDescription") as? Bool ?? Constants.Defaults.showEbookDescription
        self.showEbookPageCount = UserDefaults.standard.object(forKey: "showEbookPageCount") as? Bool ?? Constants.Defaults.showEbookPageCount
        self.showCode = UserDefaults.standard.object(forKey: "showCode") as? Bool ?? Constants.Defaults.showCode
        self.showCodeLanguage = UserDefaults.standard.object(forKey: "showCodeLanguage") as? Bool ?? Constants.Defaults.showCodeLanguage
        self.showCodeLineCount = UserDefaults.standard.object(forKey: "showCodeLineCount") as? Bool ?? Constants.Defaults.showCodeLineCount
        self.showCodeLines = UserDefaults.standard.object(forKey: "showCodeLines") as? Bool ?? Constants.Defaults.showCodeLines
        self.showCodeCommentLines = UserDefaults.standard.object(forKey: "showCodeCommentLines") as? Bool ?? Constants.Defaults.showCodeCommentLines
        self.showCodeBlankLines = UserDefaults.standard.object(forKey: "showCodeBlankLines") as? Bool ?? Constants.Defaults.showCodeBlankLines
        self.showCodeEncoding = UserDefaults.standard.object(forKey: "showCodeEncoding") as? Bool ?? Constants.Defaults.showCodeEncoding
        
        // Initialize font metadata toggles
        self.showFont = UserDefaults.standard.object(forKey: "showFont") as? Bool ?? Constants.Defaults.showFont
        self.showFontName = UserDefaults.standard.object(forKey: "showFontName") as? Bool ?? Constants.Defaults.showFontName
        self.showFontFamily = UserDefaults.standard.object(forKey: "showFontFamily") as? Bool ?? Constants.Defaults.showFontFamily
        self.showFontStyle = UserDefaults.standard.object(forKey: "showFontStyle") as? Bool ?? Constants.Defaults.showFontStyle
        self.showFontVersion = UserDefaults.standard.object(forKey: "showFontVersion") as? Bool ?? Constants.Defaults.showFontVersion
        self.showFontDesigner = UserDefaults.standard.object(forKey: "showFontDesigner") as? Bool ?? Constants.Defaults.showFontDesigner
        self.showFontCopyright = UserDefaults.standard.object(forKey: "showFontCopyright") as? Bool ?? Constants.Defaults.showFontCopyright
        self.showFontGlyphCount = UserDefaults.standard.object(forKey: "showFontGlyphCount") as? Bool ?? Constants.Defaults.showFontGlyphCount
        
        // Initialize disk image metadata toggles
        self.showDiskImage = UserDefaults.standard.object(forKey: "showDiskImage") as? Bool ?? Constants.Defaults.showDiskImage
        self.showDiskImageFormat = UserDefaults.standard.object(forKey: "showDiskImageFormat") as? Bool ?? Constants.Defaults.showDiskImageFormat
        self.showDiskImageTotalSize = UserDefaults.standard.object(forKey: "showDiskImageTotalSize") as? Bool ?? Constants.Defaults.showDiskImageTotalSize
        self.showDiskImageCompressedSize = UserDefaults.standard.object(forKey: "showDiskImageCompressedSize") as? Bool ?? Constants.Defaults.showDiskImageCompressedSize
        self.showDiskImageCompressionRatio = UserDefaults.standard.object(forKey: "showDiskImageCompressionRatio") as? Bool ?? Constants.Defaults.showDiskImageCompressionRatio
        self.showDiskImageEncrypted = UserDefaults.standard.object(forKey: "showDiskImageEncrypted") as? Bool ?? Constants.Defaults.showDiskImageEncrypted
        self.showDiskImagePartitionScheme = UserDefaults.standard.object(forKey: "showDiskImagePartitionScheme") as? Bool ?? Constants.Defaults.showDiskImagePartitionScheme
        self.showDiskImageFileSystem = UserDefaults.standard.object(forKey: "showDiskImageFileSystem") as? Bool ?? Constants.Defaults.showDiskImageFileSystem
        
        self.showVectorGraphics = UserDefaults.standard.object(forKey: "showVectorGraphics") as? Bool ?? Constants.Defaults.showVectorGraphics
        self.showVectorGraphicsFormat = UserDefaults.standard.object(forKey: "showVectorGraphicsFormat") as? Bool ?? Constants.Defaults.showVectorGraphicsFormat
        self.showVectorGraphicsDimensions = UserDefaults.standard.object(forKey: "showVectorGraphicsDimensions") as? Bool ?? Constants.Defaults.showVectorGraphicsDimensions
        self.showVectorGraphicsViewBox = UserDefaults.standard.object(forKey: "showVectorGraphicsViewBox") as? Bool ?? Constants.Defaults.showVectorGraphicsViewBox
        self.showVectorGraphicsElementCount = UserDefaults.standard.object(forKey: "showVectorGraphicsElementCount") as? Bool ?? Constants.Defaults.showVectorGraphicsElementCount
        self.showVectorGraphicsColorMode = UserDefaults.standard.object(forKey: "showVectorGraphicsColorMode") as? Bool ?? Constants.Defaults.showVectorGraphicsColorMode
        self.showVectorGraphicsCreator = UserDefaults.standard.object(forKey: "showVectorGraphicsCreator") as? Bool ?? Constants.Defaults.showVectorGraphicsCreator
        self.showVectorGraphicsVersion = UserDefaults.standard.object(forKey: "showVectorGraphicsVersion") as? Bool ?? Constants.Defaults.showVectorGraphicsVersion
        
        // Initialize subtitle metadata toggles
        self.showSubtitle = UserDefaults.standard.object(forKey: "showSubtitle") as? Bool ?? Constants.Defaults.showSubtitle
        self.showSubtitleFormat = UserDefaults.standard.object(forKey: "showSubtitleFormat") as? Bool ?? Constants.Defaults.showSubtitleFormat
        self.showSubtitleEncoding = UserDefaults.standard.object(forKey: "showSubtitleEncoding") as? Bool ?? Constants.Defaults.showSubtitleEncoding
        self.showSubtitleEntryCount = UserDefaults.standard.object(forKey: "showSubtitleEntryCount") as? Bool ?? Constants.Defaults.showSubtitleEntryCount
        self.showSubtitleDuration = UserDefaults.standard.object(forKey: "showSubtitleDuration") as? Bool ?? Constants.Defaults.showSubtitleDuration
        self.showSubtitleLanguage = UserDefaults.standard.object(forKey: "showSubtitleLanguage") as? Bool ?? Constants.Defaults.showSubtitleLanguage
        self.showSubtitleFrameRate = UserDefaults.standard.object(forKey: "showSubtitleFrameRate") as? Bool ?? Constants.Defaults.showSubtitleFrameRate
        self.showSubtitleFormatting = UserDefaults.standard.object(forKey: "showSubtitleFormatting") as? Bool ?? Constants.Defaults.showSubtitleFormatting

        // Initialize HTML metadata toggles
        self.showHTML = UserDefaults.standard.object(forKey: "showHTML") as? Bool ?? Constants.Defaults.showHTML
        self.showHTMLTitle = UserDefaults.standard.object(forKey: "showHTMLTitle") as? Bool ?? Constants.Defaults.showHTMLTitle
        self.showHTMLDescription = UserDefaults.standard.object(forKey: "showHTMLDescription") as? Bool ?? Constants.Defaults.showHTMLDescription
        self.showHTMLCharset = UserDefaults.standard.object(forKey: "showHTMLCharset") as? Bool ?? Constants.Defaults.showHTMLCharset
        self.showHTMLOpenGraph = UserDefaults.standard.object(forKey: "showHTMLOpenGraph") as? Bool ?? Constants.Defaults.showHTMLOpenGraph
        self.showHTMLTwitterCard = UserDefaults.standard.object(forKey: "showHTMLTwitterCard") as? Bool ?? Constants.Defaults.showHTMLTwitterCard
        self.showHTMLKeywords = UserDefaults.standard.object(forKey: "showHTMLKeywords") as? Bool ?? Constants.Defaults.showHTMLKeywords
        self.showHTMLAuthor = UserDefaults.standard.object(forKey: "showHTMLAuthor") as? Bool ?? Constants.Defaults.showHTMLAuthor
        self.showHTMLLanguage = UserDefaults.standard.object(forKey: "showHTMLLanguage") as? Bool ?? Constants.Defaults.showHTMLLanguage

        // Initialize extended image metadata toggles (IPTC/XMP)
        self.showImageExtended = UserDefaults.standard.object(forKey: "showImageExtended") as? Bool ?? Constants.Defaults.showImageExtended
        self.showImageCopyright = UserDefaults.standard.object(forKey: "showImageCopyright") as? Bool ?? Constants.Defaults.showImageCopyright
        self.showImageCreator = UserDefaults.standard.object(forKey: "showImageCreator") as? Bool ?? Constants.Defaults.showImageCreator
        self.showImageKeywords = UserDefaults.standard.object(forKey: "showImageKeywords") as? Bool ?? Constants.Defaults.showImageKeywords
        self.showImageRating = UserDefaults.standard.object(forKey: "showImageRating") as? Bool ?? Constants.Defaults.showImageRating
        self.showImageCreatorTool = UserDefaults.standard.object(forKey: "showImageCreatorTool") as? Bool ?? Constants.Defaults.showImageCreatorTool
        self.showImageDescription = UserDefaults.standard.object(forKey: "showImageDescription") as? Bool ?? Constants.Defaults.showImageDescription
        self.showImageHeadline = UserDefaults.standard.object(forKey: "showImageHeadline") as? Bool ?? Constants.Defaults.showImageHeadline

        // Initialize Markdown metadata toggles
        self.showMarkdown = UserDefaults.standard.object(forKey: "showMarkdown") as? Bool ?? Constants.Defaults.showMarkdown
        self.showMarkdownFrontmatter = UserDefaults.standard.object(forKey: "showMarkdownFrontmatter") as? Bool ?? Constants.Defaults.showMarkdownFrontmatter
        self.showMarkdownTitle = UserDefaults.standard.object(forKey: "showMarkdownTitle") as? Bool ?? Constants.Defaults.showMarkdownTitle
        self.showMarkdownWordCount = UserDefaults.standard.object(forKey: "showMarkdownWordCount") as? Bool ?? Constants.Defaults.showMarkdownWordCount
        self.showMarkdownHeadingCount = UserDefaults.standard.object(forKey: "showMarkdownHeadingCount") as? Bool ?? Constants.Defaults.showMarkdownHeadingCount
        self.showMarkdownLinkCount = UserDefaults.standard.object(forKey: "showMarkdownLinkCount") as? Bool ?? Constants.Defaults.showMarkdownLinkCount
        self.showMarkdownImageCount = UserDefaults.standard.object(forKey: "showMarkdownImageCount") as? Bool ?? Constants.Defaults.showMarkdownImageCount
        self.showMarkdownCodeBlockCount = UserDefaults.standard.object(forKey: "showMarkdownCodeBlockCount") as? Bool ?? Constants.Defaults.showMarkdownCodeBlockCount

        // Initialize Config file metadata toggles
        self.showConfig = UserDefaults.standard.object(forKey: "showConfig") as? Bool ?? Constants.Defaults.showConfig
        self.showConfigFormat = UserDefaults.standard.object(forKey: "showConfigFormat") as? Bool ?? Constants.Defaults.showConfigFormat
        self.showConfigValid = UserDefaults.standard.object(forKey: "showConfigValid") as? Bool ?? Constants.Defaults.showConfigValid
        self.showConfigKeyCount = UserDefaults.standard.object(forKey: "showConfigKeyCount") as? Bool ?? Constants.Defaults.showConfigKeyCount
        self.showConfigMaxDepth = UserDefaults.standard.object(forKey: "showConfigMaxDepth") as? Bool ?? Constants.Defaults.showConfigMaxDepth
        self.showConfigHasComments = UserDefaults.standard.object(forKey: "showConfigHasComments") as? Bool ?? Constants.Defaults.showConfigHasComments
        self.showConfigEncoding = UserDefaults.standard.object(forKey: "showConfigEncoding") as? Bool ?? Constants.Defaults.showConfigEncoding

        // Initialize PSD metadata toggles
        self.showPSD = UserDefaults.standard.object(forKey: "showPSD") as? Bool ?? Constants.Defaults.showPSD
        self.showPSDLayerCount = UserDefaults.standard.object(forKey: "showPSDLayerCount") as? Bool ?? Constants.Defaults.showPSDLayerCount
        self.showPSDColorMode = UserDefaults.standard.object(forKey: "showPSDColorMode") as? Bool ?? Constants.Defaults.showPSDColorMode
        self.showPSDBitDepth = UserDefaults.standard.object(forKey: "showPSDBitDepth") as? Bool ?? Constants.Defaults.showPSDBitDepth
        self.showPSDResolution = UserDefaults.standard.object(forKey: "showPSDResolution") as? Bool ?? Constants.Defaults.showPSDResolution
        self.showPSDTransparency = UserDefaults.standard.object(forKey: "showPSDTransparency") as? Bool ?? Constants.Defaults.showPSDTransparency
        self.showPSDDimensions = UserDefaults.standard.object(forKey: "showPSDDimensions") as? Bool ?? Constants.Defaults.showPSDDimensions

        // Initialize Executable metadata toggles
        self.showExecutable = UserDefaults.standard.object(forKey: "showExecutable") as? Bool ?? Constants.Defaults.showExecutable
        self.showExecutableArchitecture = UserDefaults.standard.object(forKey: "showExecutableArchitecture") as? Bool ?? Constants.Defaults.showExecutableArchitecture
        self.showExecutableCodeSigned = UserDefaults.standard.object(forKey: "showExecutableCodeSigned") as? Bool ?? Constants.Defaults.showExecutableCodeSigned
        self.showExecutableSigningAuthority = UserDefaults.standard.object(forKey: "showExecutableSigningAuthority") as? Bool ?? Constants.Defaults.showExecutableSigningAuthority
        self.showExecutableMinimumOS = UserDefaults.standard.object(forKey: "showExecutableMinimumOS") as? Bool ?? Constants.Defaults.showExecutableMinimumOS
        self.showExecutableSDKVersion = UserDefaults.standard.object(forKey: "showExecutableSDKVersion") as? Bool ?? Constants.Defaults.showExecutableSDKVersion
        self.showExecutableFileType = UserDefaults.standard.object(forKey: "showExecutableFileType") as? Bool ?? Constants.Defaults.showExecutableFileType

        // Initialize App Bundle metadata toggles
        self.showAppBundle = UserDefaults.standard.object(forKey: "showAppBundle") as? Bool ?? Constants.Defaults.showAppBundle
        self.showAppBundleID = UserDefaults.standard.object(forKey: "showAppBundleID") as? Bool ?? Constants.Defaults.showAppBundleID
        self.showAppBundleVersion = UserDefaults.standard.object(forKey: "showAppBundleVersion") as? Bool ?? Constants.Defaults.showAppBundleVersion
        self.showAppBundleBuildNumber = UserDefaults.standard.object(forKey: "showAppBundleBuildNumber") as? Bool ?? Constants.Defaults.showAppBundleBuildNumber
        self.showAppBundleMinimumOS = UserDefaults.standard.object(forKey: "showAppBundleMinimumOS") as? Bool ?? Constants.Defaults.showAppBundleMinimumOS
        self.showAppBundleCategory = UserDefaults.standard.object(forKey: "showAppBundleCategory") as? Bool ?? Constants.Defaults.showAppBundleCategory
        self.showAppBundleCopyright = UserDefaults.standard.object(forKey: "showAppBundleCopyright") as? Bool ?? Constants.Defaults.showAppBundleCopyright
        self.showAppBundleCodeSigned = UserDefaults.standard.object(forKey: "showAppBundleCodeSigned") as? Bool ?? Constants.Defaults.showAppBundleCodeSigned
        self.showAppBundleEntitlements = UserDefaults.standard.object(forKey: "showAppBundleEntitlements") as? Bool ?? Constants.Defaults.showAppBundleEntitlements

        // Initialize SQLite metadata toggles
        self.showSQLite = UserDefaults.standard.object(forKey: "showSQLite") as? Bool ?? Constants.Defaults.showSQLite
        self.showSQLiteTableCount = UserDefaults.standard.object(forKey: "showSQLiteTableCount") as? Bool ?? Constants.Defaults.showSQLiteTableCount
        self.showSQLiteIndexCount = UserDefaults.standard.object(forKey: "showSQLiteIndexCount") as? Bool ?? Constants.Defaults.showSQLiteIndexCount
        self.showSQLiteTriggerCount = UserDefaults.standard.object(forKey: "showSQLiteTriggerCount") as? Bool ?? Constants.Defaults.showSQLiteTriggerCount
        self.showSQLiteViewCount = UserDefaults.standard.object(forKey: "showSQLiteViewCount") as? Bool ?? Constants.Defaults.showSQLiteViewCount
        self.showSQLiteTotalRows = UserDefaults.standard.object(forKey: "showSQLiteTotalRows") as? Bool ?? Constants.Defaults.showSQLiteTotalRows
        self.showSQLiteSchemaVersion = UserDefaults.standard.object(forKey: "showSQLiteSchemaVersion") as? Bool ?? Constants.Defaults.showSQLiteSchemaVersion
        self.showSQLitePageSize = UserDefaults.standard.object(forKey: "showSQLitePageSize") as? Bool ?? Constants.Defaults.showSQLitePageSize
        self.showSQLiteEncoding = UserDefaults.standard.object(forKey: "showSQLiteEncoding") as? Bool ?? Constants.Defaults.showSQLiteEncoding

        // Initialize Git metadata toggles
        self.showGit = UserDefaults.standard.object(forKey: "showGit") as? Bool ?? Constants.Defaults.showGit
        self.showGitBranchCount = UserDefaults.standard.object(forKey: "showGitBranchCount") as? Bool ?? Constants.Defaults.showGitBranchCount
        self.showGitCurrentBranch = UserDefaults.standard.object(forKey: "showGitCurrentBranch") as? Bool ?? Constants.Defaults.showGitCurrentBranch
        self.showGitCommitCount = UserDefaults.standard.object(forKey: "showGitCommitCount") as? Bool ?? Constants.Defaults.showGitCommitCount
        self.showGitLastCommitDate = UserDefaults.standard.object(forKey: "showGitLastCommitDate") as? Bool ?? Constants.Defaults.showGitLastCommitDate
        self.showGitLastCommitMessage = UserDefaults.standard.object(forKey: "showGitLastCommitMessage") as? Bool ?? Constants.Defaults.showGitLastCommitMessage
        self.showGitRemoteURL = UserDefaults.standard.object(forKey: "showGitRemoteURL") as? Bool ?? Constants.Defaults.showGitRemoteURL
        self.showGitUncommittedChanges = UserDefaults.standard.object(forKey: "showGitUncommittedChanges") as? Bool ?? Constants.Defaults.showGitUncommittedChanges
        self.showGitTagCount = UserDefaults.standard.object(forKey: "showGitTagCount") as? Bool ?? Constants.Defaults.showGitTagCount

        self.followCursor = UserDefaults.standard.object(forKey: "followCursor") as? Bool ?? Constants.Defaults.followCursor
        self.windowOffsetX = UserDefaults.standard.object(forKey: "windowOffsetX") as? Double ?? Constants.Defaults.windowOffsetX
        self.windowOffsetY = UserDefaults.standard.object(forKey: "windowOffsetY") as? Double ?? Constants.Defaults.windowOffsetY

        // Load UI style preference
        if let styleString = UserDefaults.standard.string(forKey: "uiStyle"),
           let style = UIStyle(rawValue: styleString) {
            self.uiStyle = style
        } else {
            self.uiStyle = .macOS
        }

        // Load language preference
        if let langString = UserDefaults.standard.string(forKey: "preferredLanguage"),
           let language = AppLanguage(rawValue: langString) {
            self.preferredLanguage = language
        } else {
            self.preferredLanguage = .system
        }

        // Load update preferences
        self.includePrereleases = UserDefaults.standard.object(forKey: "includePrereleases") as? Bool ?? Constants.Defaults.includePrereleases

        // Apply language preference on launch
        applyLanguagePreference()
    }

    private func applyLanguagePreference() {
        if preferredLanguage == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([preferredLanguage.rawValue], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }

    func resetToDefaults() {
        hoverDelay = Constants.Defaults.hoverDelay
        autoHideEnabled = Constants.Defaults.autoHideEnabled
        launchAtLogin = Constants.Defaults.launchAtLogin
        windowOpacity = Constants.Defaults.windowOpacity
        windowMaxWidth = Constants.Defaults.windowMaxWidth
        fontSize = Constants.Defaults.fontSize
        enableBlur = Constants.Defaults.enableBlur
        compactMode = Constants.Defaults.compactMode
        showCreationDate = Constants.Defaults.showCreationDate
        showModificationDate = Constants.Defaults.showModificationDate
        showFileSize = Constants.Defaults.showFileSize
        showFileType = Constants.Defaults.showFileType
        showFilePath = Constants.Defaults.showFilePath
        showIcon = Constants.Defaults.showIcon
        showLastAccessDate = Constants.Defaults.showLastAccessDate
        showPermissions = Constants.Defaults.showPermissions
        showOwner = Constants.Defaults.showOwner
        showItemCount = Constants.Defaults.showItemCount
        showEXIF = Constants.Defaults.showEXIF
        showEXIFCamera = Constants.Defaults.showEXIFCamera
        showEXIFLens = Constants.Defaults.showEXIFLens
        showEXIFSettings = Constants.Defaults.showEXIFSettings
        showEXIFDateTaken = Constants.Defaults.showEXIFDateTaken
        showEXIFDimensions = Constants.Defaults.showEXIFDimensions
        showEXIFGPS = Constants.Defaults.showEXIFGPS
        showVideo = Constants.Defaults.showVideo
        showVideoDuration = Constants.Defaults.showVideoDuration
        showVideoResolution = Constants.Defaults.showVideoResolution
        showVideoCodec = Constants.Defaults.showVideoCodec
        showVideoFrameRate = Constants.Defaults.showVideoFrameRate
        showVideoBitrate = Constants.Defaults.showVideoBitrate
        showAudio = Constants.Defaults.showAudio
        showAudioTitle = Constants.Defaults.showAudioTitle
        showAudioArtist = Constants.Defaults.showAudioArtist
        showAudioAlbum = Constants.Defaults.showAudioAlbum
        showAudioGenre = Constants.Defaults.showAudioGenre
        showAudioYear = Constants.Defaults.showAudioYear
        showAudioDuration = Constants.Defaults.showAudioDuration
        showAudioBitrate = Constants.Defaults.showAudioBitrate
        showAudioSampleRate = Constants.Defaults.showAudioSampleRate

        // Reset HTML settings
        showHTML = Constants.Defaults.showHTML
        showHTMLTitle = Constants.Defaults.showHTMLTitle
        showHTMLDescription = Constants.Defaults.showHTMLDescription
        showHTMLCharset = Constants.Defaults.showHTMLCharset
        showHTMLOpenGraph = Constants.Defaults.showHTMLOpenGraph
        showHTMLTwitterCard = Constants.Defaults.showHTMLTwitterCard
        showHTMLKeywords = Constants.Defaults.showHTMLKeywords
        showHTMLAuthor = Constants.Defaults.showHTMLAuthor
        showHTMLLanguage = Constants.Defaults.showHTMLLanguage

        // Reset Extended Image settings
        showImageExtended = Constants.Defaults.showImageExtended
        showImageCopyright = Constants.Defaults.showImageCopyright
        showImageCreator = Constants.Defaults.showImageCreator
        showImageKeywords = Constants.Defaults.showImageKeywords
        showImageRating = Constants.Defaults.showImageRating
        showImageCreatorTool = Constants.Defaults.showImageCreatorTool
        showImageDescription = Constants.Defaults.showImageDescription
        showImageHeadline = Constants.Defaults.showImageHeadline

        // Reset Markdown settings
        showMarkdown = Constants.Defaults.showMarkdown
        showMarkdownFrontmatter = Constants.Defaults.showMarkdownFrontmatter
        showMarkdownTitle = Constants.Defaults.showMarkdownTitle
        showMarkdownWordCount = Constants.Defaults.showMarkdownWordCount
        showMarkdownHeadingCount = Constants.Defaults.showMarkdownHeadingCount
        showMarkdownLinkCount = Constants.Defaults.showMarkdownLinkCount
        showMarkdownImageCount = Constants.Defaults.showMarkdownImageCount
        showMarkdownCodeBlockCount = Constants.Defaults.showMarkdownCodeBlockCount

        // Reset Config settings
        showConfig = Constants.Defaults.showConfig
        showConfigFormat = Constants.Defaults.showConfigFormat
        showConfigValid = Constants.Defaults.showConfigValid
        showConfigKeyCount = Constants.Defaults.showConfigKeyCount
        showConfigMaxDepth = Constants.Defaults.showConfigMaxDepth
        showConfigHasComments = Constants.Defaults.showConfigHasComments
        showConfigEncoding = Constants.Defaults.showConfigEncoding

        // Reset PSD settings
        showPSD = Constants.Defaults.showPSD
        showPSDLayerCount = Constants.Defaults.showPSDLayerCount
        showPSDColorMode = Constants.Defaults.showPSDColorMode
        showPSDBitDepth = Constants.Defaults.showPSDBitDepth
        showPSDResolution = Constants.Defaults.showPSDResolution
        showPSDTransparency = Constants.Defaults.showPSDTransparency
        showPSDDimensions = Constants.Defaults.showPSDDimensions

        // Reset Executable settings
        showExecutable = Constants.Defaults.showExecutable
        showExecutableArchitecture = Constants.Defaults.showExecutableArchitecture
        showExecutableCodeSigned = Constants.Defaults.showExecutableCodeSigned
        showExecutableSigningAuthority = Constants.Defaults.showExecutableSigningAuthority
        showExecutableMinimumOS = Constants.Defaults.showExecutableMinimumOS
        showExecutableSDKVersion = Constants.Defaults.showExecutableSDKVersion
        showExecutableFileType = Constants.Defaults.showExecutableFileType

        // Reset App Bundle settings
        showAppBundle = Constants.Defaults.showAppBundle
        showAppBundleID = Constants.Defaults.showAppBundleID
        showAppBundleVersion = Constants.Defaults.showAppBundleVersion
        showAppBundleBuildNumber = Constants.Defaults.showAppBundleBuildNumber
        showAppBundleMinimumOS = Constants.Defaults.showAppBundleMinimumOS
        showAppBundleCategory = Constants.Defaults.showAppBundleCategory
        showAppBundleCopyright = Constants.Defaults.showAppBundleCopyright
        showAppBundleCodeSigned = Constants.Defaults.showAppBundleCodeSigned
        showAppBundleEntitlements = Constants.Defaults.showAppBundleEntitlements

        // Reset SQLite settings
        showSQLite = Constants.Defaults.showSQLite
        showSQLiteTableCount = Constants.Defaults.showSQLiteTableCount
        showSQLiteIndexCount = Constants.Defaults.showSQLiteIndexCount
        showSQLiteTriggerCount = Constants.Defaults.showSQLiteTriggerCount
        showSQLiteViewCount = Constants.Defaults.showSQLiteViewCount
        showSQLiteTotalRows = Constants.Defaults.showSQLiteTotalRows
        showSQLiteSchemaVersion = Constants.Defaults.showSQLiteSchemaVersion
        showSQLitePageSize = Constants.Defaults.showSQLitePageSize
        showSQLiteEncoding = Constants.Defaults.showSQLiteEncoding

        // Reset Git settings
        showGit = Constants.Defaults.showGit
        showGitBranchCount = Constants.Defaults.showGitBranchCount
        showGitCurrentBranch = Constants.Defaults.showGitCurrentBranch
        showGitCommitCount = Constants.Defaults.showGitCommitCount
        showGitLastCommitDate = Constants.Defaults.showGitLastCommitDate
        showGitLastCommitMessage = Constants.Defaults.showGitLastCommitMessage
        showGitRemoteURL = Constants.Defaults.showGitRemoteURL
        showGitUncommittedChanges = Constants.Defaults.showGitUncommittedChanges
        showGitTagCount = Constants.Defaults.showGitTagCount

        displayOrder = [
            .fileType,
            .fileSize,
            .itemCount,
            .creationDate,
            .modificationDate,
            .lastAccessDate,
            .permissions,
            .owner,
            .exif,
            .video,
            .audio,
            .pdf,
            .office,
            .archive,
            .ebook,
            .code,
            .font,
            .diskImage,
            .vectorGraphics,
            .subtitle,
            .html,
            .imageExtended,
            .markdown,
            .config,
            .psd,
            .executable,
            .appBundle,
            .sqlite,
            .git,
            .filePath
        ]
        followCursor = Constants.Defaults.followCursor
        windowOffsetX = Constants.Defaults.windowOffsetX
        windowOffsetY = Constants.Defaults.windowOffsetY
        uiStyle = .macOS
        preferredLanguage = .system
        includePrereleases = Constants.Defaults.includePrereleases
    }
}
