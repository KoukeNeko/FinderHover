//
//  DocumentMetadata.swift
//  FinderHover
//
//  Document-related metadata structures (PDF, Office, Ebook, Markdown, HTML, Config)
//

import Foundation

// MARK: - PDF Metadata Structure
struct PDFMetadata {
    let title: String?
    let author: String?
    let subject: String?
    let creator: String?
    let producer: String?
    let creationDate: String?
    let modificationDate: String?
    let pageCount: Int?
    let pageSize: String?
    let version: String?
    let isEncrypted: Bool?
    let keywords: String?

    var hasData: Bool {
        return title != nil || author != nil || subject != nil ||
               creator != nil || producer != nil || creationDate != nil ||
               modificationDate != nil || pageCount != nil || pageSize != nil ||
               version != nil || isEncrypted != nil || keywords != nil
    }
}

// MARK: - Office Document Metadata Structure
struct OfficeMetadata {
    let title: String?
    let author: String?
    let subject: String?
    let keywords: String?
    let comment: String?
    let lastModifiedBy: String?
    let creationDate: String?
    let modificationDate: String?
    let pageCount: Int?        // For Word documents
    let wordCount: Int?        // For Word documents
    let sheetCount: Int?       // For Excel documents
    let slideCount: Int?       // For PowerPoint documents
    let company: String?
    let category: String?

    var hasData: Bool {
        return title != nil || author != nil || subject != nil ||
               keywords != nil || comment != nil || lastModifiedBy != nil ||
               creationDate != nil || modificationDate != nil || pageCount != nil ||
               wordCount != nil || sheetCount != nil || slideCount != nil ||
               company != nil || category != nil
    }
}

// MARK: - E-book Metadata Structure
struct EbookMetadata {
    let title: String?            // Book title
    let author: String?           // Author(s)
    let publisher: String?        // Publisher
    let publicationDate: String?  // Publication date
    let isbn: String?             // ISBN
    let language: String?         // Language
    let description: String?      // Book description/summary
    let pageCount: Int?           // Number of pages

    var hasData: Bool {
        return title != nil || author != nil || publisher != nil ||
               publicationDate != nil || isbn != nil || language != nil ||
               description != nil || pageCount != nil
    }
}

// MARK: - Markdown Metadata Structure
struct MarkdownMetadata {
    let hasFrontmatter: Bool?
    let frontmatterFormat: String? // YAML, TOML, JSON
    let title: String?             // From frontmatter or first H1
    let wordCount: Int?
    let headingCount: Int?
    let linkCount: Int?
    let imageCount: Int?
    let codeBlockCount: Int?

    var hasData: Bool {
        return hasFrontmatter != nil || frontmatterFormat != nil || title != nil ||
               wordCount != nil || headingCount != nil || linkCount != nil ||
               imageCount != nil || codeBlockCount != nil
    }
}

// MARK: - HTML Metadata Structure
struct HTMLMetadata {
    let title: String?
    let description: String?
    let charset: String?
    let ogTitle: String?           // Open Graph title
    let ogDescription: String?     // Open Graph description
    let ogImage: String?           // Open Graph image URL
    let twitterCard: String?       // Twitter card type
    let keywords: String?
    let author: String?
    let language: String?

    var hasData: Bool {
        return title != nil || description != nil || charset != nil ||
               ogTitle != nil || ogDescription != nil || ogImage != nil ||
               twitterCard != nil || keywords != nil || author != nil || language != nil
    }
}

// MARK: - Config File Metadata Structure (JSON/YAML/TOML)
struct ConfigMetadata {
    let format: String?            // JSON, YAML, TOML
    let isValid: Bool?
    let keyCount: Int?
    let maxDepth: Int?
    let hasComments: Bool?         // YAML/TOML only
    let encoding: String?

    var hasData: Bool {
        return format != nil || isValid != nil || keyCount != nil ||
               maxDepth != nil || hasComments != nil || encoding != nil
    }
}
