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
func runProcessWithTimeout(_ process: Process, timeout: TimeInterval = 5.0) -> Bool {
    do {
        try process.run()
    } catch {
        return false
    }

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

// MARK: - Encoding Detection

func detectEncoding(data: Data) -> String {
    // Try UTF-8
    if String(data: data, encoding: .utf8) != nil {
        return "UTF-8"
    }
    // Try ASCII
    if String(data: data, encoding: .ascii) != nil {
        return "ASCII"
    }
    // Try other encodings
    if String(data: data, encoding: .utf16) != nil {
        return "UTF-16"
    }
    if String(data: data, encoding: .isoLatin1) != nil {
        return "ISO-8859-1"
    }
    return "Unknown"
}

// MARK: - Comment Syntax for Code Analysis

struct CommentSyntax {
    let singleLine: [String]
    let multiLineStart: String?
    let multiLineEnd: String?
}

func getCommentSyntax(for language: String) -> CommentSyntax {
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

func languageFromExtension(_ ext: String) -> String? {
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

func countJSONKeys(_ dict: [String: Any]) -> Int {
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

func calculateJSONDepth(_ dict: [String: Any]) -> Int {
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
