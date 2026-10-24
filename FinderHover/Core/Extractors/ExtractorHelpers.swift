//
//  ExtractorHelpers.swift
//  FinderHover
//
//  Shared helper functions for metadata extractors
//

import Foundation

// MARK: - Process Timeout Helper

/// Runs a Process with a timeout to prevent indefinite blocking
/// - Parameters:
///   - process: The Process to run
///   - timeout: Maximum time in seconds to wait for completion
/// - Returns: true if process completed within timeout, false if timed out or failed
nonisolated func runProcessWithTimeout(
    _ process: Process,
    timeout: TimeInterval = 5.0,
    afterLaunch: () -> Void = {}
) -> Bool {
    do {
        try process.run()
    } catch {
        return false
    }
    afterLaunch()

    let deadline = Date().addingTimeInterval(timeout)

    while process.isRunning {
        if Date() > deadline {
            process.terminate()
            let executable = process.executableURL?.path ?? "unknown"
            let arguments = process.arguments?.joined(separator: " ") ?? ""
            Logger.warning("Process timed out after \(timeout)s: \(executable) \(arguments)", subsystem: .fileSystem)
            return false
        }
        Thread.sleep(forTimeInterval: 0.05)
    }

    return process.terminationStatus == 0
}

/// Runs a Process and returns its standard-output bytes, or nil on timeout/failure.
/// - Parameter includeStandardError: also capture stderr (e.g. `codesign -dv` reports there);
///   otherwise stderr is discarded.
/// Output is drained while the command runs: a pipe holds about 64 KB, and a command that
/// fills it blocks until someone reads, so reading only after exit stalls until the timeout.
nonisolated func runProcessCapturingOutput(
    _ process: Process,
    timeout: TimeInterval = 5.0,
    includeStandardError: Bool = false
) -> Data? {
    let output = Pipe()
    process.standardOutput = output
    process.standardError = includeStandardError ? output : FileHandle.nullDevice

    final class Drain: @unchecked Sendable { var data = Data() }
    let drain = Drain()
    let drained = DispatchSemaphore(value: 0)
    let succeeded = runProcessWithTimeout(process, timeout: timeout) {
        DispatchQueue.global(qos: .userInitiated).async {
            drain.data = output.fileHandleForReading.readDataToEndOfFile()
            drained.signal()
        }
    }
    // A grandchild can keep the pipe open after the command exits; don't wait on it forever.
    if process.processIdentifier != 0, drained.wait(timeout: .now() + 1) == .timedOut {
        return nil
    }
    return succeeded ? drain.data : nil
}

/// Runs a command by absolute path and returns its stdout as text, or nil on failure.
nonisolated func runCommand(
    _ executable: String,
    _ arguments: [String],
    timeout: TimeInterval = 3.0,
    includeStandardError: Bool = false
) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    guard let data = runProcessCapturingOutput(process, timeout: timeout, includeStandardError: includeStandardError) else {
        return nil
    }
    return String(data: data, encoding: .utf8)
}

// MARK: - zipinfo Summary

/// Reads the totals line `zipinfo` prints last, e.g.
/// "35 files, 4900000 bytes uncompressed, 1900000 bytes compressed:  62.2%"
/// (singular "1 file," for one entry).
nonisolated func zipinfoTotals(_ output: String) -> (fileCount: Int, uncompressedBytes: Int64)? {
    for line in output.components(separatedBy: .newlines).reversed() {
        let words = line.split(separator: " ").map(String.init)
        guard words.count >= 5, words[1] == "file," || words[1] == "files,",
              words[4] == "uncompressed,",
              let count = Int(words[0]), let bytes = Int64(words[2]) else { continue }
        return (count, bytes)
    }
    return nil
}

// MARK: - Bounded Header Read

/// Reads at most the first `maxByteCount` bytes of a file into owned (non-mapped) memory.
///
/// Unlike `Data(contentsOf:)` this never allocates the whole file, and unlike
/// `Data(contentsOf:, .mappedIfSafe)` the returned bytes are copied onto the heap, so
/// dereferencing them cannot raise SIGBUS if the file is truncated after the read.
/// The returned `Data.count` is the number of bytes actually available (it may be less
/// than `maxByteCount` for short files), so callers can length-check it directly.
/// - Returns: the leading bytes, or `nil` if the file cannot be opened or read.
nonisolated func readFileHeader(of url: URL, maxByteCount: Int) -> Data? {
    guard let handle = try? FileHandle(forReadingFrom: url) else {
        return nil
    }
    defer { try? handle.close() }

    do {
        return try handle.read(upToCount: maxByteCount)
    } catch {
        Logger.debug("Failed to read file header: \(error.localizedDescription)", subsystem: .fileSystem)
        return nil
    }
}

// MARK: - Encoding Detection

nonisolated func detectEncoding(data: Data) -> String {
    // A byte-order mark is authoritative when present.
    if let bomEncoding = encodingFromBOM(data) {
        return bomEncoding
    }

    // Plain 7-bit ASCII is a meaningful, common answer and a strict subset of
    // UTF-8, so report it explicitly before the broader UTF-8 check.
    if data.allSatisfy({ $0 < 0x80 }) {
        return "ASCII"
    }

    // Valid UTF-8 (with high bytes) is the overwhelmingly common modern case.
    if String(data: data, encoding: .utf8) != nil {
        return "UTF-8"
    }

    // Fall back to Foundation's statistical detector instead of "does this
    // lossless decoder accept the bytes" — .utf16/.isoLatin1 accept almost any
    // byte sequence, which is why "Unknown" was previously unreachable.
    var converted: NSString?
    let detected = NSString.stringEncoding(
        for: data,
        encodingOptions: nil,
        convertedString: &converted,
        usedLossyConversion: nil
    )
    if detected != 0 {
        let cfEncoding = CFStringConvertNSStringEncodingToEncoding(detected)
        if let ianaName = CFStringConvertEncodingToIANACharSetName(cfEncoding) as String? {
            return ianaName.uppercased()
        }
    }

    return "Unknown"
}

/// Returns a human-readable encoding name if `data` begins with a recognized
/// byte-order mark, otherwise nil.
nonisolated private func encodingFromBOM(_ data: Data) -> String? {
    let bytes = [UInt8](data.prefix(4))
    if bytes.starts(with: [0xEF, 0xBB, 0xBF]) { return "UTF-8" }
    if bytes.starts(with: [0x00, 0x00, 0xFE, 0xFF]) { return "UTF-32BE" }
    if bytes.starts(with: [0xFF, 0xFE, 0x00, 0x00]) { return "UTF-32LE" }
    if bytes.starts(with: [0xFE, 0xFF]) { return "UTF-16BE" }
    if bytes.starts(with: [0xFF, 0xFE]) { return "UTF-16LE" }
    return nil
}

// MARK: - Comment Syntax for Code Analysis

nonisolated struct CommentSyntax {
    let singleLine: [String]
    let multiLineStart: String?
    let multiLineEnd: String?
}

nonisolated func getCommentSyntax(for language: String) -> CommentSyntax {
    switch language {
    case "C", "C++", "Objective-C", "Objective-C++", "C#", "Swift", "JavaScript", "TypeScript", "JSX", "Java", "Kotlin", "Scala", "Groovy", "Rust", "Go", "Dart", "PHP":
        return CommentSyntax(singleLine: ["//"], multiLineStart: "/*", multiLineEnd: "*/")
    case "Python", "Ruby", "Shell", "Bash", "Zsh", "Perl", "YAML", "TOML", "INI", "R":
        return CommentSyntax(singleLine: ["#"], multiLineStart: nil, multiLineEnd: nil)
    case "HTML", "XML":
        return CommentSyntax(singleLine: [], multiLineStart: "<!--", multiLineEnd: "-->")
    case "CSS", "SCSS", "Sass", "Less":
        return CommentSyntax(singleLine: ["//"], multiLineStart: "/*", multiLineEnd: "*/")
    case "Lua":
        return CommentSyntax(singleLine: ["--"], multiLineStart: "--[[", multiLineEnd: "]]")
    case "SQL":
        return CommentSyntax(singleLine: ["--"], multiLineStart: "/*", multiLineEnd: "*/")
    case "Vim Script":
        return CommentSyntax(singleLine: ["\""], multiLineStart: nil, multiLineEnd: nil)
    case "Emacs Lisp":
        return CommentSyntax(singleLine: [";"], multiLineStart: nil, multiLineEnd: nil)
    default:
        return CommentSyntax(singleLine: ["//", "#"], multiLineStart: "/*", multiLineEnd: "*/")
    }
}

// MARK: - Language Detection

nonisolated func languageFromExtension(_ ext: String) -> String? {
    let languageMap: [String: String] = [
        // C-family
        "c": "C", "h": "C",
        "cpp": "C++", "cc": "C++", "cxx": "C++", "hpp": "C++", "hxx": "C++",
        "m": "Objective-C", "mm": "Objective-C++",
        "cs": "C#",
        // Modern languages
        "swift": "Swift",
        "rs": "Rust",
        "go": "Go",
        "kt": "Kotlin", "kts": "Kotlin",
        "dart": "Dart",
        // Scripting
        "py": "Python", "pyw": "Python",
        "rb": "Ruby",
        "php": "PHP",
        "pl": "Perl", "pm": "Perl",
        "sh": "Shell", "bash": "Bash", "zsh": "Zsh",
        // JVM
        "java": "Java",
        "scala": "Scala",
        "groovy": "Groovy",
        // Web
        "js": "JavaScript", "mjs": "JavaScript",
        "ts": "TypeScript", "tsx": "TypeScript",
        "jsx": "JSX",
        "html": "HTML", "htm": "HTML",
        "css": "CSS",
        "scss": "SCSS", "sass": "Sass",
        "less": "Less",
        "vue": "Vue",
        // Data/Config
        "xml": "XML",
        // Other
        "sql": "SQL",
        "r": "R",
        "lua": "Lua",
        "vim": "Vim Script",
        "el": "Emacs Lisp", "elisp": "Emacs Lisp"
    ]

    return languageMap[ext]
}

// MARK: - JSON Helpers

nonisolated func countJSONKeys(_ dict: [String: Any]) -> Int {
    var count = dict.keys.count
    for value in dict.values {
        if let nestedDict = value as? [String: Any] {
            count += countJSONKeys(nestedDict)
        } else if let array = value as? [Any] {
            for item in array {
                if let nestedDict = item as? [String: Any] {
                    count += countJSONKeys(nestedDict)
                }
            }
        }
    }
    return count
}

nonisolated func calculateJSONDepth(_ dict: [String: Any]) -> Int {
    var maxChildDepth = 0
    for value in dict.values {
        if let nestedDict = value as? [String: Any] {
            maxChildDepth = max(maxChildDepth, calculateJSONDepth(nestedDict))
        } else if let array = value as? [Any] {
            for item in array {
                if let nestedDict = item as? [String: Any] {
                    maxChildDepth = max(maxChildDepth, calculateJSONDepth(nestedDict))
                }
            }
        }
    }
    return maxChildDepth + 1
}
