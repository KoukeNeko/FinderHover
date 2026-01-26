//
//  DeveloperExtractor.swift
//  FinderHover
//
//  Developer metadata extraction functions (Code, Git, Xcode, Executable, AppBundle, SQLite)
//

import Foundation
import SQLite3

// MARK: - Developer Metadata Extractor

enum DeveloperExtractor {

    // MARK: - Code File Metadata Extraction

    static func extractCodeMetadata(from url: URL) -> CodeMetadata? {
        let ext = url.pathExtension.lowercased()

        guard let language = languageFromExtension(ext) else {
            return nil
        }

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int64,
              fileSize < 5 * 1024 * 1024 else {
            return nil
        }

        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            return nil
        }

        let encoding = detectEncoding(data: data)
        let lines = content.components(separatedBy: .newlines)
        let lineCount = lines.count

        var codeLines = 0
        var commentLines = 0
        var blankLines = 0
        var inMultiLineComment = false

        let commentSyntax = getCommentSyntax(for: language)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                blankLines += 1
                continue
            }

            if let multiStart = commentSyntax.multiLineStart, let multiEnd = commentSyntax.multiLineEnd {
                if trimmed.contains(multiStart) {
                    inMultiLineComment = true
                }
                if inMultiLineComment {
                    commentLines += 1
                    if trimmed.contains(multiEnd) {
                        inMultiLineComment = false
                    }
                    continue
                }
            }

            var isComment = false
            for prefix in commentSyntax.singleLine {
                if trimmed.hasPrefix(prefix) {
                    commentLines += 1
                    isComment = true
                    break
                }
            }

            if !isComment {
                codeLines += 1
            }
        }

        return CodeMetadata(
            language: language,
            lineCount: lineCount,
            codeLines: codeLines,
            commentLines: commentLines,
            blankLines: blankLines,
            encoding: encoding
        )
    }

    // MARK: - Git Repository Metadata Extraction

    static func extractGitMetadata(from url: URL) -> GitMetadata? {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }

        let gitDir = url.appendingPathComponent(".git")
        guard FileManager.default.fileExists(atPath: gitDir.path) else {
            return nil
        }

        var branchCount: Int?
        var currentBranch: String?
        var commitCount: Int?
        var lastCommitDate: String?
        var lastCommitMessage: String?
        var remoteURL: String?
        var hasUncommittedChanges: Bool?
        var tagCount: Int?

        // Get current branch
        let branchProcess = Process()
        branchProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        branchProcess.arguments = ["-C", url.path, "branch", "--show-current"]
        let branchPipe = Pipe()
        branchProcess.standardOutput = branchPipe
        branchProcess.standardError = Pipe()

        if runProcessWithTimeout(branchProcess, timeout: 3.0) {
            let data = branchPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                currentBranch = output
            }
        }

        // Get branch count
        let branchCountProcess = Process()
        branchCountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        branchCountProcess.arguments = ["-C", url.path, "branch", "-a"]
        let branchCountPipe = Pipe()
        branchCountProcess.standardOutput = branchCountPipe
        branchCountProcess.standardError = Pipe()

        if runProcessWithTimeout(branchCountProcess, timeout: 3.0) {
            let data = branchCountPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                branchCount = output.components(separatedBy: .newlines).filter { !$0.isEmpty }.count
            }
        }

        // Get commit count
        let commitCountProcess = Process()
        commitCountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        commitCountProcess.arguments = ["-C", url.path, "rev-list", "--count", "HEAD"]
        let commitCountPipe = Pipe()
        commitCountProcess.standardOutput = commitCountPipe
        commitCountProcess.standardError = Pipe()

        if runProcessWithTimeout(commitCountProcess, timeout: 3.0) {
            let data = commitCountPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                commitCount = Int(output)
            }
        }

        // Get last commit info
        let logProcess = Process()
        logProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        logProcess.arguments = ["-C", url.path, "log", "-1", "--format=%ci|%s"]
        let logPipe = Pipe()
        logProcess.standardOutput = logPipe
        logProcess.standardError = Pipe()

        if runProcessWithTimeout(logProcess, timeout: 3.0) {
            let data = logPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                let parts = output.components(separatedBy: "|")
                if parts.count >= 1 {
                    lastCommitDate = parts[0]
                }
                if parts.count >= 2 {
                    lastCommitMessage = parts[1]
                }
            }
        }

        // Get remote URL
        let remoteProcess = Process()
        remoteProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        remoteProcess.arguments = ["-C", url.path, "remote", "get-url", "origin"]
        let remotePipe = Pipe()
        remoteProcess.standardOutput = remotePipe
        remoteProcess.standardError = Pipe()

        if runProcessWithTimeout(remoteProcess, timeout: 3.0) {
            let data = remotePipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                remoteURL = output
            }
        }

        // Check for uncommitted changes
        let statusProcess = Process()
        statusProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        statusProcess.arguments = ["-C", url.path, "status", "--porcelain"]
        let statusPipe = Pipe()
        statusProcess.standardOutput = statusPipe
        statusProcess.standardError = Pipe()

        if runProcessWithTimeout(statusProcess, timeout: 3.0) {
            let data = statusPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                hasUncommittedChanges = !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }

        // Get tag count
        let tagProcess = Process()
        tagProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        tagProcess.arguments = ["-C", url.path, "tag"]
        let tagPipe = Pipe()
        tagProcess.standardOutput = tagPipe
        tagProcess.standardError = Pipe()

        if runProcessWithTimeout(tagProcess, timeout: 3.0) {
            let data = tagPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                tagCount = output.components(separatedBy: .newlines).filter { !$0.isEmpty }.count
            }
        }

        let metadata = GitMetadata(
            branchCount: branchCount,
            currentBranch: currentBranch,
            commitCount: commitCount,
            lastCommitDate: lastCommitDate,
            lastCommitMessage: lastCommitMessage,
            remoteURL: remoteURL,
            hasUncommittedChanges: hasUncommittedChanges,
            tagCount: tagCount
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Xcode Project Metadata Extraction

    static func extractXcodeProjectMetadata(from url: URL) -> XcodeProjectMetadata? {
        let ext = url.pathExtension.lowercased()

        guard ext == "xcodeproj" || ext == "xcworkspace" else {
            return nil
        }

        var projectName: String? = nil
        var targetCount: Int? = nil
        var configurationCount: Int? = nil
        var swiftVersion: String? = nil
        var deploymentTarget: String? = nil
        var organizationName: String? = nil
        var hasTests: Bool? = nil
        var hasUITests: Bool? = nil

        projectName = url.deletingPathExtension().lastPathComponent

        if ext == "xcodeproj" {
            let pbxprojURL = url.appendingPathComponent("project.pbxproj")

            if FileManager.default.fileExists(atPath: pbxprojURL.path) {
                do {
                    let content = try String(contentsOf: pbxprojURL, encoding: .utf8)

                    let targetMatches = content.components(separatedBy: "isa = PBXNativeTarget")
                    targetCount = max(0, targetMatches.count - 1)

                    let configMatches = content.components(separatedBy: "isa = XCBuildConfiguration")
                    let configCount = max(0, configMatches.count - 1)
                    if configCount > 0 {
                        configurationCount = min(configCount, 10)
                    }

                    if let swiftRange = content.range(of: "SWIFT_VERSION = ") {
                        let startIndex = swiftRange.upperBound
                        if let endIndex = content[startIndex...].firstIndex(of: ";") {
                            let version = String(content[startIndex..<endIndex])
                                .trimmingCharacters(in: .whitespaces)
                                .replacingOccurrences(of: "\"", with: "")
                            if !version.isEmpty {
                                swiftVersion = version
                            }
                        }
                    }

                    let deploymentKeys = ["IPHONEOS_DEPLOYMENT_TARGET", "MACOSX_DEPLOYMENT_TARGET", "TVOS_DEPLOYMENT_TARGET", "WATCHOS_DEPLOYMENT_TARGET"]
                    for key in deploymentKeys {
                        if let range = content.range(of: "\(key) = ") {
                            let startIndex = range.upperBound
                            if let endIndex = content[startIndex...].firstIndex(of: ";") {
                                let target = String(content[startIndex..<endIndex])
                                    .trimmingCharacters(in: .whitespaces)
                                    .replacingOccurrences(of: "\"", with: "")
                                if !target.isEmpty {
                                    let platform = key.replacingOccurrences(of: "_DEPLOYMENT_TARGET", with: "")
                                        .replacingOccurrences(of: "OS", with: "OS ")
                                        .capitalized
                                    deploymentTarget = "\(platform) \(target)"
                                    break
                                }
                            }
                        }
                    }

                    if let orgRange = content.range(of: "ORGANIZATIONNAME = ") {
                        let startIndex = orgRange.upperBound
                        if let endIndex = content[startIndex...].firstIndex(of: ";") {
                            let org = String(content[startIndex..<endIndex])
                                .trimmingCharacters(in: .whitespaces)
                                .replacingOccurrences(of: "\"", with: "")
                            if !org.isEmpty {
                                organizationName = org
                            }
                        }
                    }

                    hasTests = content.contains("productType = \"com.apple.product-type.bundle.unit-test\"")
                    hasUITests = content.contains("productType = \"com.apple.product-type.bundle.ui-testing\"")

                } catch {
                    Logger.debug("Failed to parse pbxproj: \(error.localizedDescription)", subsystem: .fileSystem)
                }
            }
        } else if ext == "xcworkspace" {
            let contentsURL = url.appendingPathComponent("contents.xcworkspacedata")

            if FileManager.default.fileExists(atPath: contentsURL.path) {
                do {
                    let content = try String(contentsOf: contentsURL, encoding: .utf8)
                    let fileRefMatches = content.components(separatedBy: "<FileRef")
                    targetCount = max(0, fileRefMatches.count - 1)
                } catch {
                    Logger.debug("Failed to parse workspace: \(error.localizedDescription)", subsystem: .fileSystem)
                }
            }
        }

        let metadata = XcodeProjectMetadata(
            projectName: projectName,
            targetCount: targetCount,
            configurationCount: configurationCount,
            swiftVersion: swiftVersion,
            deploymentTarget: deploymentTarget,
            organizationName: organizationName,
            hasTests: hasTests,
            hasUITests: hasUITests
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - Executable Metadata Extraction

    static func extractExecutableMetadata(from url: URL) -> ExecutableMetadata? {
        let fileManager = FileManager.default
        guard fileManager.isExecutableFile(atPath: url.path) else { return nil }

        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue else {
            return nil
        }

        let scriptExtensions = ["sh", "bash", "zsh", "py", "rb", "pl", "js", "ts"]
        if scriptExtensions.contains(url.pathExtension.lowercased()) {
            return nil
        }

        var architecture: String?
        var isCodeSigned: Bool?
        var signingAuthority: String?
        var minimumOS: String?
        var sdkVersion: String?
        var fileType: String?

        let fileProcess = Process()
        fileProcess.executableURL = URL(fileURLWithPath: "/usr/bin/file")
        fileProcess.arguments = ["-b", url.path]
        let filePipe = Pipe()
        fileProcess.standardOutput = filePipe
        fileProcess.standardError = Pipe()

        if runProcessWithTimeout(fileProcess, timeout: 3.0) {
            let fileData = filePipe.fileHandleForReading.readDataToEndOfFile()
            if let fileOutput = String(data: fileData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if fileOutput.contains("Mach-O") {
                    if fileOutput.contains("universal") || fileOutput.contains("fat") {
                        architecture = "Universal"
                    } else if fileOutput.contains("arm64") {
                        architecture = "arm64"
                    } else if fileOutput.contains("x86_64") {
                        architecture = "x86_64"
                    }

                    if fileOutput.contains("executable") {
                        fileType = "Mach-O Executable"
                    } else if fileOutput.contains("dynamically linked shared library") {
                        fileType = "Dynamic Library"
                    } else if fileOutput.contains("bundle") {
                        fileType = "Mach-O Bundle"
                    }
                } else {
                    return nil
                }
            }
        }

        let codesignProcess = Process()
        codesignProcess.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        codesignProcess.arguments = ["-dv", url.path]
        let codesignPipe = Pipe()
        let codesignErrorPipe = Pipe()
        codesignProcess.standardOutput = codesignPipe
        codesignProcess.standardError = codesignErrorPipe

        if runProcessWithTimeout(codesignProcess, timeout: 3.0) {
            let errorData = codesignErrorPipe.fileHandleForReading.readDataToEndOfFile()
            if let errorOutput = String(data: errorData, encoding: .utf8) {
                isCodeSigned = !errorOutput.contains("not signed")

                if let authorityRange = errorOutput.range(of: #"Authority=([^\n]+)"#, options: .regularExpression) {
                    signingAuthority = String(errorOutput[authorityRange])
                        .replacingOccurrences(of: "Authority=", with: "")
                        .trimmingCharacters(in: .whitespaces)
                }
            }
        } else {
            isCodeSigned = false
        }

        let otoolProcess = Process()
        otoolProcess.executableURL = URL(fileURLWithPath: "/usr/bin/otool")
        otoolProcess.arguments = ["-l", url.path]
        let otoolPipe = Pipe()
        otoolProcess.standardOutput = otoolPipe
        otoolProcess.standardError = Pipe()

        if runProcessWithTimeout(otoolProcess, timeout: 3.0) {
            let otoolData = otoolPipe.fileHandleForReading.readDataToEndOfFile()
            if let otoolOutput = String(data: otoolData, encoding: .utf8) {
                if let minVersionRange = otoolOutput.range(of: #"minos\s+([\d.]+)"#, options: .regularExpression) {
                    let match = String(otoolOutput[minVersionRange])
                    minimumOS = match.components(separatedBy: .whitespaces).last
                }

                if let sdkRange = otoolOutput.range(of: #"sdk\s+([\d.]+)"#, options: .regularExpression) {
                    let match = String(otoolOutput[sdkRange])
                    sdkVersion = match.components(separatedBy: .whitespaces).last
                }
            }
        }

        let metadata = ExecutableMetadata(
            architecture: architecture,
            isCodeSigned: isCodeSigned,
            signingAuthority: signingAuthority,
            minimumOS: minimumOS,
            sdkVersion: sdkVersion,
            fileType: fileType
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - App Bundle Metadata Extraction

    static func extractAppBundleMetadata(from url: URL) -> AppBundleMetadata? {
        guard url.pathExtension.lowercased() == "app" else { return nil }

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }

        let infoPlistPath = url.appendingPathComponent("Contents/Info.plist")
        guard let plistData = try? Data(contentsOf: infoPlistPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }

        let bundleID = plist["CFBundleIdentifier"] as? String
        let version = plist["CFBundleShortVersionString"] as? String
        let buildNumber = plist["CFBundleVersion"] as? String
        let minimumOS = plist["LSMinimumSystemVersion"] as? String
        let category = plist["LSApplicationCategoryType"] as? String
        let copyright = plist["NSHumanReadableCopyright"] as? String

        var isCodeSigned: Bool?
        let codesignProcess = Process()
        codesignProcess.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        codesignProcess.arguments = ["-dv", url.path]
        let codesignPipe = Pipe()
        codesignProcess.standardOutput = codesignPipe
        codesignProcess.standardError = codesignPipe

        if runProcessWithTimeout(codesignProcess, timeout: 3.0) {
            let data = codesignPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                isCodeSigned = !output.contains("not signed")
            }
        }

        var hasEntitlements: Bool?
        let entitlementsProcess = Process()
        entitlementsProcess.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        entitlementsProcess.arguments = ["-d", "--entitlements", "-", url.path]
        let entitlementsPipe = Pipe()
        entitlementsProcess.standardOutput = entitlementsPipe
        entitlementsProcess.standardError = Pipe()

        if runProcessWithTimeout(entitlementsProcess, timeout: 3.0) {
            let data = entitlementsPipe.fileHandleForReading.readDataToEndOfFile()
            hasEntitlements = data.count > 100
        }

        let metadata = AppBundleMetadata(
            bundleID: bundleID,
            version: version,
            buildNumber: buildNumber,
            minimumOS: minimumOS,
            category: category,
            copyright: copyright,
            isCodeSigned: isCodeSigned,
            hasEntitlements: hasEntitlements
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - SQLite Metadata Extraction

    static func extractSQLiteMetadata(from url: URL) -> SQLiteMetadata? {
        let sqliteExtensions = ["db", "sqlite", "sqlite3", "db3"]
        let ext = url.pathExtension.lowercased()
        guard sqliteExtensions.contains(ext) else { return nil }

        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              data.count >= 16 else {
            return nil
        }

        let magic = String(data: data.prefix(16), encoding: .utf8)
        guard magic?.hasPrefix("SQLite format") == true else {
            return nil
        }

        var db: OpaquePointer?

        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return nil
        }

        defer {
            sqlite3_close(db)
        }

        func queryInt(_ sql: String) -> Int? {
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return nil
            }
            defer { sqlite3_finalize(statement) }

            if sqlite3_step(statement) == SQLITE_ROW {
                return Int(sqlite3_column_int64(statement, 0))
            }
            return nil
        }

        func queryString(_ sql: String) -> String? {
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return nil
            }
            defer { sqlite3_finalize(statement) }

            if sqlite3_step(statement) == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    return String(cString: cString)
                }
            }
            return nil
        }

        let tableCount = queryInt("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
        let indexCount = queryInt("SELECT COUNT(*) FROM sqlite_master WHERE type='index'")
        let triggerCount = queryInt("SELECT COUNT(*) FROM sqlite_master WHERE type='trigger'")
        let viewCount = queryInt("SELECT COUNT(*) FROM sqlite_master WHERE type='view'")
        let schemaVersion = queryInt("PRAGMA schema_version")
        let pageSize = queryInt("PRAGMA page_size")
        let encoding = queryString("PRAGMA encoding")

        let metadata = SQLiteMetadata(
            tableCount: tableCount,
            indexCount: indexCount,
            triggerCount: triggerCount,
            viewCount: viewCount,
            totalRows: nil,
            schemaVersion: schemaVersion,
            pageSize: pageSize,
            encoding: encoding
        )

        return metadata.hasData ? metadata : nil
    }
}
