//
//  ExtensionSettings.swift
//  FinderHoverSyncExt
//
//  Reads display toggles from the shared App Group UserDefaults.
//  The main app writes these keys on every change and on launch,
//  so they stay in sync without direct IPC.
//

import Foundation

enum ExtensionSettings {

    private static let defaults = UserDefaults(suiteName: "group.dev.koukeneko.FinderHover")

    private static func bool(_ key: String, default value: Bool = true) -> Bool {
        defaults?.object(forKey: key) as? Bool ?? value
    }

    // MARK: - Basic

    static var showFileType: Bool { bool("showFileType") }
    static var showFileSize: Bool { bool("showFileSize") }
    static var showCreationDate: Bool { bool("showCreationDate") }
    static var showModificationDate: Bool { bool("showModificationDate") }
    static var showLastAccessDate: Bool { bool("showLastAccessDate", default: false) }
    static var showPermissions: Bool { bool("showPermissions", default: false) }
    static var showOwner: Bool { bool("showOwner", default: false) }
    static var showItemCount: Bool { bool("showItemCount") }
    static var showFilePath: Bool { bool("showFilePath") }

    // MARK: - EXIF / Photo

    static var showEXIF: Bool { bool("showEXIF") }
    static var showEXIFCamera: Bool { bool("showEXIFCamera") }
    static var showEXIFLens: Bool { bool("showEXIFLens") }
    static var showEXIFSettings: Bool { bool("showEXIFSettings") }
    static var showEXIFDateTaken: Bool { bool("showEXIFDateTaken") }
    static var showEXIFDimensions: Bool { bool("showEXIFDimensions") }
    static var showEXIFGPS: Bool { bool("showEXIFGPS", default: false) }
    static var showEXIFColorProfile: Bool { bool("showEXIFColorProfile", default: false) }
    static var showEXIFBitDepth: Bool { bool("showEXIFBitDepth", default: false) }
    static var showEXIFHDRInfo: Bool { bool("showEXIFHDRInfo", default: false) }

    // MARK: - Video

    static var showVideo: Bool { bool("showVideo") }
    static var showVideoDuration: Bool { bool("showVideoDuration") }
    static var showVideoResolution: Bool { bool("showVideoResolution") }
    static var showVideoCodec: Bool { bool("showVideoCodec") }
    static var showVideoFrameRate: Bool { bool("showVideoFrameRate") }
    static var showVideoBitrate: Bool { bool("showVideoBitrate") }
    static var showVideoHDR: Bool { bool("showVideoHDR") }
    static var showVideoContainerFormat: Bool { bool("showVideoContainerFormat", default: false) }

    // MARK: - Audio

    static var showAudio: Bool { bool("showAudio") }
    static var showAudioTitle: Bool { bool("showAudioTitle") }
    static var showAudioArtist: Bool { bool("showAudioArtist") }
    static var showAudioAlbum: Bool { bool("showAudioAlbum") }
    static var showAudioGenre: Bool { bool("showAudioGenre") }
    static var showAudioYear: Bool { bool("showAudioYear") }
    static var showAudioDuration: Bool { bool("showAudioDuration") }
    static var showAudioBitrate: Bool { bool("showAudioBitrate") }
    static var showAudioSampleRate: Bool { bool("showAudioSampleRate") }

    // MARK: - PDF

    static var showPDF: Bool { bool("showPDF") }
    static var showPDFPageCount: Bool { bool("showPDFPageCount") }
    static var showPDFPageSize: Bool { bool("showPDFPageSize") }
    static var showPDFVersion: Bool { bool("showPDFVersion") }
    static var showPDFTitle: Bool { bool("showPDFTitle") }
    static var showPDFAuthor: Bool { bool("showPDFAuthor") }
    static var showPDFEncrypted: Bool { bool("showPDFEncrypted") }

    // MARK: - Archive

    static var showArchive: Bool { bool("showArchive") }
    static var showArchiveFormat: Bool { bool("showArchiveFormat") }
    static var showArchiveFileCount: Bool { bool("showArchiveFileCount") }
    static var showArchiveEncrypted: Bool { bool("showArchiveEncrypted") }

    // MARK: - Font

    static var showFont: Bool { bool("showFont") }
    static var showFontName: Bool { bool("showFontName") }
    static var showFontFamily: Bool { bool("showFontFamily") }
    static var showFontStyle: Bool { bool("showFontStyle") }
    static var showFontGlyphCount: Bool { bool("showFontGlyphCount") }

    // MARK: - Image Extended (IPTC/XMP)

    static var showImageExtended: Bool { bool("showImageExtended") }
    static var showImageCopyright: Bool { bool("showImageCopyright") }
    static var showImageCreator: Bool { bool("showImageCreator") }
    static var showImageRating: Bool { bool("showImageRating") }

    // MARK: - App Bundle

    static var showAppBundle: Bool { bool("showAppBundle") }
    static var showAppBundleID: Bool { bool("showAppBundleID") }
    static var showAppBundleVersion: Bool { bool("showAppBundleVersion") }
    static var showAppBundleBuildNumber: Bool { bool("showAppBundleBuildNumber") }
    static var showAppBundleMinimumOS: Bool { bool("showAppBundleMinimumOS") }
    static var showAppBundleCategory: Bool { bool("showAppBundleCategory") }
    static var showAppBundleCopyright: Bool { bool("showAppBundleCopyright") }
    static var showAppBundleCodeSigned: Bool { bool("showAppBundleCodeSigned") }
    static var showAppBundleEntitlements: Bool { bool("showAppBundleEntitlements") }

    // MARK: - System Metadata

    static var showSystemMetadata: Bool { bool("showSystemMetadata") }
    static var showFinderTags: Bool { bool("showFinderTags") }
    static var showWhereFroms: Bool { bool("showWhereFroms") }
    static var showUTI: Bool { bool("showUTI") }
    static var showQuarantineInfo: Bool { bool("showQuarantineInfo") }
    static var showLinkInfo: Bool { bool("showLinkInfo") }
    static var showUsageStats: Bool { bool("showUsageStats") }
    static var showFinderComment: Bool { bool("showFinderComment") }
    static var showAliasTarget: Bool { bool("showAliasTarget") }
}
