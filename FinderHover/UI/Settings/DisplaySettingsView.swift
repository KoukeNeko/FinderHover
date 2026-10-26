//
//  DisplaySettingsView.swift
//  FinderHover
//
//  Display settings page
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Display Settings
struct DisplaySettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var draggingItem: DisplayItem?

    // Data-driven declaration of every toggle section, in on-screen order. Each section's
    // first spec is the master toggle; detail specs pass `gatedBy:` the master key path,
    // reproducing the former `.disabled(!master)` / `.opacity(... ? 1 : 0.5)` gating.
    // `basicInfo` has no master and no gating. `hintKey` is non-nil only where a hint
    // previously rendered. This list is a 1:1 transcription of the old hand-written rows.
    static let sections: [DisplaySection] = [
        DisplaySection(titleKey: "settings.display.basicInfo", hintKey: nil, rows: [
            DisplayToggleSpec("settings.display.showIcon", icon: "photo", \.showIcon),
            DisplayToggleSpec("settings.display.showFileType", icon: "doc.text", \.showFileType),
            DisplayToggleSpec("settings.display.showFileSize", icon: "archivebox", \.showFileSize),
            DisplayToggleSpec("settings.display.showItemCount", icon: "number", \.showItemCount),
            DisplayToggleSpec("settings.display.showCreationDate", icon: "calendar", \.showCreationDate),
            DisplayToggleSpec("settings.display.showModificationDate", icon: "clock", \.showModificationDate),
            DisplayToggleSpec("settings.display.showLastAccessDate", icon: "eye", \.showLastAccessDate),
            DisplayToggleSpec("settings.display.showPermissions", icon: "lock.shield", \.showPermissions),
            DisplayToggleSpec("settings.display.showOwner", icon: "person", \.showOwner),
            DisplayToggleSpec("settings.display.showFilePath", icon: "folder", \.showFilePath),
            DisplayToggleSpec("settings.display.showNotes", icon: "note.text", \.showNotes),
            DisplayToggleSpec("settings.display.showFileSystemAdvanced", icon: "internaldrive", \.showFileSystemAdvanced),
        ]),
        DisplaySection(titleKey: "settings.display.exif", hintKey: "settings.display.exif.hint", rows: [
            DisplayToggleSpec("settings.display.exif.show", icon: IconManager.Photo.camera, \.showEXIF),
            DisplayToggleSpec("settings.display.exif.camera", icon: IconManager.Photo.camera, \.showEXIFCamera, gatedBy: \.showEXIF),
            DisplayToggleSpec("settings.display.exif.lens", icon: IconManager.Photo.lens, \.showEXIFLens, gatedBy: \.showEXIF),
            DisplayToggleSpec("settings.display.exif.settings", icon: IconManager.Photo.settings, \.showEXIFSettings, gatedBy: \.showEXIF),
            DisplayToggleSpec("settings.display.exif.dateTaken", icon: IconManager.Photo.calendarClock, \.showEXIFDateTaken, gatedBy: \.showEXIF),
            DisplayToggleSpec("settings.display.exif.dimensions", icon: IconManager.Photo.dimensions, \.showEXIFDimensions, gatedBy: \.showEXIF),
            DisplayToggleSpec("settings.display.exif.gps", icon: IconManager.Photo.location, \.showEXIFGPS, gatedBy: \.showEXIF),
        ]),
        DisplaySection(titleKey: "settings.display.video", hintKey: "settings.display.video.hint", rows: [
            DisplayToggleSpec("settings.display.video.show", icon: IconManager.Video.video, \.showVideo),
            DisplayToggleSpec("settings.display.video.duration", icon: IconManager.Video.duration, \.showVideoDuration, gatedBy: \.showVideo),
            DisplayToggleSpec("settings.display.video.resolution", icon: IconManager.Video.resolution, \.showVideoResolution, gatedBy: \.showVideo),
            DisplayToggleSpec("settings.display.video.codec", icon: IconManager.Video.codec, \.showVideoCodec, gatedBy: \.showVideo),
            DisplayToggleSpec("settings.display.video.framerate", icon: IconManager.Video.frameRate, \.showVideoFrameRate, gatedBy: \.showVideo),
            DisplayToggleSpec("settings.display.video.bitrate", icon: IconManager.Video.bitrate, \.showVideoBitrate, gatedBy: \.showVideo),
        ]),
        DisplaySection(titleKey: "settings.display.audio", hintKey: "settings.display.audio.hint", rows: [
            DisplayToggleSpec("settings.display.audio.show", icon: IconManager.Audio.music, \.showAudio),
            DisplayToggleSpec("settings.display.audio.title", icon: IconManager.Audio.songTitle, \.showAudioTitle, gatedBy: \.showAudio),
            DisplayToggleSpec("settings.display.audio.artist", icon: IconManager.Audio.artist, \.showAudioArtist, gatedBy: \.showAudio),
            DisplayToggleSpec("settings.display.audio.album", icon: IconManager.Audio.album, \.showAudioAlbum, gatedBy: \.showAudio),
            DisplayToggleSpec("settings.display.audio.genre", icon: IconManager.Audio.genre, \.showAudioGenre, gatedBy: \.showAudio),
            DisplayToggleSpec("settings.display.audio.year", icon: IconManager.Audio.year, \.showAudioYear, gatedBy: \.showAudio),
            DisplayToggleSpec("settings.display.audio.duration", icon: IconManager.Audio.duration, \.showAudioDuration, gatedBy: \.showAudio),
            DisplayToggleSpec("settings.display.audio.bitrate", icon: IconManager.Audio.bitrate, \.showAudioBitrate, gatedBy: \.showAudio),
            DisplayToggleSpec("settings.display.audio.samplerate", icon: IconManager.Audio.sampleRate, \.showAudioSampleRate, gatedBy: \.showAudio),
        ]),
        DisplaySection(titleKey: "settings.display.pdf", hintKey: "settings.display.pdf.hint", rows: [
            DisplayToggleSpec("settings.display.pdf.show", icon: "doc.richtext", \.showPDF),
            DisplayToggleSpec("settings.display.pdf.pageCount", icon: "doc.text", \.showPDFPageCount, gatedBy: \.showPDF),
            DisplayToggleSpec("settings.display.pdf.pageSize", icon: "ruler", \.showPDFPageSize, gatedBy: \.showPDF),
            DisplayToggleSpec("settings.display.pdf.version", icon: "info.circle", \.showPDFVersion, gatedBy: \.showPDF),
            DisplayToggleSpec("settings.display.pdf.title", icon: "textformat", \.showPDFTitle, gatedBy: \.showPDF),
            DisplayToggleSpec("settings.display.pdf.author", icon: "person", \.showPDFAuthor, gatedBy: \.showPDF),
            DisplayToggleSpec("settings.display.pdf.subject", icon: "text.alignleft", \.showPDFSubject, gatedBy: \.showPDF),
            DisplayToggleSpec("settings.display.pdf.creator", icon: "app", \.showPDFCreator, gatedBy: \.showPDF),
            DisplayToggleSpec("settings.display.pdf.producer", icon: "gearshape", \.showPDFProducer, gatedBy: \.showPDF),
            DisplayToggleSpec("settings.display.pdf.creationDate", icon: "calendar", \.showPDFCreationDate, gatedBy: \.showPDF),
            DisplayToggleSpec("settings.display.pdf.modificationDate", icon: "clock", \.showPDFModificationDate, gatedBy: \.showPDF),
            DisplayToggleSpec("settings.display.pdf.keywords", icon: "tag", \.showPDFKeywords, gatedBy: \.showPDF),
            DisplayToggleSpec("settings.display.pdf.encrypted", icon: "lock.fill", \.showPDFEncrypted, gatedBy: \.showPDF),
        ]),
        DisplaySection(titleKey: "settings.display.office", hintKey: "settings.display.office.hint", rows: [
            DisplayToggleSpec("settings.display.office.show", icon: "doc.richtext", \.showOffice),
            DisplayToggleSpec("settings.display.office.title", icon: "textformat", \.showOfficeTitle, gatedBy: \.showOffice),
            DisplayToggleSpec("settings.display.office.author", icon: "person", \.showOfficeAuthor, gatedBy: \.showOffice),
            DisplayToggleSpec("settings.display.office.subject", icon: "text.alignleft", \.showOfficeSubject, gatedBy: \.showOffice),
            DisplayToggleSpec("settings.display.office.keywords", icon: "tag", \.showOfficeKeywords, gatedBy: \.showOffice),
            DisplayToggleSpec("settings.display.office.comment", icon: "text.bubble", \.showOfficeComment, gatedBy: \.showOffice),
            DisplayToggleSpec("settings.display.office.lastModifiedBy", icon: "person.crop.circle", \.showOfficeLastModifiedBy, gatedBy: \.showOffice),
            DisplayToggleSpec("settings.display.office.creationDate", icon: "calendar", \.showOfficeCreationDate, gatedBy: \.showOffice),
            DisplayToggleSpec("settings.display.office.modificationDate", icon: "clock", \.showOfficeModificationDate, gatedBy: \.showOffice),
            DisplayToggleSpec("settings.display.office.pageCount", icon: "doc.text", \.showOfficePageCount, gatedBy: \.showOffice),
            DisplayToggleSpec("settings.display.office.wordCount", icon: "textformat.size", \.showOfficeWordCount, gatedBy: \.showOffice),
            DisplayToggleSpec("settings.display.office.sheetCount", icon: "tablecells", \.showOfficeSheetCount, gatedBy: \.showOffice),
            DisplayToggleSpec("settings.display.office.slideCount", icon: "rectangle.stack", \.showOfficeSlideCount, gatedBy: \.showOffice),
            DisplayToggleSpec("settings.display.office.company", icon: "building.2", \.showOfficeCompany, gatedBy: \.showOffice),
            DisplayToggleSpec("settings.display.office.category", icon: "folder", \.showOfficeCategory, gatedBy: \.showOffice),
        ]),
        DisplaySection(titleKey: "settings.display.archive", hintKey: "settings.display.archive.hint", rows: [
            DisplayToggleSpec("settings.display.archive.show", icon: "doc.zipper", \.showArchive),
            DisplayToggleSpec("settings.display.archive.format", icon: "doc.zipper", \.showArchiveFormat, gatedBy: \.showArchive),
            DisplayToggleSpec("settings.display.archive.fileCount", icon: "doc.on.doc", \.showArchiveFileCount, gatedBy: \.showArchive),
            DisplayToggleSpec("settings.display.archive.uncompressedSize", icon: "arrow.up.doc", \.showArchiveUncompressedSize, gatedBy: \.showArchive),
            DisplayToggleSpec("settings.display.archive.compressionRatio", icon: "chart.bar", \.showArchiveCompressionRatio, gatedBy: \.showArchive),
            DisplayToggleSpec("settings.display.archive.encrypted", icon: "lock.fill", \.showArchiveEncrypted, gatedBy: \.showArchive),
        ]),
        DisplaySection(titleKey: "settings.display.ebook", hintKey: "settings.display.ebook.hint", rows: [
            DisplayToggleSpec("settings.display.ebook.show", icon: "book.closed", \.showEbook),
            DisplayToggleSpec("settings.display.ebook.title", icon: "book.closed", \.showEbookTitle, gatedBy: \.showEbook),
            DisplayToggleSpec("settings.display.ebook.author", icon: "person", \.showEbookAuthor, gatedBy: \.showEbook),
            DisplayToggleSpec("settings.display.ebook.publisher", icon: "building.2", \.showEbookPublisher, gatedBy: \.showEbook),
            DisplayToggleSpec("settings.display.ebook.publicationDate", icon: "calendar", \.showEbookPublicationDate, gatedBy: \.showEbook),
            DisplayToggleSpec("settings.display.ebook.isbn", icon: "barcode", \.showEbookISBN, gatedBy: \.showEbook),
            DisplayToggleSpec("settings.display.ebook.language", icon: "globe", \.showEbookLanguage, gatedBy: \.showEbook),
            DisplayToggleSpec("settings.display.ebook.description", icon: "text.alignleft", \.showEbookDescription, gatedBy: \.showEbook),
            DisplayToggleSpec("settings.display.ebook.pageCount", icon: "doc.text", \.showEbookPageCount, gatedBy: \.showEbook),
        ]),
        DisplaySection(titleKey: "settings.display.code", hintKey: "settings.display.code.hint", rows: [
            DisplayToggleSpec("settings.display.code.show", icon: "chevron.left.forwardslash.chevron.right", \.showCode),
            DisplayToggleSpec("settings.display.code.language", icon: "chevron.left.forwardslash.chevron.right", \.showCodeLanguage, gatedBy: \.showCode),
            DisplayToggleSpec("settings.display.code.lineCount", icon: "number", \.showCodeLineCount, gatedBy: \.showCode),
            DisplayToggleSpec("settings.display.code.codeLines", icon: "curlybraces", \.showCodeLines, gatedBy: \.showCode),
            DisplayToggleSpec("settings.display.code.commentLines", icon: "text.bubble", \.showCodeCommentLines, gatedBy: \.showCode),
            DisplayToggleSpec("settings.display.code.blankLines", icon: "minus", \.showCodeBlankLines, gatedBy: \.showCode),
            DisplayToggleSpec("settings.display.code.encoding", icon: "textformat.abc", \.showCodeEncoding, gatedBy: \.showCode),
        ]),
        DisplaySection(titleKey: "settings.display.font.title", hintKey: "settings.display.font.hint", rows: [
            DisplayToggleSpec("settings.display.font.show", icon: "textformat", \.showFont),
            DisplayToggleSpec("settings.display.font.name", icon: "textformat", \.showFontName, gatedBy: \.showFont),
            DisplayToggleSpec("settings.display.font.family", icon: "textformat.alt", \.showFontFamily, gatedBy: \.showFont),
            DisplayToggleSpec("settings.display.font.style", icon: "italic", \.showFontStyle, gatedBy: \.showFont),
            DisplayToggleSpec("settings.display.font.version", icon: "number", \.showFontVersion, gatedBy: \.showFont),
            DisplayToggleSpec("settings.display.font.designer", icon: "person", \.showFontDesigner, gatedBy: \.showFont),
            DisplayToggleSpec("settings.display.font.copyright", icon: "c.circle", \.showFontCopyright, gatedBy: \.showFont),
            DisplayToggleSpec("settings.display.font.glyphCount", icon: "character.textbox", \.showFontGlyphCount, gatedBy: \.showFont),
        ]),
        DisplaySection(titleKey: "settings.display.diskImage.title", hintKey: "settings.display.diskImage.hint", rows: [
            DisplayToggleSpec("settings.display.diskImage.show", icon: "opticaldiscdrive", \.showDiskImage),
            DisplayToggleSpec("settings.display.diskImage.format", icon: "opticaldiscdrive", \.showDiskImageFormat, gatedBy: \.showDiskImage),
            DisplayToggleSpec("settings.display.diskImage.totalSize", icon: "externaldrive", \.showDiskImageTotalSize, gatedBy: \.showDiskImage),
            DisplayToggleSpec("settings.display.diskImage.compressedSize", icon: "arrow.down.circle", \.showDiskImageCompressedSize, gatedBy: \.showDiskImage),
            DisplayToggleSpec("settings.display.diskImage.compressionRatio", icon: "chart.bar", \.showDiskImageCompressionRatio, gatedBy: \.showDiskImage),
            DisplayToggleSpec("settings.display.diskImage.encrypted", icon: "lock.shield", \.showDiskImageEncrypted, gatedBy: \.showDiskImage),
            DisplayToggleSpec("settings.display.diskImage.partitionScheme", icon: "square.split.2x2", \.showDiskImagePartitionScheme, gatedBy: \.showDiskImage),
            DisplayToggleSpec("settings.display.diskImage.fileSystem", icon: "doc.text", \.showDiskImageFileSystem, gatedBy: \.showDiskImage),
        ]),
        DisplaySection(titleKey: "settings.display.vectorGraphics.title", hintKey: "settings.display.vectorGraphics.hint", rows: [
            DisplayToggleSpec("settings.display.vectorGraphics.show", icon: "paintbrush.pointed", \.showVectorGraphics),
            DisplayToggleSpec("settings.display.vectorGraphics.format", icon: "paintbrush.pointed", \.showVectorGraphicsFormat, gatedBy: \.showVectorGraphics),
            DisplayToggleSpec("settings.display.vectorGraphics.dimensions", icon: "arrow.up.left.and.arrow.down.right", \.showVectorGraphicsDimensions, gatedBy: \.showVectorGraphics),
            DisplayToggleSpec("settings.display.vectorGraphics.viewBox", icon: "rectangle.dashed", \.showVectorGraphicsViewBox, gatedBy: \.showVectorGraphics),
            DisplayToggleSpec("settings.display.vectorGraphics.elementCount", icon: "square.stack.3d.up", \.showVectorGraphicsElementCount, gatedBy: \.showVectorGraphics),
            DisplayToggleSpec("settings.display.vectorGraphics.colorMode", icon: "paintpalette", \.showVectorGraphicsColorMode, gatedBy: \.showVectorGraphics),
            DisplayToggleSpec("settings.display.vectorGraphics.creator", icon: "hammer", \.showVectorGraphicsCreator, gatedBy: \.showVectorGraphics),
            DisplayToggleSpec("settings.display.vectorGraphics.version", icon: "number", \.showVectorGraphicsVersion, gatedBy: \.showVectorGraphics),
        ]),
        DisplaySection(titleKey: "settings.display.subtitle.title", hintKey: "settings.display.subtitle.hint", rows: [
            DisplayToggleSpec("settings.display.subtitle.show", icon: "captions.bubble", \.showSubtitle),
            DisplayToggleSpec("settings.display.subtitle.format", icon: "captions.bubble", \.showSubtitleFormat, gatedBy: \.showSubtitle),
            DisplayToggleSpec("settings.display.subtitle.encoding", icon: "textformat.abc", \.showSubtitleEncoding, gatedBy: \.showSubtitle),
            DisplayToggleSpec("settings.display.subtitle.entryCount", icon: "list.number", \.showSubtitleEntryCount, gatedBy: \.showSubtitle),
            DisplayToggleSpec("settings.display.subtitle.duration", icon: "clock", \.showSubtitleDuration, gatedBy: \.showSubtitle),
            DisplayToggleSpec("settings.display.subtitle.language", icon: "globe", \.showSubtitleLanguage, gatedBy: \.showSubtitle),
            DisplayToggleSpec("settings.display.subtitle.frameRate", icon: "film", \.showSubtitleFrameRate, gatedBy: \.showSubtitle),
            DisplayToggleSpec("settings.display.subtitle.hasFormatting", icon: "textformat", \.showSubtitleFormatting, gatedBy: \.showSubtitle),
        ]),
        DisplaySection(titleKey: "settings.display.html.title", hintKey: nil, rows: [
            DisplayToggleSpec("settings.display.html.show", icon: "globe", \.showHTML),
            DisplayToggleSpec("settings.display.html.title.field", icon: "textformat", \.showHTMLTitle, gatedBy: \.showHTML),
            DisplayToggleSpec("settings.display.html.description", icon: "text.alignleft", \.showHTMLDescription, gatedBy: \.showHTML),
            DisplayToggleSpec("settings.display.html.charset", icon: "textformat.abc", \.showHTMLCharset, gatedBy: \.showHTML),
            DisplayToggleSpec("settings.display.html.openGraph", icon: "square.and.arrow.up", \.showHTMLOpenGraph, gatedBy: \.showHTML),
            DisplayToggleSpec("settings.display.html.twitterCard", icon: "bubble.left", \.showHTMLTwitterCard, gatedBy: \.showHTML),
            DisplayToggleSpec("settings.display.html.keywords", icon: "tag", \.showHTMLKeywords, gatedBy: \.showHTML),
            DisplayToggleSpec("settings.display.html.author", icon: "person", \.showHTMLAuthor, gatedBy: \.showHTML),
            DisplayToggleSpec("settings.display.html.language", icon: "globe", \.showHTMLLanguage, gatedBy: \.showHTML),
        ]),
        DisplaySection(titleKey: "settings.display.imageExtended.title", hintKey: nil, rows: [
            DisplayToggleSpec("settings.display.imageExtended.show", icon: "photo.badge.plus", \.showImageExtended),
            DisplayToggleSpec("settings.display.imageExtended.copyright", icon: "c.circle", \.showImageCopyright, gatedBy: \.showImageExtended),
            DisplayToggleSpec("settings.display.imageExtended.creator", icon: "person", \.showImageCreator, gatedBy: \.showImageExtended),
            DisplayToggleSpec("settings.display.imageExtended.keywords", icon: "tag", \.showImageKeywords, gatedBy: \.showImageExtended),
            DisplayToggleSpec("settings.display.imageExtended.rating", icon: "star", \.showImageRating, gatedBy: \.showImageExtended),
            DisplayToggleSpec("settings.display.imageExtended.creatorTool", icon: "wrench.and.screwdriver", \.showImageCreatorTool, gatedBy: \.showImageExtended),
            DisplayToggleSpec("settings.display.imageExtended.description", icon: "text.alignleft", \.showImageDescription, gatedBy: \.showImageExtended),
            DisplayToggleSpec("settings.display.imageExtended.headline", icon: "textformat", \.showImageHeadline, gatedBy: \.showImageExtended),
        ]),
        DisplaySection(titleKey: "settings.display.markdown.title", hintKey: nil, rows: [
            DisplayToggleSpec("settings.display.markdown.show", icon: "text.document", \.showMarkdown),
            DisplayToggleSpec("settings.display.markdown.frontmatter", icon: "doc.text", \.showMarkdownFrontmatter, gatedBy: \.showMarkdown),
            DisplayToggleSpec("settings.display.markdown.title.field", icon: "textformat", \.showMarkdownTitle, gatedBy: \.showMarkdown),
            DisplayToggleSpec("settings.display.markdown.wordCount", icon: "character.cursor.ibeam", \.showMarkdownWordCount, gatedBy: \.showMarkdown),
            DisplayToggleSpec("settings.display.markdown.headingCount", icon: "number", \.showMarkdownHeadingCount, gatedBy: \.showMarkdown),
            DisplayToggleSpec("settings.display.markdown.linkCount", icon: "link", \.showMarkdownLinkCount, gatedBy: \.showMarkdown),
            DisplayToggleSpec("settings.display.markdown.imageCount", icon: "photo", \.showMarkdownImageCount, gatedBy: \.showMarkdown),
            DisplayToggleSpec("settings.display.markdown.codeBlockCount", icon: "chevron.left.forwardslash.chevron.right", \.showMarkdownCodeBlockCount, gatedBy: \.showMarkdown),
        ]),
        DisplaySection(titleKey: "settings.display.config.title", hintKey: nil, rows: [
            DisplayToggleSpec("settings.display.config.show", icon: "gearshape.2", \.showConfig),
            DisplayToggleSpec("settings.display.config.format", icon: "doc.text", \.showConfigFormat, gatedBy: \.showConfig),
            DisplayToggleSpec("settings.display.config.valid", icon: "checkmark.circle", \.showConfigValid, gatedBy: \.showConfig),
            DisplayToggleSpec("settings.display.config.keyCount", icon: "number", \.showConfigKeyCount, gatedBy: \.showConfig),
            DisplayToggleSpec("settings.display.config.maxDepth", icon: "arrow.down.right", \.showConfigMaxDepth, gatedBy: \.showConfig),
            DisplayToggleSpec("settings.display.config.hasComments", icon: "text.bubble", \.showConfigHasComments, gatedBy: \.showConfig),
            DisplayToggleSpec("settings.display.config.encoding", icon: "textformat.abc", \.showConfigEncoding, gatedBy: \.showConfig),
        ]),
        DisplaySection(titleKey: "settings.display.psd.title", hintKey: nil, rows: [
            DisplayToggleSpec("settings.display.psd.show", icon: "square.3.layers.3d", \.showPSD),
            DisplayToggleSpec("settings.display.psd.layerCount", icon: "square.stack.3d.up", \.showPSDLayerCount, gatedBy: \.showPSD),
            DisplayToggleSpec("settings.display.psd.colorMode", icon: "paintpalette", \.showPSDColorMode, gatedBy: \.showPSD),
            DisplayToggleSpec("settings.display.psd.bitDepth", icon: "number", \.showPSDBitDepth, gatedBy: \.showPSD),
            DisplayToggleSpec("settings.display.psd.resolution", icon: "square.dashed", \.showPSDResolution, gatedBy: \.showPSD),
            DisplayToggleSpec("settings.display.psd.transparency", icon: "checkerboard.rectangle", \.showPSDTransparency, gatedBy: \.showPSD),
            DisplayToggleSpec("settings.display.psd.dimensions", icon: "aspectratio", \.showPSDDimensions, gatedBy: \.showPSD),
        ]),
        DisplaySection(titleKey: "settings.display.executable.title", hintKey: nil, rows: [
            DisplayToggleSpec("settings.display.executable.show", icon: "terminal", \.showExecutable),
            DisplayToggleSpec("settings.display.executable.architecture", icon: "cpu", \.showExecutableArchitecture, gatedBy: \.showExecutable),
            DisplayToggleSpec("settings.display.executable.codeSigned", icon: "checkmark.seal", \.showExecutableCodeSigned, gatedBy: \.showExecutable),
            DisplayToggleSpec("settings.display.executable.signingAuthority", icon: "signature", \.showExecutableSigningAuthority, gatedBy: \.showExecutable),
            DisplayToggleSpec("settings.display.executable.minimumOS", icon: "desktopcomputer", \.showExecutableMinimumOS, gatedBy: \.showExecutable),
            DisplayToggleSpec("settings.display.executable.sdkVersion", icon: "wrench.and.screwdriver", \.showExecutableSDKVersion, gatedBy: \.showExecutable),
            DisplayToggleSpec("settings.display.executable.fileType", icon: "doc", \.showExecutableFileType, gatedBy: \.showExecutable),
        ]),
        DisplaySection(titleKey: "settings.display.appBundle.title", hintKey: nil, rows: [
            DisplayToggleSpec("settings.display.appBundle.show", icon: "app.badge", \.showAppBundle),
            DisplayToggleSpec("settings.display.appBundle.bundleID", icon: "app", \.showAppBundleID, gatedBy: \.showAppBundle),
            DisplayToggleSpec("settings.display.appBundle.version", icon: "number", \.showAppBundleVersion, gatedBy: \.showAppBundle),
            DisplayToggleSpec("settings.display.appBundle.buildNumber", icon: "hammer", \.showAppBundleBuildNumber, gatedBy: \.showAppBundle),
            DisplayToggleSpec("settings.display.appBundle.minimumOS", icon: "desktopcomputer", \.showAppBundleMinimumOS, gatedBy: \.showAppBundle),
            DisplayToggleSpec("settings.display.appBundle.category", icon: "folder", \.showAppBundleCategory, gatedBy: \.showAppBundle),
            DisplayToggleSpec("settings.display.appBundle.copyright", icon: "c.circle", \.showAppBundleCopyright, gatedBy: \.showAppBundle),
            DisplayToggleSpec("settings.display.appBundle.codeSigned", icon: "checkmark.seal", \.showAppBundleCodeSigned, gatedBy: \.showAppBundle),
            DisplayToggleSpec("settings.display.appBundle.entitlements", icon: "lock.shield", \.showAppBundleEntitlements, gatedBy: \.showAppBundle),
        ]),
        DisplaySection(titleKey: "settings.display.sqlite.title", hintKey: nil, rows: [
            DisplayToggleSpec("settings.display.sqlite.show", icon: "cylinder", \.showSQLite),
            DisplayToggleSpec("settings.display.sqlite.tableCount", icon: "tablecells", \.showSQLiteTableCount, gatedBy: \.showSQLite),
            DisplayToggleSpec("settings.display.sqlite.indexCount", icon: "list.number", \.showSQLiteIndexCount, gatedBy: \.showSQLite),
            DisplayToggleSpec("settings.display.sqlite.triggerCount", icon: "bolt", \.showSQLiteTriggerCount, gatedBy: \.showSQLite),
            DisplayToggleSpec("settings.display.sqlite.viewCount", icon: "eye", \.showSQLiteViewCount, gatedBy: \.showSQLite),
            DisplayToggleSpec("settings.display.sqlite.totalRows", icon: "number", \.showSQLiteTotalRows, gatedBy: \.showSQLite),
            DisplayToggleSpec("settings.display.sqlite.schemaVersion", icon: "tag", \.showSQLiteSchemaVersion, gatedBy: \.showSQLite),
            DisplayToggleSpec("settings.display.sqlite.pageSize", icon: "doc", \.showSQLitePageSize, gatedBy: \.showSQLite),
            DisplayToggleSpec("settings.display.sqlite.encoding", icon: "textformat.abc", \.showSQLiteEncoding, gatedBy: \.showSQLite),
        ]),
        DisplaySection(titleKey: "settings.display.git.title", hintKey: nil, rows: [
            DisplayToggleSpec("settings.display.git.show", icon: "arrow.triangle.branch", \.showGit),
            DisplayToggleSpec("settings.display.git.branchCount", icon: "arrow.triangle.branch", \.showGitBranchCount, gatedBy: \.showGit),
            DisplayToggleSpec("settings.display.git.currentBranch", icon: "arrow.right.circle", \.showGitCurrentBranch, gatedBy: \.showGit),
            DisplayToggleSpec("settings.display.git.commitCount", icon: "number", \.showGitCommitCount, gatedBy: \.showGit),
            DisplayToggleSpec("settings.display.git.lastCommitDate", icon: "calendar", \.showGitLastCommitDate, gatedBy: \.showGit),
            DisplayToggleSpec("settings.display.git.lastCommitMessage", icon: "text.bubble", \.showGitLastCommitMessage, gatedBy: \.showGit),
            DisplayToggleSpec("settings.display.git.remoteURL", icon: "link", \.showGitRemoteURL, gatedBy: \.showGit),
            DisplayToggleSpec("settings.display.git.uncommittedChanges", icon: "exclamationmark.triangle", \.showGitUncommittedChanges, gatedBy: \.showGit),
            DisplayToggleSpec("settings.display.git.tagCount", icon: "tag", \.showGitTagCount, gatedBy: \.showGit),
        ]),
    ]

    /// Accent per section, matching the popup's per-type accent colors.
    private static let tints: [String: Color] = [
        "settings.display.exif": .yellow, "settings.display.imageExtended.title": .yellow,
        "settings.display.video": .indigo, "settings.display.audio": .pink, "settings.display.pdf": .red,
        "settings.display.office": .blue, "settings.display.archive": .brown, "settings.display.ebook": .orange,
        "settings.display.code": .cyan, "settings.display.font.title": .green, "settings.display.diskImage.title": .gray,
        "settings.display.vectorGraphics.title": .purple, "settings.display.subtitle.title": .teal,
        "settings.display.html.title": .orange, "settings.display.markdown.title": .mint,
        "settings.display.config.title": .gray, "settings.display.psd.title": .blue,
        "settings.display.executable.title": .gray, "settings.display.appBundle.title": .blue,
        "settings.display.sqlite.title": .teal, "settings.display.git.title": .orange
    ]
    private static let orderID = "settings.display.order"

    @State private var selectedSectionID = "settings.display.exif"
    @State private var searchText = ""

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var selectedSection: DisplaySection? {
        Self.sections.first { $0.id == selectedSectionID }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            SettingsCanvas {
                ScrollView {
                    PopupPreview {
                        HoverContentView(fileInfo: PreviewSamples.fileInfo(for: selectedSectionID))
                    }
                    .padding(.vertical, 28)
                    .frame(maxWidth: .infinity)
                }
            }
            SettingsInspector {
                if selectedSectionID == Self.orderID {
                    displayOrder
                } else if let section = selectedSection {
                    inspector(for: section)
                }
            }
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("settings.display.search".localized, text: $searchText)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("displaySearch")
                if !searchText.isEmpty {
                    Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("settings.display.clearSearch".localized)
                }
            }
            .font(.system(size: 13))
            .padding(.horizontal, 8)
            .frame(height: 28)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if query.isEmpty {
                        ForEach(Self.sections) { section in
                            sectionButton(section)
                        }
                        Divider().padding(.vertical, 6)
                        sidebarButton(id: Self.orderID, title: "settings.display.order".localized,
                                      dot: nil, trailing: nil)
                    } else {
                        let results = Self.sections.compactMap { $0.matching(query) }
                        if results.isEmpty {
                            ContentUnavailableView.search(text: query)
                        }
                        ForEach(results) { result in
                            sectionButton(result)
                            ForEach(result.rows.filter { $0.titleKey.localized.localizedStandardContains(query) }) { row in
                                Button { selectedSectionID = result.id } label: {
                                    Text(row.titleKey.localized)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 27)
                                        .padding(.vertical, 2)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding(10)
        .frame(width: SettingsCanvasLayout.sidebarWidth)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func sectionButton(_ section: DisplaySection) -> some View {
        sidebarButton(id: section.id, title: section.titleKey.localized,
                      dot: Self.tints[section.id] ?? .gray, trailing: summary(of: section))
    }

    private func sidebarButton(id: String, title: String, dot: Color?, trailing: String?) -> some View {
        let isOff = trailing == "settings.display.off".localized
        return Button { selectedSectionID = id } label: {
            HStack(spacing: 9) {
                if let dot {
                    Circle().fill(dot).frame(width: 8, height: 8).opacity(isOff ? 0.35 : 1)
                } else {
                    Image(systemName: "line.3.horizontal").font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Text(title)
                    .foregroundStyle(isOff ? .secondary : .primary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if let trailing {
                    Text(trailing)
                        .font(.system(size: 12, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 13))
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(selectedSectionID == id ? Color.accentColor.opacity(0.16) : .clear,
                        in: RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Inspector

    /// A section's first row is its master switch when every other row is gated by it.
    private func master(of section: DisplaySection) -> DisplayToggleSpec? {
        guard let first = section.rows.first, section.rows.count > 1,
              section.rows.dropFirst().allSatisfy({ $0.gate == first.keyPath }) else { return nil }
        return first
    }

    /// "6/7" fields shown, or "Off" when the section's master switch is off.
    private func summary(of section: DisplaySection) -> String {
        let master = master(of: section)
        if let master, !settings[keyPath: master.keyPath] { return "settings.display.off".localized }
        let fields = section.rows.filter { $0.id != master?.id }
        return "\(fields.filter { settings[keyPath: $0.keyPath] }.count)/\(fields.count)"
    }

    @ViewBuilder
    private func inspector(for section: DisplaySection) -> some View {
        let master = master(of: section)
        HStack(spacing: 8) {
            Circle().fill(Self.tints[section.id] ?? .gray).frame(width: 10, height: 10)
            Text(section.titleKey.localized).font(.system(size: 15, weight: .semibold))
            Spacer()
            if let master {
                Toggle("", isOn: binding(master.keyPath))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .accessibilityLabel(master.titleKey.localized)
            }
        }
        InspectorGroup {
            let fields = section.rows.filter { $0.id != master?.id }
            ForEach(Array(fields.enumerated()), id: \.element.id) { index, spec in
                if index > 0 { Divider() }
                InspectorToggleRow(title: spec.titleKey.localized, isOn: binding(spec.keyPath))
                    .disabled(!(spec.gate.map { settings[keyPath: $0] } ?? true))
            }
        }
        if let hintKey = section.hintKey {
            Text(hintKey.localized)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func binding(_ keyPath: ReferenceWritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(get: { settings[keyPath: keyPath] }, set: { settings[keyPath: keyPath] = $0 })
    }

    private var displayOrder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("settings.display.order".localized).font(.system(size: 15, weight: .semibold))
            Text("settings.display.order.hint".localized)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 0) {
                ForEach(settings.displayOrder) { item in
                    HStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.tertiary)
                        Image(systemName: item.icon)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 20)
                        Text(item.localizedName)
                        Spacer()
                        Button { move(item, by: -1) } label: {
                            Image(systemName: "chevron.up")
                        }
                        .disabled(settings.displayOrder.first == item)
                        .accessibilityLabel("settings.display.moveUp".localized(item.localizedName))
                        Button { move(item, by: 1) } label: {
                            Image(systemName: "chevron.down")
                        }
                        .disabled(settings.displayOrder.last == item)
                        .accessibilityLabel("settings.display.moveDown".localized(item.localizedName))
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 13))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .background(Color(NSColor.controlBackgroundColor))
                    .onDrag {
                        draggingItem = item
                        return NSItemProvider(item: item.rawValue as NSString,
                                              typeIdentifier: UTType.displayItemOrder.identifier)
                    }
                    .onDrop(of: [UTType.displayItemOrder], delegate: DisplayItemDropDelegate(
                        item: item, items: $settings.displayOrder, draggingItem: $draggingItem
                    ))
                    if item != settings.displayOrder.last {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func move(_ item: DisplayItem, by offset: Int) {
        guard let index = settings.displayOrder.firstIndex(of: item),
              settings.displayOrder.indices.contains(index + offset) else { return }
        settings.displayOrder.swapAt(index, index + offset)
    }
}
