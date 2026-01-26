//
//  ArchiveMetadata.swift
//  FinderHover
//
//  Archive-related metadata structures (Archive, Disk Image)
//

import Foundation

// MARK: - Archive Metadata Structure
struct ArchiveMetadata {
    let format: String?           // ZIP, RAR, 7Z, TAR, GZ, etc.
    let fileCount: Int?           // Number of files in archive
    let uncompressedSize: UInt64? // Total uncompressed size
    let compressionRatio: Double? // Compression ratio percentage
    let isEncrypted: Bool?        // Whether archive is password protected
    let comment: String?          // Archive comment (ZIP)

    var hasData: Bool {
        return format != nil || fileCount != nil || uncompressedSize != nil ||
               compressionRatio != nil || isEncrypted != nil || comment != nil
    }
}

// MARK: - Disk Image Metadata Structure
struct DiskImageMetadata {
    let format: String?           // Image format (UDIF, UDZO, UDBZ, ISO 9660, etc.)
    let totalSize: Int64?         // Total size in bytes
    let compressedSize: Int64?    // Compressed size in bytes (if applicable)
    let compressionRatio: String? // Compression ratio (e.g., "2.5:1")
    let isEncrypted: Bool?        // Whether the image is encrypted
    let partitionScheme: String?  // Partition scheme (GPT, APM, MBR, etc.)
    let fileSystem: String?       // File system (HFS+, APFS, ISO 9660, etc.)

    var hasData: Bool {
        return format != nil || totalSize != nil || compressedSize != nil ||
               compressionRatio != nil || isEncrypted != nil || partitionScheme != nil || fileSystem != nil
    }
}
