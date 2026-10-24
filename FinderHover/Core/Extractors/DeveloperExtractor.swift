//
//  DeveloperExtractor.swift
//  FinderHover
//
//  Developer metadata extraction functions (Code, Git, Xcode, Executable, AppBundle, SQLite)
//

import Foundation
import SQLite3

// MARK: - Developer Metadata Extractor

nonisolated enum DeveloperExtractor {

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
            classifyLine(
                line,
                syntax: commentSyntax,
                inMultiLineComment: &inMultiLineComment,
                blankLines: &blankLines,
                commentLines: &commentLines,
                codeLines: &codeLines
            )
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

    /// Classifies one source line as blank / comment / code, updating the
    /// running totals and the multi-line-comment state. The scan walks the
    /// trimmed line so that delimiters appearing inside string literals do not
    /// flip comment state, and a line that contains both code and a comment is
    /// counted as code.
    private static func classifyLine(
        _ line: String,
        syntax: CommentSyntax,
        inMultiLineComment: inout Bool,
        blankLines: inout Int,
        commentLines: inout Int,
        codeLines: inout Int
    ) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            blankLines += 1
            return
        }

        let scalars = Array(trimmed)
        var index = 0
        var sawCode = false
        var sawComment = false
        var inStringLiteral = false
        var stringDelimiter: Character = "\""

        func matches(_ token: String, at position: Int) -> Bool {
            let tokenChars = Array(token)
            guard position + tokenChars.count <= scalars.count else { return false }
            for offset in 0..<tokenChars.count where scalars[position + offset] != tokenChars[offset] {
                return false
            }
            return true
        }

        while index < scalars.count {
            let character = scalars[index]

            if inMultiLineComment {
                sawComment = true
                if let end = syntax.multiLineEnd, matches(end, at: index) {
                    inMultiLineComment = false
                    index += end.count
                    continue
                }
                index += 1
                continue
            }

            if inStringLiteral {
                if character == "\\" {
                    index += 2 // skip escaped char
                    continue
                }
                if character == stringDelimiter {
                    inStringLiteral = false
                }
                index += 1
                continue
            }

            if let start = syntax.multiLineStart, matches(start, at: index) {
                inMultiLineComment = true
                index += start.count
                continue
            }

            if syntax.singleLine.contains(where: { matches($0, at: index) }) {
                sawComment = true
                break // rest of line is a comment
            }

            if character == "\"" || character == "'" {
                inStringLiteral = true
                stringDelimiter = character
                sawCode = true
                index += 1
                continue
            }

            sawCode = true
            index += 1
        }

        if sawCode {
            codeLines += 1
        } else if sawComment {
            commentLines += 1
        }
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

        // The repository's own config (local and per-worktree files, with their includes) is
        // untrusted: it can name programs that git runs during `status` (fsmonitor, clean
        // filters). Skip `status` when it defines any, or when the config can't be read.
        let config = git(["config", "--list", "--show-scope", "--includes"], in: url)
        let entries = (config ?? "").split(separator: "\n").compactMap { line -> (scope: Substring, key: String, value: Substring)? in
            let scoped = line.split(separator: "\t", maxSplits: 1)
            guard scoped.count == 2 else { return nil }
            let pair = scoped[1].split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            return (scoped[0], pair[0].lowercased(), pair.count > 1 ? pair[1] : "")
        }
        let runsPrograms = config == nil || entries.contains { entry in
            (entry.scope == "local" || entry.scope == "worktree")
                && (entry.key.hasPrefix("filter.") || entry.key == "core.fsmonitor")
        }
        remoteURL = entries.last { $0.key == "remote.origin.url" }.map { String($0.value) }

        if !runsPrograms, let status = git(["status", "--porcelain=v2", "--branch", "--ignore-submodules"], in: url) {
            let lines = status.split(separator: "\n")
            if let head = lines.first(where: { $0.hasPrefix("# branch.head ") })?.dropFirst("# branch.head ".count),
               head != "(detached)" {
                currentBranch = String(head)
            }
            hasUncommittedChanges = lines.contains { !$0.hasPrefix("#") }
        } else if let branch = git(["branch", "--show-current"], in: url)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !branch.isEmpty {
            currentBranch = branch
        }

        if let refs = git(["for-each-ref", "--format=%(refname)"], in: url) {
            let names = refs.split(separator: "\n")
            branchCount = names.filter { $0.hasPrefix("refs/heads/") || $0.hasPrefix("refs/remotes/") }.count
            tagCount = names.filter { $0.hasPrefix("refs/tags/") }.count
        }

        if let count = git(["rev-list", "--count", "HEAD"], in: url)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            commitCount = Int(count)
        }

        if let log = git(["log", "-1", "--format=%ci|%s"], in: url)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            let parts = log.split(separator: "|", maxSplits: 1).map(String.init)
            lastCommitDate = parts.first
            lastCommitMessage = parts.count > 1 ? parts[1] : nil
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

    /// Runs a read-only git command in `url` with settings that would launch programs
    /// (fsmonitor, signature verification) forced off and no optional index lock taken.
    private static func git(_ arguments: [String], in url: URL) -> String? {
        runCommand("/usr/bin/git", [
            "--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "log.showSignature=false",
            "-C", url.path
        ] + arguments)
    }

    // MARK: - Xcode Project Metadata Extraction

    static func extractXcodeProjectMetadata(
        from url: URL,
        policy: FileInfo.MetadataExtractionPolicy = .default,
        noticeRecorder: ((FileInfo.AnalysisNotice) -> Void)? = nil
    ) -> XcodeProjectMetadata? {
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
                    if policy.enableLargeFileProtection,
                       let attrs = try? FileManager.default.attributesOfItem(atPath: pbxprojURL.path),
                       let fileSize = attrs[.size] as? Int64,
                       fileSize > policy.largeFileThresholds.xcodeProjectBytes {
                        noticeRecorder?(.largeFileProtection)
                    } else {
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
                    }

                } catch {
                    Logger.debug("Failed to parse pbxproj: \(error.localizedDescription)", subsystem: .fileSystem)
                }
            }
        } else if ext == "xcworkspace" {
            let contentsURL = url.appendingPathComponent("contents.xcworkspacedata")

            if FileManager.default.fileExists(atPath: contentsURL.path) {
                do {
                    if policy.enableLargeFileProtection,
                       let attrs = try? FileManager.default.attributesOfItem(atPath: contentsURL.path),
                       let fileSize = attrs[.size] as? Int64,
                       fileSize > policy.largeFileThresholds.xcodeProjectBytes {
                        noticeRecorder?(.largeFileProtection)
                    } else {
                        let content = try String(contentsOf: contentsURL, encoding: .utf8)
                        let fileRefMatches = content.components(separatedBy: "<FileRef")
                        targetCount = max(0, fileRefMatches.count - 1)
                    }
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

        if let fileOutput = runCommand("/usr/bin/file", ["-b", url.path])?.trimmingCharacters(in: .whitespacesAndNewlines) {
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

        // codesign reports signing details on stderr.
        if let signingOutput = runCommand("/usr/bin/codesign", ["-dv", url.path], includeStandardError: true) {
            isCodeSigned = !signingOutput.contains("not signed")

            if let authorityRange = signingOutput.range(of: #"Authority=([^\n]+)"#, options: .regularExpression) {
                signingAuthority = String(signingOutput[authorityRange])
                    .replacingOccurrences(of: "Authority=", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        } else {
            isCodeSigned = false
        }

        if let otoolOutput = runCommand("/usr/bin/otool", ["-l", url.path]) {
            if let minVersionRange = otoolOutput.range(of: #"minos\s+([\d.]+)"#, options: .regularExpression) {
                let match = String(otoolOutput[minVersionRange])
                minimumOS = match.components(separatedBy: .whitespaces).last
            }

            if let sdkRange = otoolOutput.range(of: #"sdk\s+([\d.]+)"#, options: .regularExpression) {
                let match = String(otoolOutput[sdkRange])
                sdkVersion = match.components(separatedBy: .whitespaces).last
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

        let isCodeSigned = runCommand("/usr/bin/codesign", ["-dv", url.path], includeStandardError: true)
            .map { !$0.contains("not signed") }
        let hasEntitlements = runCommand("/usr/bin/codesign", ["-d", "--entitlements", "-", url.path])
            .map { $0.utf8.count > 100 }

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
