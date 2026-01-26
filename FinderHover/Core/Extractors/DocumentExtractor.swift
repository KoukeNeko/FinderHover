//
//  DocumentExtractor.swift
//  FinderHover
//
//  Document metadata extraction functions (PDF, Office, Ebook, Markdown, HTML, Config)
//

import Foundation
import PDFKit

// MARK: - Document Metadata Extractor

enum DocumentExtractor {

    // MARK: - PDF Metadata Extraction

    static func extractPDFMetadata(from url: URL) -> PDFMetadata? {
        guard url.pathExtension.lowercased() == "pdf" else {
            return nil
        }

        guard let pdfDocument = PDFDocument(url: url) else {
            return nil
        }

        let attributes = pdfDocument.documentAttributes

        let title = attributes?[PDFDocumentAttribute.titleAttribute] as? String
        let author = attributes?[PDFDocumentAttribute.authorAttribute] as? String
        let subject = attributes?[PDFDocumentAttribute.subjectAttribute] as? String
        let creator = attributes?[PDFDocumentAttribute.creatorAttribute] as? String
        let producer = attributes?[PDFDocumentAttribute.producerAttribute] as? String
        let keywords = attributes?[PDFDocumentAttribute.keywordsAttribute] as? String

        var creationDate: String? = nil
        if let date = attributes?[PDFDocumentAttribute.creationDateAttribute] as? Date {
            creationDate = DateFormatters.formatMediumDateTime(date)
        }

        var modificationDate: String? = nil
        if let date = attributes?[PDFDocumentAttribute.modificationDateAttribute] as? Date {
            modificationDate = DateFormatters.formatMediumDateTime(date)
        }

        let pageCount = pdfDocument.pageCount

        var pageSize: String? = nil
        if let firstPage = pdfDocument.page(at: 0) {
            let bounds = firstPage.bounds(for: .mediaBox)
            let width = bounds.width
            let height = bounds.height
            let widthInches = width / 72.0
            let heightInches = height / 72.0

            if abs(widthInches - 8.5) < 0.1 && abs(heightInches - 11.0) < 0.1 {
                pageSize = "Letter (8.5\" × 11\")"
            } else if abs(widthInches - 11.0) < 0.1 && abs(heightInches - 17.0) < 0.1 {
                pageSize = "Tabloid (11\" × 17\")"
            } else if abs(width - 595.0) < 2.0 && abs(height - 842.0) < 2.0 {
                pageSize = "A4 (210mm × 297mm)"
            } else if abs(width - 420.0) < 2.0 && abs(height - 595.0) < 2.0 {
                pageSize = "A5 (148mm × 210mm)"
            } else if abs(width - 842.0) < 2.0 && abs(height - 1191.0) < 2.0 {
                pageSize = "A3 (297mm × 420mm)"
            } else {
                pageSize = String(format: "%.0f × %.0f pt (%.1f\" × %.1f\")",
                                width, height, widthInches, heightInches)
            }
        }

        var version: String? = nil
        let majorVersion = pdfDocument.majorVersion
        let minorVersion = pdfDocument.minorVersion
        if majorVersion > 0 {
            version = "\(majorVersion).\(minorVersion)"
        }

        let isEncrypted = pdfDocument.isEncrypted

        let metadata = PDFMetadata(
            title: title,
            author: author,
            subject: subject,
            creator: creator,
            producer: producer,
            creationDate: creationDate,
            modificationDate: modificationDate,
            pageCount: pageCount > 0 ? pageCount : nil,
            pageSize: pageSize,
            version: version,
            isEncrypted: isEncrypted ? true : nil,
            keywords: keywords
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Office Document Metadata Extraction

    static func extractOfficeMetadata(from url: URL) -> OfficeMetadata? {
        let officeExtensions = ["docx", "doc", "xlsx", "xls", "pptx", "ppt"]
        guard let ext = url.pathExtension.lowercased() as String?,
              officeExtensions.contains(ext) else {
            return nil
        }

        guard let mdItem = MDItemCreate(kCFAllocatorDefault, url.path as CFString) else {
            return nil
        }

        let title = MDItemCopyAttribute(mdItem, kMDItemTitle) as? String

        var author: String? = nil
        if let authors = MDItemCopyAttribute(mdItem, kMDItemAuthors) as? [String], !authors.isEmpty {
            author = authors.joined(separator: ", ")
        }

        let subject = MDItemCopyAttribute(mdItem, kMDItemSubject) as? String

        var keywords: String? = nil
        if let keywordArray = MDItemCopyAttribute(mdItem, kMDItemKeywords) as? [String], !keywordArray.isEmpty {
            keywords = keywordArray.joined(separator: ", ")
        }

        let comment = MDItemCopyAttribute(mdItem, kMDItemComment) as? String
        let lastModifiedBy = MDItemCopyAttribute(mdItem, kMDItemLastUsedDate) as? String

        var creationDate: String? = nil
        if let date = MDItemCopyAttribute(mdItem, kMDItemContentCreationDate) as? Date {
            creationDate = DateFormatters.formatMediumDateTime(date)
        }

        var modificationDate: String? = nil
        if let date = MDItemCopyAttribute(mdItem, kMDItemContentModificationDate) as? Date {
            modificationDate = DateFormatters.formatMediumDateTime(date)
        }

        let pageCount = MDItemCopyAttribute(mdItem, kMDItemNumberOfPages) as? Int

        let wordCount = MDItemCopyAttribute(mdItem, kMDItemTextContent) as? String
        let actualWordCount: Int? = wordCount != nil ? wordCount!.split(separator: " ").count : nil

        var sheetCount: Int? = nil
        if ext == "xlsx" || ext == "xls" {
            sheetCount = pageCount
        }

        var slideCount: Int? = nil
        if ext == "pptx" || ext == "ppt" {
            slideCount = pageCount
        }

        let company = MDItemCopyAttribute(mdItem, kMDItemOrganizations) as? String
        let category = MDItemCopyAttribute(mdItem, kMDItemHeadline) as? String

        let metadata = OfficeMetadata(
            title: title,
            author: author,
            subject: subject,
            keywords: keywords,
            comment: comment,
            lastModifiedBy: lastModifiedBy,
            creationDate: creationDate,
            modificationDate: modificationDate,
            pageCount: (ext == "docx" || ext == "doc") ? pageCount : nil,
            wordCount: (ext == "docx" || ext == "doc") ? actualWordCount : nil,
            sheetCount: sheetCount,
            slideCount: slideCount,
            company: company,
            category: category
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - E-book Metadata Extraction

    static func extractEbookMetadata(from url: URL) -> EbookMetadata? {
        let ext = url.pathExtension.lowercased()
        let ebookExtensions = ["epub", "mobi", "azw", "azw3", "fb2", "lit", "prc"]

        guard ebookExtensions.contains(ext) else {
            return nil
        }

        if ext == "epub" {
            return extractEPUBMetadata(from: url)
        }

        return extractEbookMetadataViaMDItem(from: url)
    }

    private static func extractEPUBMetadata(from url: URL) -> EbookMetadata? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        defer {
            try? fileManager.removeItem(at: tempDir)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", url.path, "-d", tempDir.path]

        guard runProcessWithTimeout(process, timeout: 5.0) else {
            return nil
        }

        do {
            let containerPath = tempDir.appendingPathComponent("META-INF/container.xml")
            guard fileManager.fileExists(atPath: containerPath.path) else {
                return nil
            }

            let containerData = try Data(contentsOf: containerPath)
            let containerXML = try XMLDocument(data: containerData, options: [])

            guard let rootfile = try containerXML.nodes(forXPath: "//rootfile[@media-type='application/oebps-package+xml']").first as? XMLElement,
                  let opfRelativePath = rootfile.attribute(forName: "full-path")?.stringValue else {
                return nil
            }

            let opfPath = tempDir.appendingPathComponent(opfRelativePath)
            let opfData = try Data(contentsOf: opfPath)
            let opfXML = try XMLDocument(data: opfData, options: [])

            let title = try? opfXML.nodes(forXPath: "//*[local-name()='title']").first?.stringValue
            let author = try? opfXML.nodes(forXPath: "//*[local-name()='creator']").first?.stringValue
            let publisher = try? opfXML.nodes(forXPath: "//*[local-name()='publisher']").first?.stringValue
            let publicationDate = try? opfXML.nodes(forXPath: "//*[local-name()='date']").first?.stringValue
            let language = try? opfXML.nodes(forXPath: "//*[local-name()='language']").first?.stringValue
            let description = try? opfXML.nodes(forXPath: "//*[local-name()='description']").first?.stringValue

            var isbn: String? = nil
            if let identifiers = try? opfXML.nodes(forXPath: "//*[local-name()='identifier']") {
                for identifier in identifiers {
                    if let element = identifier as? XMLElement,
                       let scheme = element.attribute(forName: "scheme")?.stringValue?.lowercased(),
                       scheme.contains("isbn") {
                        isbn = element.stringValue
                        break
                    }
                    if let element = identifier as? XMLElement,
                       let value = element.stringValue,
                       value.uppercased().contains("ISBN") {
                        isbn = value
                        break
                    }
                }
            }

            return EbookMetadata(
                title: title,
                author: author,
                publisher: publisher,
                publicationDate: publicationDate,
                isbn: isbn,
                language: language,
                description: description,
                pageCount: nil
            )

        } catch {
            return nil
        }
    }

    private static func extractEbookMetadataViaMDItem(from url: URL) -> EbookMetadata? {
        guard let mdItem = MDItemCreateWithURL(kCFAllocatorDefault, url as CFURL) else {
            return nil
        }

        let title = MDItemCopyAttribute(mdItem, kMDItemTitle) as? String
        let authors = MDItemCopyAttribute(mdItem, kMDItemAuthors) as? [String]
        let author = authors?.joined(separator: ", ")
        let publisher = MDItemCopyAttribute(mdItem, kMDItemPublishers) as? [String]
        let language = MDItemCopyAttribute(mdItem, kMDItemLanguages) as? [String]
        let description = MDItemCopyAttribute(mdItem, kMDItemDescription) as? String
        let pageCount = MDItemCopyAttribute(mdItem, kMDItemNumberOfPages) as? Int

        return EbookMetadata(
            title: title,
            author: author,
            publisher: publisher?.first,
            publicationDate: nil,
            isbn: nil,
            language: language?.first,
            description: description,
            pageCount: pageCount
        )
    }

    // MARK: - Markdown Metadata Extraction

    static func extractMarkdownMetadata(from url: URL) -> MarkdownMetadata? {
        let markdownExtensions = ["md", "markdown", "mdown", "mkd"]
        let ext = url.pathExtension.lowercased()
        guard markdownExtensions.contains(ext) else { return nil }

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int64,
              fileSize < 1024 * 1024 else {
            return nil
        }

        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        var hasFrontmatter: Bool? = nil
        var frontmatterFormat: String? = nil
        var title: String? = nil

        let lines = content.components(separatedBy: .newlines)

        if lines.first == "---" {
            hasFrontmatter = true
            frontmatterFormat = "YAML"
            var inFrontmatter = true
            for (index, line) in lines.enumerated() {
                if index == 0 { continue }
                if line == "---" {
                    inFrontmatter = false
                    continue
                }
                if inFrontmatter && line.hasPrefix("title:") {
                    title = line.replacingOccurrences(of: "title:", with: "").trimmingCharacters(in: .whitespaces)
                    title = title?.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                }
            }
        } else if lines.first == "+++" {
            hasFrontmatter = true
            frontmatterFormat = "TOML"
        } else if lines.first == "{" {
            hasFrontmatter = true
            frontmatterFormat = "JSON"
        } else {
            hasFrontmatter = false
        }

        if title == nil {
            if let h1Line = lines.first(where: { $0.hasPrefix("# ") }) {
                title = h1Line.replacingOccurrences(of: "# ", with: "")
            }
        }

        var inCodeBlock = false
        var inFrontmatterBlock = hasFrontmatter == true
        var words = 0
        var headings = 0
        var codeBlocks = 0

        for (index, line) in lines.enumerated() {
            if inFrontmatterBlock {
                if (frontmatterFormat == "YAML" && line == "---" && index > 0) ||
                   (frontmatterFormat == "TOML" && line == "+++") {
                    inFrontmatterBlock = false
                }
                continue
            }

            if line.hasPrefix("```") || line.hasPrefix("~~~") {
                if !inCodeBlock {
                    codeBlocks += 1
                }
                inCodeBlock.toggle()
                continue
            }

            if !inCodeBlock {
                if line.hasPrefix("#") {
                    headings += 1
                }
                let lineWords = line.split(separator: " ").count
                words += lineWords
            }
        }

        var linkCount: Int? = nil
        let linkPattern = #"\[([^\]]+)\]\([^)]+\)"#
        if let regex = try? NSRegularExpression(pattern: linkPattern) {
            linkCount = regex.numberOfMatches(in: content, range: NSRange(content.startIndex..., in: content))
        }

        var imageCount: Int? = nil
        let imagePattern = #"!\[([^\]]*)\]\([^)]+\)"#
        if let regex = try? NSRegularExpression(pattern: imagePattern) {
            imageCount = regex.numberOfMatches(in: content, range: NSRange(content.startIndex..., in: content))
        }

        let metadata = MarkdownMetadata(
            hasFrontmatter: hasFrontmatter,
            frontmatterFormat: frontmatterFormat,
            title: title,
            wordCount: words,
            headingCount: headings,
            linkCount: linkCount,
            imageCount: imageCount,
            codeBlockCount: codeBlocks
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - HTML Metadata Extraction

    static func extractHTMLMetadata(from url: URL) -> HTMLMetadata? {
        let htmlExtensions = ["html", "htm", "xhtml"]
        let ext = url.pathExtension.lowercased()
        guard htmlExtensions.contains(ext) else { return nil }

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int64,
              fileSize < 64 * 1024 else {
            return nil
        }

        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            return nil
        }

        var title: String?
        var description: String?
        var charset: String?
        var ogTitle: String?
        var ogDescription: String?
        var ogImage: String?
        var twitterCard: String?
        var keywords: String?
        var author: String?
        var language: String?

        if let titleRange = content.range(of: #"<title[^>]*>([^<]+)</title>"#, options: .regularExpression) {
            let titleTag = String(content[titleRange])
            if let innerRange = titleTag.range(of: #">([^<]+)<"#, options: .regularExpression) {
                title = String(titleTag[innerRange]).trimmingCharacters(in: CharacterSet(charactersIn: "><"))
            }
        }

        let metaPattern = #"<meta\s+[^>]*>"#
        if let regex = try? NSRegularExpression(pattern: metaPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
            for match in matches {
                if let range = Range(match.range, in: content) {
                    let metaTag = String(content[range]).lowercased()
                    let originalTag = String(content[range])

                    func extractContent(from tag: String) -> String? {
                        if let contentRange = tag.range(of: #"content="([^"]+)""#, options: .regularExpression) {
                            let contentStr = String(tag[contentRange])
                            return contentStr.replacingOccurrences(of: "content=\"", with: "").replacingOccurrences(of: "\"", with: "")
                        }
                        return nil
                    }

                    if metaTag.contains("name=\"description\"") || metaTag.contains("name='description'") {
                        description = extractContent(from: originalTag)
                    }
                    if metaTag.contains("charset=") {
                        if let charsetRange = metaTag.range(of: #"charset="?([^"\s>]+)"?"#, options: .regularExpression) {
                            charset = String(metaTag[charsetRange]).replacingOccurrences(of: "charset=", with: "").replacingOccurrences(of: "\"", with: "")
                        }
                    }
                    if metaTag.contains("name=\"keywords\"") {
                        keywords = extractContent(from: originalTag)
                    }
                    if metaTag.contains("name=\"author\"") {
                        author = extractContent(from: originalTag)
                    }
                    if metaTag.contains("property=\"og:title\"") {
                        ogTitle = extractContent(from: originalTag)
                    }
                    if metaTag.contains("property=\"og:description\"") {
                        ogDescription = extractContent(from: originalTag)
                    }
                    if metaTag.contains("property=\"og:image\"") {
                        ogImage = extractContent(from: originalTag)
                    }
                    if metaTag.contains("name=\"twitter:card\"") {
                        twitterCard = extractContent(from: originalTag)
                    }
                }
            }
        }

        if let langRange = content.range(of: #"<html[^>]*\slang="([^"]+)""#, options: .regularExpression) {
            let langTag = String(content[langRange])
            if let innerRange = langTag.range(of: #"lang="([^"]+)""#, options: .regularExpression) {
                language = String(langTag[innerRange]).replacingOccurrences(of: "lang=\"", with: "").replacingOccurrences(of: "\"", with: "")
            }
        }

        let metadata = HTMLMetadata(
            title: title,
            description: description,
            charset: charset,
            ogTitle: ogTitle,
            ogDescription: ogDescription,
            ogImage: ogImage,
            twitterCard: twitterCard,
            keywords: keywords,
            author: author,
            language: language
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Config File Metadata Extraction

    static func extractConfigMetadata(from url: URL) -> ConfigMetadata? {
        let ext = url.pathExtension.lowercased()
        let configExtensions = ["json", "yaml", "yml", "toml"]
        guard configExtensions.contains(ext) else { return nil }

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int64,
              fileSize < 1024 * 1024 else {
            return nil
        }

        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        var format: String?
        var isValid: Bool?
        var keyCount: Int?
        var maxDepth: Int?
        var hasComments: Bool?
        let encoding = "UTF-8"

        switch ext {
        case "json":
            format = "JSON"
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    isValid = true
                    keyCount = countJSONKeys(json)
                    maxDepth = calculateJSONDepth(json)
                } else if (try JSONSerialization.jsonObject(with: data) as? [Any]) != nil {
                    isValid = true
                    keyCount = 0
                    maxDepth = 1
                }
            } catch {
                isValid = false
            }
            hasComments = false

        case "yaml", "yml":
            format = "YAML"
            let lines = content.components(separatedBy: .newlines)
            let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            let keyLines = nonEmptyLines.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.hasPrefix("#") && trimmed.contains(":") && !trimmed.hasPrefix("-")
            }
            keyCount = keyLines.count

            hasComments = nonEmptyLines.contains { $0.trimmingCharacters(in: .whitespaces).hasPrefix("#") }

            var maxIndent = 0
            for line in nonEmptyLines {
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("#") { continue }
                let indent = line.prefix(while: { $0 == " " || $0 == "\t" }).count
                maxIndent = max(maxIndent, indent)
            }
            maxDepth = (maxIndent / 2) + 1

            isValid = !content.isEmpty && keyCount! > 0

        case "toml":
            format = "TOML"
            let lines = content.components(separatedBy: .newlines)
            let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            let keyLines = nonEmptyLines.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.hasPrefix("#") && !trimmed.hasPrefix("[") && trimmed.contains("=")
            }
            keyCount = keyLines.count

            let sectionLines = nonEmptyLines.filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("[") }
            let maxSectionDepth = sectionLines.map { line -> Int in
                let dots = line.filter { $0 == "." }.count
                return dots + 1
            }.max() ?? 1
            maxDepth = maxSectionDepth

            hasComments = nonEmptyLines.contains { $0.trimmingCharacters(in: .whitespaces).hasPrefix("#") }

            isValid = !content.isEmpty

        default:
            return nil
        }

        let metadata = ConfigMetadata(
            format: format,
            isValid: isValid,
            keyCount: keyCount,
            maxDepth: maxDepth,
            hasComments: hasComments,
            encoding: encoding
        )

        return metadata.hasData ? metadata : nil
    }
}
