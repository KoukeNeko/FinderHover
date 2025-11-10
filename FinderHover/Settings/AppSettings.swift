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
