//
//  Logger.swift
//  FinderHover
//
//  Centralized logging system for error tracking and debugging
//

import Foundation
import os.log

/// Centralized logging system with different severity levels
enum Logger {

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

    enum Subsystem: String {
        case general = "FinderHover"
        case mouseTracking = "FinderHover.MouseTracking"
        case fileSystem = "FinderHover.FileSystem"
        case accessibility = "FinderHover.Accessibility"
        case ui = "FinderHover.UI"
        case settings = "FinderHover.Settings"
    }

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
        let formattedMessage = "[\(fileName):\(line)] \(function) - \(message)"

        // Use os_log for system integration
        let log = OSLog(subsystem: subsystem.rawValue, category: level.prefix)
        os_log("%{public}@", log: log, type: level.osLogType, formattedMessage)

        // Also print to console in debug mode
        #if DEBUG
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] \(level.prefix) [\(subsystem.rawValue)] \(formattedMessage)")
        #endif
    }
}
