//
//  HoverContentView.swift
//  FinderHover
//
//  macOS-style popup content (v2 layout): header, one block per file type, dates,
//  file details, location footer and notes, separated by hairlines instead of titles.
//

import SwiftUI
import AppKit
import CoreText
import QuickLookThumbnailing

// MARK: - Style Tokens

private enum V2Style {
    static let hairline = Color.gray.opacity(0.3)
    static let barTrack = Color.primary.opacity(0.1)
    static let barFill = Color.primary.opacity(0.45)
    static let tertiary = Color(nsColor: .tertiaryLabelColor)
}

// MARK: - Popup Content

struct HoverContentView: View {
    let fileInfo: FileInfo
    @State private var thumbnail: NSImage?
    @State private var thumbnailRequest: QLThumbnailGenerator.Request?
    @State private var fontPreview: CTFontDescriptor?
    @State private var noteText: String = ""
    @State private var noteErrorMessage: String?
    /// Measured content height of the note editor; drives its auto-growing frame.
    @State private var noteEditorHeight: CGFloat = 0
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject private var windowState = HoverWindowState.shared

    private var fontSize: Double { settings.fontSize }
    private var spacing: CGFloat { settings.compactMode ? 8 : 12 }

    private struct Section: Identifiable {
        let id: String
        var attached = false
        let content: AnyView
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(Array(makeSections().enumerated()), id: \.element.id) { index, section in
                if index > 0 && !section.attached {
                    Rectangle().fill(V2Style.hairline).frame(height: 1)
                }
                section.content
            }
        }
        .padding(.horizontal, settings.compactMode ? 12 : 16)
        .padding(.vertical, settings.compactMode ? 10 : 14)
        .frame(minWidth: 320, maxWidth: settings.windowMaxWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.clear)
        .onAppear {
            loadNote()
            loadFontPreview()
        }
        // Persist whenever the text changes — the original, working save flow.
        .onChange(of: noteText) { _, newValue in
            saveNote(newValue)
        }
    }

    // MARK: Section Order

    /// Groups of generic fields; each renders where its first member sits in the display order.
    private static let genericGroups: [(id: String, items: Set<DisplayItem>)] = [
        ("dates", [.creationDate, .modificationDate, .lastAccessDate]),
        ("file", [.permissions, .owner, .systemMetadata, .fileSystemAdvanced]),
        ("footer", [.filePath]),
        ("notes", [.notes])
    ]

    /// Header first, then the per-type blocks, then the generic groups — both following the
    /// user's display order within their kind, so the v2 skeleton holds for any order.
    private func makeSections() -> [Section] {
        var sections = [Section(id: "header", content: AnyView(header))]

        if let analysisNotice = fileInfo.analysisNotice {
            sections.append(Section(id: "notice", content: AnyView(
                Text(analysisNotice.localizedText)
                    .font(.system(size: fontSize - 1))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            )))
        }

        for item in settings.displayOrder {
            if let content = typeSection(for: item) {
                sections.append(Section(id: item.rawValue, content: content))
            }
        }

        var emitted: Set<String> = []
        for item in settings.displayOrder {
            guard let group = Self.genericGroups.first(where: { $0.items.contains(item) }),
                  !emitted.contains(group.id) else { continue }
            emitted.insert(group.id)
            if let content = genericSection(group.id) {
                let attached = group.id == "notes" && sections.last?.id == "footer"
                sections.append(Section(id: group.id, attached: attached, content: content))
            }
        }
        return sections
    }

    private func genericSection(_ id: String) -> AnyView? {
        switch id {
        case "dates": return datesSection
        case "file": return fileSection
        case "footer": return footerSection
        case "notes": return notesSection
        default: return nil
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            if settings.showIcon {
                let side: CGFloat = settings.compactMode ? 28 : 36
                Image(nsImage: thumbnail ?? fileInfo.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: side * 1.25, maxHeight: side)
                    .clipShape(RoundedRectangle(cornerRadius: thumbnail == nil ? 0 : 4, style: .continuous))
                    .onAppear {
                        // Load thumbnail asynchronously with cancellation support
                        thumbnailRequest = fileInfo.generateThumbnailAsync { image in
                            if let image = image {
                                thumbnail = image
                            }
                        }
                    }
                    .onDisappear {
                        // Cancel pending thumbnail generation to prevent resource accumulation
                        if let request = thumbnailRequest {
                            FileInfo.cancelThumbnailGeneration(request)
                            thumbnailRequest = nil
                        }
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(fileInfo.name)
                    .font(.system(size: fontSize + 2, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .copyable(fileInfo.name)

                if !headerDetails.isEmpty {
                    Text(headerDetails)
                        .font(.system(size: fontSize))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !finderTags.isEmpty {
                    FlowLayout(spacing: 10, lineSpacing: 2) {
                        ForEach(finderTags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Circle().fill(Self.tagColor(tag)).frame(width: 7, height: 7)
                                Text(tag)
                                    .font(.system(size: fontSize - 0.5))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// "ARW File · 21.6 MB" or "Folder · 14 items".
    private var headerDetails: String {
        var parts: [String] = []
        if settings.showFileType {
            parts.append(FileTypeDescriptor.description(fileExtension: fileInfo.fileExtension, isDirectory: fileInfo.isDirectory))
        }
        if fileInfo.isDirectory, settings.showItemCount, let count = fileInfo.itemCount {
            parts.append("\(count.formatted()) \(count == 1 ? "common.item".localized : "common.items".localized)")
        }
        if settings.showFileSize, !(fileInfo.isDirectory && fileInfo.size == 0) {
            parts.append(fileInfo.formattedSize)
        }
        return parts.joined(separator: " · ")
    }

    private var finderTags: [String] {
        guard settings.showSystemMetadata, settings.showFinderTags else { return [] }
        return fileInfo.systemMetadata?.finderTags ?? []
    }

    /// Finder's standard label colors; custom tags keep their color in Finder's private
    /// preferences, so they fall back to gray.
    private static func tagColor(_ name: String) -> Color {
        let workspace = NSWorkspace.shared
        if let index = workspace.fileLabels.firstIndex(of: name), index > 0, index < workspace.fileLabelColors.count {
            return Color(nsColor: workspace.fileLabelColors[index])
        }
        return .gray
    }

    // MARK: Type Sections

    private func typeSection(for item: DisplayItem) -> AnyView? {
        switch item {
        case .exif: return exifSection
        case .video: return videoSection
        case .audio: return audioSection
        case .pdf: return pdfSection
        case .office: return officeSection
        case .archive: return archiveSection
        case .code: return codeSection
        case .font: return fontSection
        case .diskImage: return diskImageSection
        case .markdown: return markdownSection
        case .appBundle: return appBundleSection
        case .git: return gitSection
        case .systemMetadata: return sourceSection
        case .ebook, .vectorGraphics, .subtitle, .html, .imageExtended, .config, .psd,
             .executable, .sqlite, .model3D, .xcodeProject:
            return fieldsOnlySection(for: item)
        case .fileType, .fileSize, .itemCount, .creationDate, .modificationDate, .lastAccessDate,
             .permissions, .owner, .filePath, .fileSystemAdvanced, .notes:
            return nil
        }
    }

    /// EXIF dimensions drawn as a ratio frame; it sits beside the dates when they are shown.
    private var exifPixelSize: PixelSize? {
        guard settings.showEXIF, settings.showEXIFDimensions, let size = fileInfo.exifData?.imageSize else { return nil }
        return PixelSize(size)
    }

    private var exifSection: AnyView? {
        guard settings.showEXIF, let exif = fileInfo.exifData else { return nil }
        let camera = settings.showEXIFCamera ? exif.camera : nil
        let lens = settings.showEXIFLens ? exif.lens : nil
        let specs = settings.showEXIFSettings ? [
            Spec(exif.focalLength, "hover.v2.focal", color: .yellow),
            Spec(exif.aperture, "hover.v2.aperture", color: .yellow),
            Spec(exif.shutterSpeed, "hover.v2.shutter", color: .yellow),
            Spec(exif.iso, "hover.v2.iso", color: .yellow)
        ].compactMap { $0 } : []

        var fields = FieldList()
        fields.add("hover.exif.taken", exif.dateTaken, when: settings.showEXIFDateTaken)
        fields.add("hover.exif.gps", exif.gpsLocation, when: settings.showEXIFGPS)
        fields.add("hover.imageExtended.creatorTool", fileInfo.imageExtendedMetadata?.creatorTool,
                   when: settings.showImageExtended && settings.showImageCreatorTool)
        if settings.showEXIFDimensions, let size = exif.imageSize, PixelSize(size) == nil {
            fields.add("hover.exif.dimensions", size)
        }
        let diagram = dateFields.isEmpty ? exifPixelSize : nil

        guard camera != nil || lens != nil || !specs.isEmpty || !fields.isEmpty || diagram != nil else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: spacing) {
            if camera != nil || lens != nil {
                TitleBlock(title: camera, titleSize: fontSize + 2, subtitle: lens, fontSize: fontSize)
            }
            if !specs.isEmpty { SpecStrip(specs: specs, valueSize: fontSize + 6, fontSize: fontSize) }
            if !fields.isEmpty { FieldGrid(fields: fields.items, fontSize: fontSize) }
            if let diagram { DimensionDiagram(size: diagram, fontSize: fontSize) }
        })
    }

    private var videoSection: AnyView? {
        guard settings.showVideo, let video = fileInfo.videoMetadata else { return nil }
        let duration = settings.showVideoDuration ? video.duration : nil
        let hdr = settings.showVideoHDR ? video.hdrFormat.flatMap { $0 == "SDR" ? nil : $0 } : nil
        let specs = [
            settings.showVideoResolution ? Spec(video.resolution, "hover.video.resolution") : nil,
            settings.showVideoFrameRate ? Spec(video.frameRate, "hover.video.framerate") : nil,
            settings.showVideoCodec ? Spec(video.codec, "hover.video.codec") : nil,
            settings.showVideoBitrate ? Spec(video.bitrate, "hover.video.bitrate") : nil
        ].compactMap { $0 }
        let tracks = [
            video.containerFormat,
            video.videoTracks.flatMap { $0 > 0 ? countText("hover.v2.videoTracks", $0) : nil },
            video.audioTracks.flatMap { $0 > 0 ? countText("hover.v2.audioTracks", $0) : nil },
            video.subtitleTracks.flatMap { $0 > 0 ? countText("hover.v2.subtitleTracks", $0) : nil },
            video.chapterCount.flatMap { $0 > 0 ? countText("hover.v2.chapters", $0) : nil },
            video.attachmentCount.flatMap { $0 > 0 ? countText("hover.v2.attachments", $0) : nil }
        ].compactMap { $0 }.joined(separator: " · ")

        guard duration != nil || hdr != nil || !specs.isEmpty || !tracks.isEmpty else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: spacing) {
            if duration != nil || hdr != nil {
                HeroRow(value: duration, trailing: hdr, color: .indigo, fontSize: fontSize)
            }
            if !specs.isEmpty { SpecStrip(specs: specs, valueSize: fontSize + 4, fontSize: fontSize) }
            if !tracks.isEmpty { CaptionLine(text: tracks, fontSize: fontSize) }
        })
    }

    private var audioSection: AnyView? {
        guard settings.showAudio, let audio = fileInfo.audioMetadata else { return nil }
        let title = settings.showAudioTitle ? audio.title : nil
        let artist = settings.showAudioArtist ? audio.artist : nil
        let albumLine = [
            settings.showAudioAlbum ? audio.album : nil,
            settings.showAudioYear ? audio.year : nil,
            settings.showAudioGenre ? audio.genre : nil
        ].compactMap { $0 }.joined(separator: " · ")
        let specs = [
            settings.showAudioDuration ? Spec(audio.duration, "hover.audio.duration") : nil,
            settings.showAudioBitrate ? Spec(audio.bitrate, "hover.audio.bitrate") : nil,
            settings.showAudioSampleRate ? Spec(audio.sampleRate, "hover.audio.samplerate") : nil,
            Spec(audio.channels, "hover.audio.channels")
        ].compactMap { $0 }

        guard title != nil || artist != nil || !albumLine.isEmpty || !specs.isEmpty else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: spacing) {
            if title != nil || artist != nil || !albumLine.isEmpty {
                TitleBlock(title: title, titleSize: fontSize + 5, accent: artist, accentColor: .pink,
                           subtitle: albumLine.isEmpty ? nil : albumLine, fontSize: fontSize)
            }
            if !specs.isEmpty { SpecStrip(specs: specs, valueSize: fontSize + 4, fontSize: fontSize) }
        })
    }

    private var pdfSection: AnyView? {
        guard settings.showPDF, let pdf = fileInfo.pdfMetadata else { return nil }
        let title = settings.showPDFTitle ? pdf.title : nil
        let author = settings.showPDFAuthor ? pdf.author : nil
        let specs = [
            settings.showPDFPageCount ? Spec(pdf.pageCount?.formatted(), "hover.pdf.pageCount", color: .red) : nil,
            settings.showPDFPageSize ? Spec(pdf.pageSize, "hover.pdf.pageSize") : nil,
            settings.showPDFVersion ? Spec(pdf.version, "hover.pdf.version") : nil,
            settings.showPDFEncrypted ? Spec(pdf.isEncrypted.map(yesNo), "hover.pdf.encrypted") : nil
        ].compactMap { $0 }
        var fields = FieldList()
        fields.add("hover.pdf.subject", pdf.subject, when: settings.showPDFSubject, wide: true)
        fields.add("hover.pdf.keywords", pdf.keywords, when: settings.showPDFKeywords, wide: true)
        fields.add("hover.pdf.creator", pdf.creator, when: settings.showPDFCreator)
        fields.add("hover.pdf.producer", pdf.producer, when: settings.showPDFProducer)
        fields.add("hover.v2.documentCreated", pdf.creationDate, when: settings.showPDFCreationDate)
        fields.add("hover.v2.documentModified", pdf.modificationDate, when: settings.showPDFModificationDate)

        guard title != nil || author != nil || !specs.isEmpty || !fields.isEmpty else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: spacing) {
            if title != nil || author != nil {
                TitleBlock(title: title, titleSize: fontSize + 4, subtitle: author, fontSize: fontSize)
            }
            if !specs.isEmpty { SpecStrip(specs: specs, valueSize: fontSize + 4, fontSize: fontSize) }
            if !fields.isEmpty { FieldGrid(fields: fields.items, fontSize: fontSize) }
        })
    }

    private var officeSection: AnyView? {
        guard settings.showOffice, let office = fileInfo.officeMetadata else { return nil }
        let title = settings.showOfficeTitle ? office.title : nil
        let author = settings.showOfficeAuthor ? office.author : nil
        var specs = [
            settings.showOfficePageCount ? Spec(office.pageCount?.formatted(), "hover.office.pageCount") : nil,
            settings.showOfficeWordCount ? Spec(office.wordCount?.formatted(), "hover.office.wordCount") : nil,
            settings.showOfficeSheetCount ? Spec(office.sheetCount?.formatted(), "hover.office.sheetCount") : nil,
            settings.showOfficeSlideCount ? Spec(office.slideCount?.formatted(), "hover.office.slideCount") : nil
        ].compactMap { $0 }
        if !specs.isEmpty { specs[0].color = .blue }
        var fields = FieldList()
        fields.add("hover.office.subject", office.subject, when: settings.showOfficeSubject, wide: true)
        fields.add("hover.office.keywords", office.keywords, when: settings.showOfficeKeywords, wide: true)
        fields.add("hover.office.comment", office.comment, when: settings.showOfficeComment, wide: true)
        fields.add("hover.v2.documentCreated", office.creationDate, when: settings.showOfficeCreationDate)
        fields.add("hover.v2.documentModified", office.modificationDate, when: settings.showOfficeModificationDate)
        fields.add("hover.office.lastModifiedBy", office.lastModifiedBy, when: settings.showOfficeLastModifiedBy)
        fields.add("hover.office.company", office.company, when: settings.showOfficeCompany)
        fields.add("hover.office.category", office.category, when: settings.showOfficeCategory)

        guard title != nil || author != nil || !specs.isEmpty || !fields.isEmpty else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: spacing) {
            if title != nil || author != nil {
                TitleBlock(title: title, titleSize: fontSize + 4, subtitle: author, fontSize: fontSize)
            }
            if !specs.isEmpty { SpecStrip(specs: specs, valueSize: fontSize + 4, fontSize: fontSize) }
            if !fields.isEmpty { FieldGrid(fields: fields.items, fontSize: fontSize) }
        })
    }

    private var markdownSection: AnyView? {
        guard settings.showMarkdown, let md = fileInfo.markdownMetadata, md.hasData else { return nil }
        let title = settings.showMarkdownTitle ? md.title : nil
        let frontmatter: String? = settings.showMarkdownFrontmatter && md.hasFrontmatter == true
            ? String(format: "hover.v2.frontmatter".localized, md.frontmatterFormat ?? "")
                .trimmingCharacters(in: .whitespaces)
            : nil
        var specs = [
            settings.showMarkdownWordCount ? Spec(md.wordCount?.formatted(), "hover.markdown.wordCount") : nil,
            settings.showMarkdownHeadingCount ? Spec(md.headingCount?.formatted(), "hover.markdown.headingCount") : nil,
            settings.showMarkdownLinkCount ? Spec(md.linkCount?.formatted(), "hover.markdown.linkCount") : nil,
            settings.showMarkdownImageCount ? Spec(md.imageCount?.formatted(), "hover.markdown.imageCount") : nil,
            settings.showMarkdownCodeBlockCount ? Spec(md.codeBlockCount?.formatted(), "hover.markdown.codeBlockCount") : nil
        ].compactMap { $0 }
        if !specs.isEmpty { specs[0].color = .mint }

        guard title != nil || frontmatter != nil || !specs.isEmpty else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: spacing) {
            if title != nil || frontmatter != nil {
                TitleBlock(title: title, titleSize: fontSize + 4, subtitle: frontmatter, fontSize: fontSize)
            }
            if !specs.isEmpty { SpecStrip(specs: specs, valueSize: fontSize + 4, fontSize: fontSize) }
        })
    }

    private var codeSection: AnyView? {
        guard settings.showCode, let code = fileInfo.codeMetadata else { return nil }
        let lineCount = settings.showCodeLineCount ? code.lineCount : nil
        let languageLine = [
            settings.showCodeLanguage ? code.language : nil,
            settings.showCodeEncoding ? code.encoding : nil
        ].compactMap { $0 }.joined(separator: " · ")
        let codeLines = settings.showCodeLines ? code.codeLines : nil
        let commentLines = settings.showCodeCommentLines ? code.commentLines : nil
        let blankLines = settings.showCodeBlankLines ? code.blankLines : nil
        // Bar colors follow the design: code = accent, comments = gray, blank = dim.
        let segments = [
            codeLines.map { (Double($0), Color.cyan) },
            commentLines.map { (Double($0), V2Style.barFill) },
            blankLines.map { (Double($0), V2Style.barTrack) }
        ].compactMap { $0 }
        var fields = FieldList()
        fields.add("hover.code.codeLines", codeLines?.formatted())
        fields.add("hover.code.commentLines", commentLines?.formatted())
        fields.add("hover.code.blankLines", blankLines?.formatted())

        guard lineCount != nil || !languageLine.isEmpty || !fields.isEmpty else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: spacing) {
            if lineCount != nil || !languageLine.isEmpty {
                HeroRow(value: lineCount?.formatted(),
                        unit: lineCount.map { unitText("hover.v2.lines", $0) },
                        trailing: languageLine.isEmpty ? nil : languageLine,
                        color: .cyan, fontSize: fontSize)
            }
            if segments.count > 1, segments.contains(where: { $0.0 > 0 }) { SegmentBar(segments: segments) }
            if !fields.isEmpty { FieldGrid(fields: fields.items, columns: 3, fontSize: fontSize) }
        })
    }

    private var gitSection: AnyView? {
        guard settings.showGit, let git = fileInfo.gitMetadata, git.hasData else { return nil }
        let branch = settings.showGitCurrentBranch ? git.currentBranch : nil
        let changes: String? = settings.showGitUncommittedChanges
            ? git.hasUncommittedChanges.map { ($0 ? "hover.v2.uncommittedChanges" : "hover.v2.noUncommittedChanges").localized }
            : nil
        let commitDate = settings.showGitLastCommitDate ? git.lastCommitDate : nil
        let commitMessage = settings.showGitLastCommitMessage ? git.lastCommitMessage : nil
        let specs = [
            settings.showGitCommitCount ? Spec(git.commitCount?.formatted(), "hover.git.commitCount") : nil,
            settings.showGitBranchCount ? Spec(git.branchCount?.formatted(), "hover.git.branchCount") : nil,
            settings.showGitTagCount ? Spec(git.tagCount?.formatted(), "hover.git.tagCount") : nil
        ].compactMap { $0 }
        let remote = settings.showGitRemoteURL ? git.remoteURL : nil

        guard branch != nil || changes != nil || commitDate != nil || commitMessage != nil
                || !specs.isEmpty || remote != nil else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: spacing) {
            if branch != nil || changes != nil {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if let branch {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: fontSize + 1, weight: .semibold))
                            .foregroundColor(.orange)
                        Text(branch)
                            .font(.system(size: fontSize + 4, weight: .semibold))
                            .foregroundColor(.orange)
                            .copyable(branch)
                    }
                    Spacer(minLength: 8)
                    if let changes {
                        Text(changes).font(.system(size: fontSize)).foregroundColor(.secondary)
                    }
                }
            }
            if commitDate != nil || commitMessage != nil {
                let label = ["hover.v2.lastCommit".localized, commitDate].compactMap { $0 }.joined(separator: " · ")
                FieldView(field: Field(label: label, value: commitMessage ?? ""), fontSize: fontSize)
            }
            if !specs.isEmpty { SpecStrip(specs: specs, valueSize: fontSize + 4, fontSize: fontSize) }
            if let remote {
                PinnedCopyField(label: "hover.git.remoteURL".localized, value: remote, fontSize: fontSize)
            }
        })
    }

    private var appBundleSection: AnyView? {
        guard settings.showAppBundle, let app = fileInfo.appBundleMetadata, app.hasData else { return nil }
        let version = settings.showAppBundleVersion ? app.version : nil
        let build = settings.showAppBundleBuildNumber ? app.buildNumber : nil
        let category = settings.showAppBundleCategory ? app.category : nil
        let bundleID = settings.showAppBundleID ? app.bundleID : nil
        var fields = FieldList()
        if version == nil {
            fields.add("hover.appBundle.buildNumber", build)
        }
        fields.add("hover.appBundle.minimumOS", app.minimumOS, when: settings.showAppBundleMinimumOS)
        fields.add("hover.appBundle.codeSigned", app.isCodeSigned.map(yesNo), when: settings.showAppBundleCodeSigned)
        fields.add("hover.appBundle.entitlements", app.hasEntitlements.map(yesNo), when: settings.showAppBundleEntitlements)
        fields.add("hover.appBundle.copyright", app.copyright, when: settings.showAppBundleCopyright)

        guard version != nil || category != nil || bundleID != nil || !fields.isEmpty else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: spacing) {
            if version != nil || category != nil {
                HeroRow(value: version,
                        unit: version != nil ? build.map { String(format: "hover.v2.build".localized, $0) } : nil,
                        trailing: category, color: .blue, fontSize: fontSize)
            }
            if let bundleID {
                PinnedCopyField(label: "hover.appBundle.bundleID".localized, value: bundleID, fontSize: fontSize)
            }
            if !fields.isEmpty { FieldGrid(fields: fields.items, fontSize: fontSize) }
        })
    }

    private var archiveSection: AnyView? {
        guard settings.showArchive, let archive = fileInfo.archiveMetadata else { return nil }
        let fileCount = settings.showArchiveFileCount ? archive.fileCount : nil
        let encrypted = settings.showArchiveEncrypted && archive.isEncrypted == true
        let uncompressed = settings.showArchiveUncompressedSize ? archive.uncompressedSize : nil
        var fields = FieldList()
        fields.add("hover.archive.format", archive.format, when: settings.showArchiveFormat)
        fields.add("hover.archive.compressionRatio", archive.formattedCompressionRatio, when: settings.showArchiveCompressionRatio)

        guard fileCount != nil || encrypted || uncompressed != nil || !fields.isEmpty else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: spacing) {
            if fileCount != nil || encrypted {
                HeroRow(value: fileCount?.formatted(),
                        unit: fileCount.map { unitText("hover.v2.files", $0) },
                        trailing: encrypted ? "hover.archive.encrypted".localized : nil,
                        color: .brown, fontSize: fontSize)
            }
            if let uncompressed {
                SizeComparison(rows: [
                    ("hover.archive.uncompressedSize".localized, uncompressed, V2Style.barFill),
                    ("hover.v2.archive".localized, fileInfo.size, .brown)
                ], fontSize: fontSize)
            }
            if !fields.isEmpty { FieldGrid(fields: fields.items, columns: 3, fontSize: fontSize) }
        })
    }

    private var diskImageSection: AnyView? {
        guard settings.showDiskImage, let disk = fileInfo.diskImageMetadata else { return nil }
        let specs = [
            settings.showDiskImageFormat ? Spec(disk.format, "hover.diskImage.format") : nil,
            settings.showDiskImagePartitionScheme ? Spec(disk.partitionScheme, "hover.diskImage.partitionScheme") : nil,
            settings.showDiskImageFileSystem ? Spec(disk.fileSystem, "hover.diskImage.fileSystem") : nil
        ].compactMap { $0 }
        let sizes: [(String, Int64, Color)] = [
            settings.showDiskImageTotalSize ? disk.totalSize.map { ("hover.diskImage.totalSize".localized, $0, V2Style.barFill) } : nil,
            settings.showDiskImageCompressedSize ? disk.compressedSize.map { ("hover.diskImage.compressedSize".localized, $0, Color.gray) } : nil
        ].compactMap { $0 }
        var fields = FieldList()
        fields.add("hover.diskImage.compressionRatio", disk.formattedCompressionRatio, when: settings.showDiskImageCompressionRatio)
        fields.add("hover.diskImage.encrypted", disk.isEncrypted.map(yesNo), when: settings.showDiskImageEncrypted)

        guard !specs.isEmpty || !sizes.isEmpty || !fields.isEmpty else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: spacing) {
            if !specs.isEmpty { SpecStrip(specs: specs, valueSize: fontSize + 4, fontSize: fontSize) }
            if !sizes.isEmpty { SizeComparison(rows: sizes, fontSize: fontSize) }
            if !fields.isEmpty { FieldGrid(fields: fields.items, columns: 3, fontSize: fontSize) }
        })
    }

    private var fontSection: AnyView? {
        guard settings.showFont, let font = fileInfo.fontMetadata else { return nil }
        let family = settings.showFontFamily ? font.fontFamily : nil
        let style = settings.showFontStyle ? font.fontStyle : nil
        var fields = FieldList()
        fields.add("hover.font.name", font.fontName, when: settings.showFontName)
        fields.add("hover.font.version", font.version, when: settings.showFontVersion)
        fields.add("hover.font.glyphCount", font.glyphCount?.formatted(), when: settings.showFontGlyphCount)
        fields.add("hover.font.designer", font.designer, when: settings.showFontDesigner)
        fields.add("hover.font.copyright", font.copyright, when: settings.showFontCopyright, wide: true)

        guard family != nil || style != nil || fontPreview != nil || !fields.isEmpty else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: spacing) {
            if family != nil || style != nil || fontPreview != nil {
                HStack(spacing: 14) {
                    if let fontPreview {
                        Text("Aa").font(Font(CTFontCreateWithFontDescriptor(fontPreview, fontSize + 33, nil)))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        TitleBlock(title: family, titleSize: fontSize + 4, accent: style, accentColor: .green, fontSize: fontSize)
                        if let fontPreview {
                            Text("hover.v2.fontSample".localized)
                                .font(Font(CTFontCreateWithFontDescriptor(fontPreview, fontSize, nil)))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            if !fields.isEmpty { FieldGrid(fields: fields.items, fontSize: fontSize) }
        })
    }

    /// Download source, with the full URL behind an always-visible copy button.
    private var sourceSection: AnyView? {
        guard settings.showSystemMetadata, settings.showWhereFroms, let source = sourceURL else { return nil }
        let url = URL(string: source)
        let host = url?.host
        let remainder = host.flatMap { source.range(of: $0) }.map { String(source[$0.upperBound...]) } ?? ""
        var fields = FieldList()
        if settings.showQuarantineInfo, let quarantine = fileInfo.systemMetadata?.quarantineInfo, quarantine.isQuarantined {
            fields.add("hover.v2.downloaded", quarantineText(quarantine))
        }

        return AnyView(VStack(alignment: .leading, spacing: spacing) {
            VStack(alignment: .leading, spacing: 3) {
                Text("hover.v2.downloadedFrom".localized)
                    .font(.system(size: fontSize - 1))
                    .foregroundColor(.secondary)
                Text(host ?? source)
                    .font(.system(size: fontSize + 3, weight: .semibold))
                    .foregroundColor(.purple)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Text(host == nil ? "" : remainder)
                        .font(.system(size: fontSize - 0.5))
                        .foregroundColor(V2Style.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    V2CopyButton(value: source, key: "source:" + source, fontSize: fontSize)
                }
            }
            if !fields.isEmpty { FieldGrid(fields: fields.items, fontSize: fontSize) }
        })
    }

    private var sourceURL: String? {
        guard let source = fileInfo.systemMetadata?.whereFroms?.first, !source.isEmpty else { return nil }
        return source
    }

    /// Types without a dedicated v2 card: the same fields as before, as a label-over-value grid.
    private func fieldsOnlySection(for item: DisplayItem) -> AnyView? {
        var fields = FieldList()
        switch item {
        case .ebook:
            guard settings.showEbook, let ebook = fileInfo.ebookMetadata else { return nil }
            fields.add("hover.ebook.bookTitle", ebook.title, when: settings.showEbookTitle, wide: true)
            fields.add("hover.ebook.author", ebook.author, when: settings.showEbookAuthor)
            fields.add("hover.ebook.publisher", ebook.publisher, when: settings.showEbookPublisher)
            fields.add("hover.ebook.publicationDate", ebook.publicationDate, when: settings.showEbookPublicationDate)
            fields.add("hover.ebook.isbn", ebook.isbn, when: settings.showEbookISBN)
            fields.add("hover.ebook.language", ebook.language, when: settings.showEbookLanguage)
            fields.add("hover.ebook.pageCount", ebook.pageCount?.formatted(), when: settings.showEbookPageCount)
            fields.add("hover.ebook.description", ebook.description, when: settings.showEbookDescription, wide: true)
        case .vectorGraphics:
            guard settings.showVectorGraphics, let vector = fileInfo.vectorGraphicsMetadata else { return nil }
            fields.add("hover.vectorGraphics.format", vector.format, when: settings.showVectorGraphicsFormat)
            fields.add("hover.vectorGraphics.dimensions", vector.dimensions, when: settings.showVectorGraphicsDimensions)
            fields.add("hover.vectorGraphics.viewBox", vector.viewBox, when: settings.showVectorGraphicsViewBox)
            fields.add("hover.vectorGraphics.elementCount", vector.elementCount?.formatted(), when: settings.showVectorGraphicsElementCount)
            fields.add("hover.vectorGraphics.colorMode", vector.colorMode, when: settings.showVectorGraphicsColorMode)
            fields.add("hover.vectorGraphics.creator", vector.creator, when: settings.showVectorGraphicsCreator)
            fields.add("hover.vectorGraphics.version", vector.version, when: settings.showVectorGraphicsVersion)
        case .subtitle:
            guard settings.showSubtitle, let subtitle = fileInfo.subtitleMetadata else { return nil }
            fields.add("hover.subtitle.format", subtitle.format, when: settings.showSubtitleFormat)
            fields.add("hover.subtitle.encoding", subtitle.encoding, when: settings.showSubtitleEncoding)
            fields.add("hover.subtitle.entryCount", subtitle.entryCount?.formatted(), when: settings.showSubtitleEntryCount)
            fields.add("hover.subtitle.duration", subtitle.duration, when: settings.showSubtitleDuration)
            fields.add("hover.subtitle.language", subtitle.language, when: settings.showSubtitleLanguage)
            fields.add("hover.subtitle.frameRate", subtitle.frameRate, when: settings.showSubtitleFrameRate)
            fields.add("hover.subtitle.hasFormatting", subtitle.hasFormatting.map(yesNo), when: settings.showSubtitleFormatting)
        case .html:
            guard settings.showHTML, let html = fileInfo.htmlMetadata, html.hasData else { return nil }
            fields.add("hover.html.pageTitle", html.title, when: settings.showHTMLTitle, wide: true)
            fields.add("hover.html.description", html.description, when: settings.showHTMLDescription, wide: true)
            fields.add("hover.html.charset", html.charset, when: settings.showHTMLCharset)
            fields.add("hover.html.ogTitle", html.ogTitle, when: settings.showHTMLOpenGraph, wide: true)
            fields.add("hover.html.ogDescription", html.ogDescription, when: settings.showHTMLOpenGraph, wide: true)
            fields.add("hover.html.twitterCard", html.twitterCard, when: settings.showHTMLTwitterCard)
            fields.add("hover.html.keywords", html.keywords, when: settings.showHTMLKeywords, wide: true)
            fields.add("hover.html.author", html.author, when: settings.showHTMLAuthor)
            fields.add("hover.html.language", html.language, when: settings.showHTMLLanguage)
        case .imageExtended:
            guard settings.showImageExtended, let image = fileInfo.imageExtendedMetadata, image.hasData else { return nil }
            fields.add("hover.imageExtended.headline", image.headline, when: settings.showImageHeadline, wide: true)
            fields.add("hover.imageExtended.creator", image.creator, when: settings.showImageCreator)
            fields.add("hover.imageExtended.copyright", image.copyright, when: settings.showImageCopyright)
            fields.add("hover.imageExtended.rating", image.rating.map {
                String(repeating: "★", count: $0) + String(repeating: "☆", count: max(0, 5 - $0))
            }, when: settings.showImageRating)
            // The photo block already shows Creator Tool next to the capture date.
            let toolShownWithPhoto = settings.showEXIF && fileInfo.exifData != nil
            fields.add("hover.imageExtended.creatorTool", image.creatorTool,
                       when: settings.showImageCreatorTool && !toolShownWithPhoto)
            fields.add("hover.imageExtended.keywords", image.keywords, when: settings.showImageKeywords, wide: true)
            fields.add("hover.imageExtended.description", image.description, when: settings.showImageDescription, wide: true)
        case .config:
            guard settings.showConfig, let config = fileInfo.configMetadata, config.hasData else { return nil }
            fields.add("hover.config.format", config.format, when: settings.showConfigFormat)
            fields.add("hover.config.isValid", config.isValid.map(yesNo), when: settings.showConfigValid)
            fields.add("hover.config.keyCount", config.keyCount?.formatted(), when: settings.showConfigKeyCount)
            fields.add("hover.config.maxDepth", config.maxDepth?.formatted(), when: settings.showConfigMaxDepth)
            fields.add("hover.config.hasComments", config.hasComments.map(yesNo), when: settings.showConfigHasComments)
            fields.add("hover.config.encoding", config.encoding, when: settings.showConfigEncoding)
        case .psd:
            guard settings.showPSD, let psd = fileInfo.psdMetadata, psd.hasData else { return nil }
            fields.add("hover.psd.layerCount", psd.layerCount?.formatted(), when: settings.showPSDLayerCount)
            fields.add("hover.psd.colorMode", psd.colorMode, when: settings.showPSDColorMode)
            fields.add("hover.psd.bitDepth", psd.bitDepth.map { "\($0) bit" }, when: settings.showPSDBitDepth)
            fields.add("hover.psd.resolution", psd.resolution, when: settings.showPSDResolution)
            fields.add("hover.psd.transparency", psd.hasTransparency.map(yesNo), when: settings.showPSDTransparency)
            fields.add("hover.psd.dimensions", psd.dimensions, when: settings.showPSDDimensions)
        case .executable:
            guard settings.showExecutable, let exe = fileInfo.executableMetadata, exe.hasData else { return nil }
            fields.add("hover.executable.architecture", exe.architecture, when: settings.showExecutableArchitecture)
            fields.add("hover.executable.codeSigned", exe.isCodeSigned.map(yesNo), when: settings.showExecutableCodeSigned)
            fields.add("hover.executable.signingAuthority", exe.signingAuthority, when: settings.showExecutableSigningAuthority, wide: true)
            fields.add("hover.executable.minimumOS", exe.minimumOS, when: settings.showExecutableMinimumOS)
            fields.add("hover.executable.sdkVersion", exe.sdkVersion, when: settings.showExecutableSDKVersion)
            fields.add("hover.executable.fileType", exe.fileType, when: settings.showExecutableFileType)
        case .sqlite:
            guard settings.showSQLite, let db = fileInfo.sqliteMetadata, db.hasData else { return nil }
            fields.add("hover.sqlite.tableCount", db.tableCount?.formatted(), when: settings.showSQLiteTableCount)
            fields.add("hover.sqlite.indexCount", db.indexCount?.formatted(), when: settings.showSQLiteIndexCount)
            fields.add("hover.sqlite.triggerCount", db.triggerCount?.formatted(), when: settings.showSQLiteTriggerCount)
            fields.add("hover.sqlite.viewCount", db.viewCount?.formatted(), when: settings.showSQLiteViewCount)
            fields.add("hover.sqlite.totalRows", db.totalRows?.formatted(), when: settings.showSQLiteTotalRows)
            fields.add("hover.sqlite.schemaVersion", db.schemaVersion.map { "\($0)" }, when: settings.showSQLiteSchemaVersion)
            fields.add("hover.sqlite.pageSize", db.pageSize.map { "\($0) bytes" }, when: settings.showSQLitePageSize)
            fields.add("hover.sqlite.encoding", db.encoding, when: settings.showSQLiteEncoding)
        case .model3D:
            guard settings.showModel3D, let model = fileInfo.model3DMetadata else { return nil }
            fields.add("hover.model3D.format", model.format, when: settings.showModel3DFormat)
            fields.add("hover.model3D.vertices", model.vertexCount?.formatted(), when: settings.showModel3DVertices)
            fields.add("hover.model3D.faces", model.faceCount?.formatted(), when: settings.showModel3DVertices)
            fields.add("hover.model3D.materials", model.materialCount?.formatted(), when: settings.showModel3DMaterials)
            fields.add("hover.model3D.animations", model.animationCount.flatMap { $0 > 0 ? $0.formatted() : nil },
                       when: settings.showModel3DAnimations)
        case .xcodeProject:
            guard settings.showXcodeProject, let xcode = fileInfo.xcodeProjectMetadata else { return nil }
            fields.add("hover.xcodeProject.projectName", xcode.projectName)
            fields.add("hover.xcodeProject.targets", xcode.targetCount?.formatted(), when: settings.showXcodeTargets)
            fields.add("hover.xcodeProject.swiftVersion", xcode.swiftVersion, when: settings.showXcodeSwiftVersion)
            fields.add("hover.xcodeProject.deploymentTarget", xcode.deploymentTarget, when: settings.showXcodeDeploymentTarget)
            fields.add("hover.xcodeProject.hasTests", xcode.hasTests == true ? "hover.config.yes".localized : nil)
        default:
            return nil
        }
        guard !fields.isEmpty else { return nil }
        return AnyView(FieldGrid(fields: fields.items, fontSize: fontSize))
    }

    // MARK: Generic Sections

    private var dateFields: [Field] {
        var fields = FieldList()
        fields.add("hover.label.created", fileInfo.formattedCreationDate, when: settings.showCreationDate)
        fields.add("hover.label.modified", fileInfo.formattedModificationDate, when: settings.showModificationDate)
        fields.add("hover.label.accessed", fileInfo.formattedLastAccessDate, when: settings.showLastAccessDate)
        if settings.showSystemMetadata, settings.showUsageStats, let usage = fileInfo.systemMetadata?.usageStats {
            let lastOpened = [usage.lastUsedDate, usage.useCount.map { countText("hover.v2.openCount", $0) }]
                .compactMap { $0 }
                .joined(separator: " · ")
            fields.add("hover.v2.lastOpened", lastOpened.isEmpty ? nil : lastOpened, wide: true)
        }
        return fields.items
    }

    private var datesSection: AnyView? {
        let fields = dateFields
        guard !fields.isEmpty else { return nil }
        if let pixelSize = exifPixelSize {
            return AnyView(HStack(alignment: .center, spacing: 20) {
                DimensionDiagram(size: pixelSize, fontSize: fontSize)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(fields) { FieldView(field: $0, fontSize: fontSize) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            })
        }
        return AnyView(FieldGrid(fields: fields, fontSize: fontSize))
    }

    private var fileSection: AnyView? {
        var fields = FieldList()
        let system = settings.showSystemMetadata ? fileInfo.systemMetadata : nil
        let fileSystem = settings.showFileSystemAdvanced ? fileInfo.fileSystemAdvancedMetadata : nil

        fields.add("hover.systemMetadata.iCloud", system?.iCloudStatus, when: settings.showiCloudStatus)
        // When the download source is shown, the quarantine date already sits under it.
        let quarantineShownWithSource = settings.showWhereFroms && sourceURL != nil
        if settings.showQuarantineInfo, !quarantineShownWithSource,
           let quarantine = system?.quarantineInfo, quarantine.isQuarantined {
            fields.add("hover.v2.quarantine", quarantineText(quarantine))
        }
        // Allocated size only adds information when it differs (sparse or APFS-compressed files).
        if settings.showAllocatedSize, let allocated = fileSystem?.formattedAllocatedSize,
           allocated != fileInfo.formattedSize {
            fields.add("hover.v2.allocated", allocated)
        }
        fields.add("hover.systemMetadata.uti", system?.uti, when: settings.showUTI, wide: true)
        fields.add("hover.systemMetadata.comment", system?.finderComment, when: settings.showFinderComment, wide: true)
        if settings.showLinkInfo, let link = system?.linkInfo {
            fields.add("hover.systemMetadata.symlinkTarget", link.isSymlink ? link.symlinkTarget : nil, wide: true)
            fields.add("hover.systemMetadata.hardLinks", link.hardLinkCount > 1 ? "\(link.hardLinkCount)" : nil)
        }
        if settings.showExtendedAttributes, let xattrs = system?.extendedAttributes, !xattrs.isEmpty {
            fields.add("hover.systemMetadata.xattr", "\(xattrs.count)")
        }
        if settings.showAliasTarget, system?.isAliasFile == true {
            fields.add("hover.systemMetadata.aliasTarget", system?.aliasTarget, wide: true)
        }
        if settings.showFileProvider, let provider = fileSystem?.fileProviderName {
            fields.add("hover.fileSystemAdvanced.fileProvider",
                       [provider, fileSystem?.fileProviderStatus].compactMap { $0 }.joined(separator: " · "))
        }
        fields.add("hover.fileSystemAdvanced.spotlightIndexed", fileSystem?.spotlightIndexed.map(yesNo),
                   when: settings.showSpotlightIndexed)
        fields.add("hover.label.mode", fileInfo.formattedPermissions, when: settings.showPermissions)
        fields.add("hover.label.owner", fileInfo.owner, when: settings.showOwner)

        guard !fields.isEmpty else { return nil }
        return AnyView(FieldGrid(fields: fields.items, fontSize: fontSize))
    }

    private var footerSection: AnyView? {
        let path = settings.showFilePath ? breadcrumb : nil
        let volumeInfo = settings.showFileSystemAdvanced && settings.showVolumeInfo ? fileInfo.fileSystemAdvancedMetadata : nil
        let volume = [volumeInfo?.volumeName, volumeInfo?.volumeFormat].compactMap { $0 }.joined(separator: " · ")
        let available = volumeInfo?.formattedVolumeAvailable.map { String(format: "hover.v2.available".localized, $0) }
        let usage = volumeInfo?.volumeUsagePercentage

        guard path != nil || !volume.isEmpty || available != nil else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: 8) {
            if let path {
                HStack(alignment: .top, spacing: 8) {
                    Text(path)
                        .font(.system(size: fontSize - 0.5))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    V2CopyButton(value: fileInfo.path, key: "path:" + fileInfo.path, fontSize: fontSize - 1)
                }
            }
            if !volume.isEmpty || available != nil {
                HStack(spacing: 6) {
                    Text(volume)
                    Spacer(minLength: 6)
                    if let available { Text(available) }
                }
                .font(.system(size: fontSize - 0.5))
                .foregroundColor(.secondary)
            }
            if let usage {
                UsageBar(fraction: usage / 100, fill: V2Style.barFill, track: V2Style.barTrack)
            }
        })
    }

    /// Parent folder as a breadcrumb ("~ › Documents › Work"); the full path is one copy away.
    private var breadcrumb: String {
        let folder = ((fileInfo.path as NSString).deletingLastPathComponent as NSString).abbreviatingWithTildeInPath
        var parts = folder.split(separator: "/").map(String.init)
        if folder.hasPrefix("/") { parts.insert("/", at: 0) }
        return parts.joined(separator: " › ")
    }

    // MARK: Notes

    /// Actual per-line height of the note text (used to size the field in whole rows).
    private var noteLineHeight: CGFloat {
        NSLayoutManager().defaultLineHeight(for: .systemFont(ofSize: settings.fontSize))
    }

    /// The note editor's visible height: at least one row, growing with content up to a
    /// 12-row cap, after which the field scrolls instead of growing further.
    private var noteHeight: CGFloat {
        let pad: CGFloat = 4
        return min(max(noteEditorHeight, noteLineHeight + pad), noteLineHeight * 12 + pad)
    }

    private var notesSection: AnyView? {
        guard settings.showNotes else { return nil }
        return AnyView(VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topLeading) {
                if noteText.isEmpty {
                    Text("hover.notes.placeholder".localized)
                        .font(.system(size: fontSize - 0.5))
                        .foregroundColor(V2Style.tertiary)
                        .allowsHitTesting(false)
                        .padding(.top, 2)
                }
                NotesEditorView(text: $noteText, fontSize: fontSize) { height in
                    if abs(noteEditorHeight - height) > 0.5 { noteEditorHeight = height }
                }
            }
            .frame(height: noteHeight)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(nsColor: .textBackgroundColor).opacity(windowState.isEditingNotes ? 0.85 : 0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(windowState.isEditingNotes ? Color.accentColor.opacity(0.7) : V2Style.hairline, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: windowState.isEditingNotes)
            .help("hover.notes.disclosure".localized)

            if let noteErrorMessage {
                Text(noteErrorMessage)
                    .font(.system(size: fontSize - 1))
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        })
    }

    private func loadNote() {
        // Synchronous so the existing note shows the instant the popup appears (a read is
        // a single fast getxattr); only the per-keystroke write needs to be off-main.
        do {
            noteText = try NotesStorage.read(for: fileInfo.path)
            noteErrorMessage = nil
        } catch {
            noteText = ""
            noteErrorMessage = noteDisplayMessage(for: error)
        }
    }

    private func saveNote(_ note: String) {
        let path = fileInfo.path
        // Dispatch immediately and detached from the view lifecycle: the block runs to
        // completion even if the popup hides the instant editing ends (which is what broke
        // the earlier debounced/.task-based save), while keeping setxattr off the main thread.
        NotesStorage.ioQueue.async {
            do {
                try NotesStorage.save(note, for: path)
                DispatchQueue.main.async { noteErrorMessage = nil }
            } catch {
                DispatchQueue.main.async { noteErrorMessage = noteDisplayMessage(for: error) }
            }
        }
    }

    private func noteDisplayMessage(for error: Error) -> String {
        if let storageError = error as? NotesStorage.StorageError {
            switch storageError {
            case .readFailed:
                return "hover.notes.error.load".localized
            case .writeFailed, .tooLarge:
                return "hover.notes.error.save".localized
            case .deleteFailed:
                return "hover.notes.error.delete".localized
            }
        }

        return error.localizedDescription
    }

    // MARK: Helpers

    private func loadFontPreview() {
        guard settings.showFont, fileInfo.fontMetadata != nil,
              let descriptors = CTFontManagerCreateFontDescriptorsFromURL(URL(fileURLWithPath: fileInfo.path) as CFURL)
                as? [CTFontDescriptor] else { return }
        fontPreview = descriptors.first
    }

    private func quarantineText(_ quarantine: QuarantineInfo) -> String? {
        let text = [
            quarantine.sourceApp.map { String(format: "hover.v2.via".localized, $0) },
            quarantine.downloadDate
        ].compactMap { $0 }.joined(separator: " · ")
        return text.isEmpty ? nil : text
    }

    private func yesNo(_ value: Bool) -> String {
        value ? "hover.config.yes".localized : "hover.config.no".localized
    }

    /// "%ld times"-style text; keys have a `.one` variant for a count of one.
    private func countText(_ key: String, _ count: Int) -> String {
        String(format: (count == 1 ? key + ".one" : key).localized, count)
    }

    private func unitText(_ key: String, _ count: Int) -> String {
        (count == 1 ? key + ".one" : key).localized
    }
}

// MARK: - Field Model

private struct Field: Identifiable {
    let label: String
    let value: String
    var wide = false

    var id: String { label }

    var isWide: Bool { wide || value.count > 30 || value.contains("\n") }
}

/// Collects visible fields, skipping disabled settings and missing values.
private struct FieldList {
    private(set) var items: [Field] = []

    var isEmpty: Bool { items.isEmpty }

    mutating func add(_ labelKey: String, _ value: String?, when enabled: Bool = true, wide: Bool = false) {
        guard enabled, let value, !value.isEmpty else { return }
        items.append(Field(label: labelKey.localized, value: value, wide: wide))
    }
}

private struct Spec: Identifiable {
    let value: String
    let caption: String
    var color: Color = .primary

    var id: String { caption }

    init?(_ value: String?, _ captionKey: String, color: Color = .primary) {
        guard let value, !value.isEmpty else { return nil }
        self.value = value
        self.caption = captionKey.localized
        self.color = color
    }
}

/// "3936 × 2624" as produced by the EXIF extractor.
private struct PixelSize {
    let width: Int
    let height: Int

    init?(_ text: String) {
        let parts = text.components(separatedBy: "×").map { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 2, let width = parts[0], let height = parts[1], width > 0, height > 0 else { return nil }
        self.width = width
        self.height = height
    }

    var megapixels: String {
        String(format: "%.1f MP", Double(width) * Double(height) / 1_000_000)
    }
}

// MARK: - Building Blocks

/// Label above value. Copy is offered while the popup is locked (Option held), as before.
private struct FieldView: View {
    let field: Field
    let fontSize: Double
    @ObservedObject private var windowState = HoverWindowState.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(field.label)
                .font(.system(size: fontSize - 1))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if !field.value.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(field.value)
                        .font(.system(size: fontSize + 0.5, weight: .medium))
                        .fixedSize(horizontal: false, vertical: true)
                    V2CopyButton(value: field.value, key: field.label + ":" + field.value, fontSize: fontSize - 1)
                        .opacity(windowState.isLocked ? 1 : 0)
                        .allowsHitTesting(windowState.isLocked)
                }
            }
        }
    }
}

/// A field whose full value is always one click from the clipboard (remote URL, bundle ID).
private struct PinnedCopyField: View {
    let label: String
    let value: String
    let fontSize: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: fontSize - 1))
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(value)
                    .font(.system(size: fontSize + 0.5, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                V2CopyButton(value: value, key: label + ":" + value, fontSize: fontSize)
            }
        }
    }
}

/// Fields two per row (or `columns`); long values take a full row.
private struct FieldGrid: View {
    let fields: [Field]
    var columns = 2
    let fontSize: Double

    private var rows: [[Field]] {
        var rows: [[Field]] = []
        var current: [Field] = []
        for field in fields {
            if field.isWide {
                if !current.isEmpty { rows.append(current); current = [] }
                rows.append([field])
                continue
            }
            current.append(field)
            if current.count == columns { rows.append(current); current = [] }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: 12) {
                    ForEach(row) { field in
                        FieldView(field: field, fontSize: fontSize)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !(row.first?.isWide ?? false) {
                        ForEach(row.count..<columns, id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                        }
                    }
                }
            }
        }
    }
}

/// Big rounded figures with small uppercase captions.
private struct SpecStrip: View {
    let specs: [Spec]
    let valueSize: Double
    let fontSize: Double
    @ObservedObject private var windowState = HoverWindowState.shared

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(specs) { spec in
                let key = "spec:" + spec.caption + ":" + spec.value
                VStack(spacing: 2) {
                    Text(spec.value)
                        .font(.system(size: valueSize, weight: .semibold, design: .rounded))
                        .foregroundColor(spec.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(windowState.copiedValue == key ? "hover.copy.copied".localized : spec.caption)
                        .font(.system(size: fontSize - 2, weight: .semibold))
                        .kerning(0.54)
                        .textCase(.uppercase)
                        .foregroundColor(windowState.copiedValue == key ? .green : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    if windowState.isLocked { windowState.copyToClipboard(spec.value, key: key) }
                }
            }
        }
    }
}

/// One headline figure (duration, line count, version…) with a unit and a trailing note.
private struct HeroRow: View {
    let value: String?
    var unit: String?
    var trailing: String?
    let color: Color
    let fontSize: Double

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if let value {
                Text(value)
                    .font(.system(size: fontSize + 15, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
                    .copyable(value)
            }
            if let unit {
                Text(unit)
                    .font(.system(size: fontSize + 1))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .font(.system(size: fontSize + 0.5, weight: .medium))
                    .copyable(trailing)
            }
        }
    }
}

/// Title with optional accent line and secondary line (camera + lens, song + artist…).
private struct TitleBlock: View {
    let title: String?
    let titleSize: Double
    var accent: String?
    var accentColor: Color = .primary
    var subtitle: String?
    let fontSize: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title {
                Text(title)
                    .font(.system(size: titleSize, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .copyable(title)
            }
            if let accent {
                Text(accent)
                    .font(.system(size: fontSize + 1, weight: .medium))
                    .foregroundColor(accentColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .copyable(accent)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: fontSize))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .copyable(subtitle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CaptionLine: View {
    let text: String
    let fontSize: Double

    var body: some View {
        Text(text)
            .font(.system(size: fontSize - 0.5))
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .copyable(text)
    }
}

/// Image dimensions as a ratio frame with the pixel counts on its edges.
private struct DimensionDiagram: View {
    let size: PixelSize
    let fontSize: Double

    private var box: CGSize {
        let scale = min(104 / CGFloat(size.width), 78 / CGFloat(size.height))
        return CGSize(width: max(36, CGFloat(size.width) * scale), height: max(24, CGFloat(size.height) * scale))
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 4) {
                Rectangle().fill(V2Style.tertiary).frame(height: 1)
                measure("\(size.width)")
                Rectangle().fill(V2Style.tertiary).frame(height: 1)
            }
            .frame(width: box.width, height: 12)
            HStack(alignment: .top, spacing: 4) {
                VStack(spacing: 3) {
                    Rectangle().fill(V2Style.tertiary).frame(width: 1)
                    measure("\(size.height)")
                    Rectangle().fill(V2Style.tertiary).frame(width: 1)
                }
                .frame(width: 28, height: box.height)
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(V2Style.tertiary, lineWidth: 1)
                    .frame(width: box.width, height: box.height)
                    .overlay(
                        Text(size.megapixels)
                            .font(.system(size: fontSize - 1, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    )
            }
        }
        .copyable("\(size.width) × \(size.height)")
    }

    private func measure(_ text: String) -> some View {
        Text(text)
            .font(.system(size: fontSize - 1, weight: .semibold, design: .rounded))
            .fixedSize()
    }
}

private struct UsageBar: View {
    let fraction: Double
    let fill: Color
    var track: Color = .clear

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(fill).frame(width: geometry.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 3)
    }
}

/// Proportional line breakdown (code / comments / blank).
private struct SegmentBar: View {
    let segments: [(Double, Color)]

    var body: some View {
        GeometryReader { geometry in
            let total = segments.reduce(0) { $0 + $1.0 }
            let available = geometry.size.width - CGFloat(segments.count - 1) * 2
            HStack(spacing: 2) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(segment.1)
                        .frame(width: max(1, available * CGFloat(total > 0 ? segment.0 / total : 0)))
                }
            }
        }
        .frame(height: 4)
    }
}

/// Two sizes as bars of proportional length (uncompressed vs. archive).
private struct SizeComparison: View {
    let rows: [(String, Int64, Color)]
    let fontSize: Double

    var body: some View {
        let largest = Double(rows.map { $0.1 }.max() ?? 0)
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                let formatted = ByteCountFormatter.string(fromByteCount: row.1, countStyle: .file)
                HStack(spacing: 10) {
                    Text(row.0)
                        .font(.system(size: fontSize - 0.5))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: 84, alignment: .leading)
                    UsageBar(fraction: largest > 0 ? Double(row.1) / largest : 0, fill: row.2)
                    Text(formatted)
                        .font(.system(size: fontSize, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .frame(minWidth: 60, alignment: .trailing)
                        .copyable(formatted)
                }
            }
        }
    }
}

private struct V2CopyButton: View {
    let value: String
    let key: String
    let fontSize: Double
    @ObservedObject private var windowState = HoverWindowState.shared
    @State private var isHovering = false

    var body: some View {
        let copied = windowState.copiedValue == key
        Image(systemName: copied ? "checkmark" : "doc.on.doc")
            .font(.system(size: fontSize))
            .foregroundColor(copied ? .green : (isHovering ? .primary : .secondary))
            .frame(width: 14, alignment: .center)
            .contentShape(Rectangle())
            .onTapGesture { windowState.copyToClipboard(value, key: key) }
            .onHover { isHovering = $0 }
            .help("hover.copy.copy".localized)
    }
}

/// While the popup is locked, clicking the text copies it and briefly shows "Copied!".
private struct CopyOnTap: ViewModifier {
    let value: String
    @ObservedObject private var windowState = HoverWindowState.shared

    private var key: String { "text:" + value }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if windowState.copiedValue == key {
                    Text("hover.copy.copied".localized)
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.horizontal, 4)
                        .background(.regularMaterial, in: Capsule())
                        .fixedSize()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if windowState.isLocked { windowState.copyToClipboard(value, key: key) }
            }
    }
}

private extension View {
    func copyable(_ value: String) -> some View {
        modifier(CopyOnTap(value: value))
    }
}

/// Left-to-right wrapping layout for Finder tags.
private struct FlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0, width: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            width = max(width, x + size.width)
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: width, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
