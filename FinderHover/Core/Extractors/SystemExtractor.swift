//
//  SystemExtractor.swift
//  FinderHover
//
//  System-related metadata extraction (System, FileSystemAdvanced)
//

import Foundation
import UniformTypeIdentifiers

// MARK: - System Metadata Extractor

enum SystemExtractor {

    // MARK: - System Metadata Extraction

    static func extractSystemMetadata(from url: URL) -> SystemMetadata? {
        var finderTags: [String]? = nil
        var whereFroms: [String]? = nil
        var quarantineInfo: QuarantineInfo? = nil
        var linkInfo: LinkInfo? = nil
        var usageStats: UsageStats? = nil
        var iCloudStatus: String? = nil
        var finderComment: String? = nil
        var uti: String? = nil
        var extendedAttributes: [String]? = nil
        var aliasTarget: String? = nil
        var isAliasFile = false

        // Extract Finder Tags
        do {
            let resourceValues = try url.resourceValues(forKeys: [.tagNamesKey])
            if let tags = resourceValues.tagNames, !tags.isEmpty {
                finderTags = tags
            }
        } catch {
            Logger.debug("Failed to extract Finder tags: \(error.localizedDescription)", subsystem: .fileSystem)
        }

        // Extract UTI
        do {
            let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
            if let contentType = resourceValues.contentType {
                uti = contentType.identifier
            }
        } catch {
            Logger.debug("Failed to extract UTI: \(error.localizedDescription)", subsystem: .fileSystem)
        }

        // Check alias file
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isAliasFileKey])
            isAliasFile = resourceValues.isAliasFile ?? false

            if isAliasFile {
                do {
                    let originalURL = try URL(resolvingAliasFileAt: url, options: [.withoutUI, .withoutMounting])
                    aliasTarget = originalURL.path
                } catch {
                    Logger.debug("Failed to resolve alias: \(error.localizedDescription)", subsystem: .fileSystem)
                }
            }
        } catch {
            Logger.debug("Failed to check alias status: \(error.localizedDescription)", subsystem: .fileSystem)
        }

        // Extract iCloud status
        do {
            let resourceValues = try url.resourceValues(forKeys: [
                .isUbiquitousItemKey,
                .ubiquitousItemDownloadingStatusKey,
                .ubiquitousItemIsUploadedKey,
                .ubiquitousItemIsUploadingKey,
                .ubiquitousItemIsDownloadingKey
            ])

            if resourceValues.isUbiquitousItem == true {
                if let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus {
                    if downloadStatus == .current || downloadStatus == .downloaded {
                        iCloudStatus = "iCloud.downloaded".localized
                    } else if downloadStatus == .notDownloaded {
                        iCloudStatus = "iCloud.cloudOnly".localized
                    } else {
                        iCloudStatus = "iCloud.unknown".localized
                    }
                }
                if resourceValues.ubiquitousItemIsDownloading == true {
                    iCloudStatus = "iCloud.downloading".localized
                }
                if resourceValues.ubiquitousItemIsUploading == true {
                    iCloudStatus = "iCloud.uploading".localized
                }
            }
        } catch {
            Logger.debug("Failed to extract iCloud status: \(error.localizedDescription)", subsystem: .fileSystem)
        }

        // Extract Link Info
        let path = url.path
        var statInfo = stat()
        if lstat(path, &statInfo) == 0 {
            let isSymlink = (statInfo.st_mode & S_IFMT) == S_IFLNK
            var symlinkTarget: String? = nil

            if isSymlink {
                var buffer = [CChar](repeating: 0, count: Int(PATH_MAX))
                let length = readlink(path, &buffer, Int(PATH_MAX))
                if length > 0 {
                    symlinkTarget = String(cString: buffer)
                }
            }

            let hardLinkCount = Int(statInfo.st_nlink)

            linkInfo = LinkInfo(
                isSymlink: isSymlink,
                symlinkTarget: symlinkTarget,
                hardLinkCount: hardLinkCount
            )
        }

        // Extract Extended Attributes
        let xattrLength = listxattr(path, nil, 0, 0)
        if xattrLength > 0 {
            var buffer = [CChar](repeating: 0, count: xattrLength)
            let result = listxattr(path, &buffer, xattrLength, 0)
            if result > 0 {
                let xattrString = String(cString: buffer)
                let attrs = xattrString.split(separator: "\0").map { String($0) }
                if !attrs.isEmpty {
                    extendedAttributes = attrs
                }
            }
        }

        // Extract Quarantine Info
        var quarantineBuffer = [CChar](repeating: 0, count: 1024)
        let quarantineLength = getxattr(path, "com.apple.quarantine", &quarantineBuffer, 1024, 0, 0)
        if quarantineLength > 0 {
            let quarantineString = String(cString: quarantineBuffer)
            let components = quarantineString.split(separator: ";")
            var downloadDate: String? = nil
            var sourceApp: String? = nil

            if components.count >= 2 {
                if let timestampHex = Int(components[1], radix: 16) {
                    let date = Date(timeIntervalSinceReferenceDate: TimeInterval(timestampHex))
                    downloadDate = DateFormatters.formatShortDateTime(date)
                }
            }
            if components.count >= 3 {
                sourceApp = String(components[2])
            }

            quarantineInfo = QuarantineInfo(
                isQuarantined: true,
                downloadDate: downloadDate,
                sourceApp: sourceApp,
                sourceURL: nil
            )
        }

        // Extract Where From using Spotlight
        if let mdItem = MDItemCreateWithURL(nil, url as CFURL) {
            if let whereFromsArray = MDItemCopyAttribute(mdItem, kMDItemWhereFroms) as? [String], !whereFromsArray.isEmpty {
                whereFroms = whereFromsArray
            }

            if let comment = MDItemCopyAttribute(mdItem, kMDItemFinderComment) as? String, !comment.isEmpty {
                finderComment = comment
            }

            let useCount = MDItemCopyAttribute(mdItem, "kMDItemUseCount" as CFString) as? Int
            var lastUsedDate: String? = nil
            if let date = MDItemCopyAttribute(mdItem, kMDItemLastUsedDate) as? Date {
                lastUsedDate = DateFormatters.formatShortDateTime(date)
            }

            if useCount != nil || lastUsedDate != nil {
                usageStats = UsageStats(useCount: useCount, lastUsedDate: lastUsedDate)
            }
        }

        let metadata = SystemMetadata(
            finderTags: finderTags,
            whereFroms: whereFroms,
            quarantineInfo: quarantineInfo,
            linkInfo: linkInfo,
            usageStats: usageStats,
            iCloudStatus: iCloudStatus,
            finderComment: finderComment,
            uti: uti,
            extendedAttributes: extendedAttributes,
            aliasTarget: aliasTarget,
            isAliasFile: isAliasFile
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - File System Advanced Metadata Extraction

    static func extractFileSystemAdvancedMetadata(from url: URL) -> FileSystemAdvancedMetadata? {
        var allocatedSize: Int64? = nil
        var attributeModDate: Date? = nil
        var resourceForkSize: Int64? = nil
        var dataForkSize: Int64? = nil
        var volumeName: String? = nil
        var volumeFormat: String? = nil
        var volumeAvailable: Int64? = nil
        var volumeTotal: Int64? = nil
        var spotlightIndexed: Bool? = nil
        var fileProviderName: String? = nil
        var fileProviderStatus: String? = nil

        // Extract allocated size
        do {
            let resourceValues = try url.resourceValues(forKeys: [
                .totalFileAllocatedSizeKey,
                .fileSizeKey,
                .totalFileSizeKey
            ])
            if let allocated = resourceValues.totalFileAllocatedSize {
                allocatedSize = Int64(allocated)
            }
            if let fileSize = resourceValues.fileSize {
                dataForkSize = Int64(fileSize)
            }
        } catch {
            Logger.debug("Failed to extract allocated size: \(error.localizedDescription)", subsystem: .fileSystem)
        }

        // Extract volume information
        do {
            let resourceValues = try url.resourceValues(forKeys: [
                .volumeNameKey,
                .volumeLocalizedFormatDescriptionKey,
                .volumeAvailableCapacityKey,
                .volumeTotalCapacityKey
            ])
            volumeName = resourceValues.volumeName
            volumeFormat = resourceValues.volumeLocalizedFormatDescription
            if let available = resourceValues.volumeAvailableCapacity {
                volumeAvailable = Int64(available)
            }
            if let total = resourceValues.volumeTotalCapacity {
                volumeTotal = Int64(total)
            }
        } catch {
            Logger.debug("Failed to extract volume info: \(error.localizedDescription)", subsystem: .fileSystem)
        }

        // Extract attribute modification date
        let path = url.path
        var statInfo = stat()
        if stat(path, &statInfo) == 0 {
            let ctimeSeconds = statInfo.st_ctimespec.tv_sec
            attributeModDate = Date(timeIntervalSince1970: TimeInterval(ctimeSeconds))
        }

        // Extract resource fork size
        let resourceForkPath = path + "/..namedfork/rsrc"
        var rsrcStat = stat()
        if stat(resourceForkPath, &rsrcStat) == 0 {
            let size = rsrcStat.st_size
            if size > 0 {
                resourceForkSize = Int64(size)
            }
        }

        // Check Spotlight indexing
        if let mdItem = MDItemCreateWithURL(nil, url as CFURL) {
            spotlightIndexed = true
        } else {
            spotlightIndexed = false
        }

        // Extract file provider information
        do {
            let resourceValues = try url.resourceValues(forKeys: [
                .ubiquitousItemContainerDisplayNameKey,
                .ubiquitousItemDownloadingStatusKey,
                .isUbiquitousItemKey
            ])

            if resourceValues.isUbiquitousItem == true {
                if let containerName = resourceValues.ubiquitousItemContainerDisplayName {
                    fileProviderName = containerName
                }

                if let status = resourceValues.ubiquitousItemDownloadingStatus {
                    switch status {
                    case .current, .downloaded:
                        fileProviderStatus = "fileProvider.downloaded".localized
                    case .notDownloaded:
                        fileProviderStatus = "fileProvider.cloudOnly".localized
                    default:
                        fileProviderStatus = "fileProvider.unknown".localized
                    }
                }
            }
        } catch {
            Logger.debug("Failed to extract file provider info: \(error.localizedDescription)", subsystem: .fileSystem)
        }

        // Check for third-party file providers
        if fileProviderName == nil {
            let pathComponents = url.pathComponents

            if pathComponents.contains("Dropbox") {
                fileProviderName = "Dropbox"
            } else if pathComponents.contains("Google Drive") || pathComponents.contains("GoogleDrive") {
                fileProviderName = "Google Drive"
            } else if pathComponents.contains("OneDrive") {
                fileProviderName = "OneDrive"
            } else if pathComponents.contains("Box") {
                fileProviderName = "Box"
            }
        }

        let metadata = FileSystemAdvancedMetadata(
            allocatedSize: allocatedSize,
            attributeModDate: attributeModDate,
            resourceForkSize: resourceForkSize,
            dataForkSize: dataForkSize,
            volumeName: volumeName,
            volumeFormat: volumeFormat,
            volumeAvailable: volumeAvailable,
            volumeTotal: volumeTotal,
            spotlightIndexed: spotlightIndexed,
            fileProviderName: fileProviderName,
            fileProviderStatus: fileProviderStatus
        )

        return metadata.hasData ? metadata : nil
    }
}
