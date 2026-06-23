//
//  Logger.swift
//  FinderHover
//
//  Centralized logging system for error tracking and debugging
//

import Foundation
import os

/// Centralized logging system with different severity levels.
/// `nonisolated` because logging is thread-safe (`os.Logger` is `Sendable`) and must
/// be callable from any isolation domain — background queues and actors included —
/// without hopping to the main actor.
nonisolated enum Logger {

    // MARK: - Log Levels

    enum Level {
        case debug
        case info
        case warning
        case error
        case critical

        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }

        var prefix: String {
            switch self {
            case .debug: return "🔍 DEBUG"
            case .info: return "ℹ️ INFO"
            case .warning: return "⚠️ WARNING"
            case .error: return "❌ ERROR"
            case .critical: return "🔥 CRITICAL"
            }
        }
    }

    // MARK: - Subsystems

    enum Subsystem: String, CaseIterable {
        case general = "FinderHover"
        case mouseTracking = "FinderHover.MouseTracking"
        case fileSystem = "FinderHover.FileSystem"
        case accessibility = "FinderHover.Accessibility"
        case ui = "FinderHover.UI"
        case settings = "FinderHover.Settings"

        var categoryName: String {
            switch self {
            case .general: return "General"
            case .mouseTracking: return "MouseTracking"
            case .fileSystem: return "FileSystem"
            case .accessibility: return "Accessibility"
            case .ui: return "UI"
            case .settings: return "Settings"
            }
        }
    }

    // MARK: - Cached Loggers

    private static let loggers: [Subsystem: os.Logger] = Dictionary(
        uniqueKeysWithValues: Subsystem.allCases.map { subsystem in
            (subsystem, os.Logger(subsystem: subsystem.rawValue, category: subsystem.categoryName))
        }
    )

    // MARK: - Logging Methods

    /// Log a debug message (only in debug builds)
    static func debug(_ message: String, subsystem: Subsystem = .general, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log(message, level: .debug, subsystem: subsystem, file: file, function: function, line: line)
        #endif
    }

    /// Log an informational message
    static func info(_ message: String, subsystem: Subsystem = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, subsystem: subsystem, file: file, function: function, line: line)
    }

    /// Log a warning message
    static func warning(_ message: String, subsystem: Subsystem = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, subsystem: subsystem, file: file, function: function, line: line)
    }

    /// Log an error message
    static func error(_ message: String, error: Error? = nil, subsystem: Subsystem = .general, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .error, subsystem: subsystem, file: file, function: function, line: line)
    }

    /// Log a critical error message (system failure)
    static func critical(_ message: String, error: Error? = nil, subsystem: Subsystem = .general, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .critical, subsystem: subsystem, file: file, function: function, line: line)
    }

    // MARK: - Private Implementation

    private static func log(_ message: String, level: Level, subsystem: Subsystem, file: String, function: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let location = "[\(fileName):\(line)] \(function)"

        let logger = loggers[subsystem] ?? loggers[.general]!
        logger.log(
            level: level.osLogType,
            "\(location, privacy: .public) - \(message, privacy: .private)"
        )

        // Also print to console in debug mode
        #if DEBUG
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] \(level.prefix) [\(subsystem.rawValue)] \(location) - \(message)")
        #endif
    }
}
