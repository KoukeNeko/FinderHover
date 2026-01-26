//
//  SystemMetadata.swift
//  FinderHover
//
//  System-related metadata structures (System, FileSystem, Quarantine, Link, Usage)
//

import Foundation

// MARK: - Quarantine Info Structure
struct QuarantineInfo {
    let isQuarantined: Bool
    let downloadDate: String?
    let sourceApp: String?
    let sourceURL: String?

    var hasData: Bool {
        return isQuarantined || downloadDate != nil || sourceApp != nil || sourceURL != nil
    }
}

// MARK: - Link Info Structure
struct LinkInfo {
    let isSymlink: Bool
    let symlinkTarget: String?
    let hardLinkCount: Int

    var hasData: Bool {
        return isSymlink || hardLinkCount > 1
    }
}

// MARK: - Usage Stats Structure
struct UsageStats {
    let useCount: Int?
    let lastUsedDate: String?

    var hasData: Bool {
        return useCount != nil || lastUsedDate != nil
    }
}

// MARK: - System Metadata Structure
struct SystemMetadata {
    let finderTags: [String]?
    let whereFroms: [String]?
    let quarantineInfo: QuarantineInfo?
    let linkInfo: LinkInfo?
    let usageStats: UsageStats?
    let iCloudStatus: String?
    let finderComment: String?
    let uti: String?
    let extendedAttributes: [String]?
    let aliasTarget: String?
    let isAliasFile: Bool

    var hasData: Bool {
        return (finderTags != nil && !finderTags!.isEmpty) ||
               (whereFroms != nil && !whereFroms!.isEmpty) ||
               (quarantineInfo?.hasData ?? false) ||
               (linkInfo?.hasData ?? false) ||
               (usageStats?.hasData ?? false) ||
               iCloudStatus != nil ||
               finderComment != nil ||
               uti != nil ||
               (extendedAttributes != nil && !extendedAttributes!.isEmpty) ||
               aliasTarget != nil ||
               isAliasFile
    }
}

// MARK: - File System Advanced Metadata Structure
struct FileSystemAdvancedMetadata {
    let allocatedSize: Int64?           // Actual disk blocks used
    let attributeModDate: Date?         // Attribute modification date
    let resourceForkSize: Int64?        // Resource fork size (classic Mac)
    let dataForkSize: Int64?            // Data fork size
    let volumeName: String?             // Volume name
    let volumeFormat: String?           // Volume format (APFS, HFS+, etc.)
    let volumeAvailable: Int64?         // Available space on volume
    let volumeTotal: Int64?             // Total volume capacity
    let spotlightIndexed: Bool?         // Is indexed by Spotlight
    let fileProviderName: String?       // Cloud storage provider name
    let fileProviderStatus: String?     // Cloud sync status

    var hasData: Bool {
        return allocatedSize != nil ||
               attributeModDate != nil ||
               resourceForkSize != nil ||
               dataForkSize != nil ||
               volumeName != nil ||
               volumeFormat != nil ||
               volumeAvailable != nil ||
               volumeTotal != nil ||
               spotlightIndexed != nil ||
               fileProviderName != nil ||
               fileProviderStatus != nil
    }

    /// Formatted allocated size
    var formattedAllocatedSize: String? {
        guard let size = allocatedSize else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Formatted attribute modification date
    var formattedAttributeModDate: String? {
        guard let date = attributeModDate else { return nil }
        return DateFormatters.formatShortDateTime(date)
    }

    /// Formatted resource fork size
    var formattedResourceForkSize: String? {
        guard let size = resourceForkSize, size > 0 else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Formatted volume available space
    var formattedVolumeAvailable: String? {
        guard let size = volumeAvailable else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Formatted volume total capacity
    var formattedVolumeTotal: String? {
        guard let size = volumeTotal else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Volume usage percentage
    var volumeUsagePercentage: Double? {
        guard let total = volumeTotal, let available = volumeAvailable, total > 0 else { return nil }
        return Double(total - available) / Double(total) * 100.0
    }
}
