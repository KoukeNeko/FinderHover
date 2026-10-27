//
//  DateFormatters.swift
//  FinderHover
//
//  Centralized date formatters to avoid repeated creation
//

import Foundation

/// Provides reusable date formatters to avoid creating new instances repeatedly
nonisolated enum DateFormatters {

    /// Short date and short time (e.g., "11/10/25, 4:30 PM").
    /// Every date-and-time the popup shows uses this one style, so they read alike.
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    /// EXIF date parser (e.g., "2025:11:10 16:30:45")
    /// Used for: parsing EXIF DateTimeOriginal
    static let exifParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter
    }()

    /// Format a date with short date and short time style
    static func formatShortDateTime(_ date: Date) -> String {
        return shortDateTime.string(from: date)
    }

    /// Parse EXIF date string and return it in the short date/time style
    /// - Parameter exifDateString: Date string in EXIF format ("YYYY:MM:DD HH:MM:SS")
    /// - Returns: Formatted date string, or original string if parsing fails
    static func parseAndFormatExifDate(_ exifDateString: String) -> String {
        if let date = exifParser.date(from: exifDateString) {
            return shortDateTime.string(from: date)
        }
        return exifDateString
    }
}
