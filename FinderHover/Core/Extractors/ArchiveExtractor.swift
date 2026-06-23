//
//  ArchiveExtractor.swift
//  FinderHover
//
//  Archive-related metadata extraction (Archive, DiskImage)
//

import Foundation

// MARK: - Archive Metadata Extractor

enum ArchiveExtractor {

    // MARK: - Archive Metadata Extraction

    static func extractArchiveMetadata(from url: URL) -> ArchiveMetadata? {
        let archiveExtensions = ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "tgz", "tbz2", "txz", "tar.gz", "tar.bz2", "tar.xz"]
        let ext = url.pathExtension.lowercased()

        let fileName = url.deletingPathExtension().lastPathComponent
        let doubleExt = fileName.contains(".") ? "\(fileName.split(separator: ".").last!).\(ext)" : ext

        guard archiveExtensions.contains(ext) || archiveExtensions.contains(doubleExt) else {
            return nil
        }

        // Determine format
        var format: String? = nil
        if ext == "zip" {
            format = "ZIP"
        } else if ext == "rar" {
            format = "RAR"
        } else if ext == "7z" {
            format = "7-Zip"
        } else if ext == "tar" || doubleExt.hasPrefix("tar.") {
            if doubleExt.hasSuffix(".gz") || ext == "tgz" {
                format = "TAR.GZ"
            } else if doubleExt.hasSuffix(".bz2") || ext == "tbz2" {
                format = "TAR.BZ2"
            } else if doubleExt.hasSuffix(".xz") || ext == "txz" {
                format = "TAR.XZ"
            } else {
                format = "TAR"
            }
        } else if ext == "gz" {
            format = "GZIP"
        } else if ext == "bz2" {
            format = "BZIP2"
        } else if ext == "xz" {
            format = "XZ"
        }

        var fileCount: Int? = nil
        var uncompressedSize: Int64? = nil
        var isEncrypted: Bool? = nil
        let comment: String? = nil

        if ext == "zip" {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/zipinfo")
            process.arguments = ["-t", url.path]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()

            if runProcessWithTimeout(process, timeout: 3.0) {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: .newlines)
                    for line in lines {
                        if line.contains("files,") {
                            if let countMatch = line.split(separator: " ").first,
                               let count = Int(countMatch) {
                                fileCount = count
                            }

                            let components = line.components(separatedBy: " ")
                            if let uncompIndex = components.firstIndex(of: "bytes"), uncompIndex > 0,
                               let size = Int64(components[uncompIndex - 1].replacingOccurrences(of: ",", with: "")) {
                                uncompressedSize = size
                            }
                        }
                    }
                }
            }

            // Check for encryption via the verbose central-directory listing.
            // `unzip -Z -v` prints a per-entry table; each entry has a
            // "file security status:" line whose value is "encrypted" or
            // "not encrypted". `unzip -Z -1` only lists names and exits 0 even
            // on encrypted archives, so it can never reveal encryption.
            // Match only the security-status line and exclude "not encrypted",
            // because that string also contains the substring "encrypted".
            let listProcess = Process()
            listProcess.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            listProcess.arguments = ["-Z", "-v", url.path]

            let listPipe = Pipe()
            listProcess.standardOutput = listPipe
            listProcess.standardError = Pipe()

            if runProcessWithTimeout(listProcess, timeout: 3.0) {
                let listData = listPipe.fileHandleForReading.readDataToEndOfFile()
                if let listOutput = String(data: listData, encoding: .utf8) {
                    let hasEncryptedEntry = listOutput
                        .components(separatedBy: .newlines)
                        .contains { line in
                            let lowered = line.lowercased()
                            return lowered.contains("security status:")
                                && lowered.contains("encrypted")
                                && !lowered.contains("not encrypted")
                        }
                    if hasEncryptedEntry {
                        isEncrypted = true
                    }
                }
            }

        } else if doubleExt.hasPrefix("tar") || ext == "tar" || ext == "tgz" || ext == "tbz2" || ext == "txz" {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")

            var tarArgs = ["-t"]
            if ext == "gz" || ext == "tgz" || doubleExt.hasSuffix(".gz") {
                tarArgs.append("-z")
            } else if ext == "bz2" || ext == "tbz2" || doubleExt.hasSuffix(".bz2") {
                tarArgs.append("-j")
            } else if ext == "xz" || ext == "txz" || doubleExt.hasSuffix(".xz") {
                tarArgs.append("-J")
            }
            tarArgs.append(contentsOf: ["-f", url.path])

            process.arguments = tarArgs

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()

            if runProcessWithTimeout(process, timeout: 5.0) {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let files = output.components(separatedBy: .newlines).filter { !$0.isEmpty && !$0.hasSuffix("/") }
                    fileCount = files.count
                }
            }
        }

        // Calculate compression ratio
        var compressionRatio: Double? = nil
        if let uncompSize = uncompressedSize, uncompSize > 0 {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let compressedSize = attributes[.size] as? Int64, compressedSize > 0 {
                    compressionRatio = (1.0 - Double(compressedSize) / Double(uncompSize)) * 100.0
                }
            } catch {
                // Silently fail
            }
        }

        let metadata = ArchiveMetadata(
            format: format,
            fileCount: fileCount,
            uncompressedSize: uncompressedSize,
            compressionRatio: compressionRatio,
            isEncrypted: isEncrypted,
            comment: comment
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Disk Image Metadata Extraction

    static func extractDiskImageMetadata(from url: URL) -> DiskImageMetadata? {
        let diskImageExtensions = ["dmg", "iso", "img", "sparseimage", "sparsebundle"]
        let ext = url.pathExtension.lowercased()

        guard diskImageExtensions.contains(ext) else {
            return nil
        }

        var format: String? = nil
        var totalSize: Int64? = nil
        var compressedSize: Int64? = nil
        var compressionRatio: Double? = nil
        var isEncrypted: Bool? = nil
        var partitionScheme: String? = nil
        let fileSystem: String? = nil

        // Get file size as compressed size
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            compressedSize = size
        }

        // Use hdiutil to get disk image info
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["imageinfo", url.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        if runProcessWithTimeout(process, timeout: 5.0) {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)

                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)

                    if trimmed.hasPrefix("Format:") {
                        format = trimmed.replacingOccurrences(of: "Format:", with: "").trimmingCharacters(in: .whitespaces)
                    } else if trimmed.hasPrefix("Total Bytes:") {
                        if let sizeStr = trimmed.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces),
                           let size = Int64(sizeStr) {
                            totalSize = size
                        }
                    } else if trimmed.hasPrefix("Encrypted:") {
                        isEncrypted = trimmed.lowercased().contains("true") || trimmed.lowercased().contains("yes")
                    } else if trimmed.hasPrefix("Partition Type:") {
                        partitionScheme = trimmed.replacingOccurrences(of: "Partition Type:", with: "").trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }

        // Calculate compression ratio
        if let total = totalSize, let compressed = compressedSize, compressed > 0 {
            compressionRatio = Double(total) / Double(compressed)
        }

        // Determine format from extension if not found
        if format == nil {
            switch ext {
            case "dmg":
                format = "Apple Disk Image"
            case "iso":
                format = "ISO 9660"
            case "img":
                format = "Disk Image"
            case "sparseimage":
                format = "Sparse Image"
            case "sparsebundle":
                format = "Sparse Bundle"
            default:
                format = ext.uppercased()
            }
        }

        let metadata = DiskImageMetadata(
            format: format,
            totalSize: totalSize,
            compressedSize: compressedSize,
            compressionRatio: compressionRatio,
            isEncrypted: isEncrypted,
            partitionScheme: partitionScheme,
            fileSystem: fileSystem
        )

        return metadata.hasData ? metadata : nil
    }
}
