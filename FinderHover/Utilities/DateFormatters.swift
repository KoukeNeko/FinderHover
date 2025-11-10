//
//  DateFormatters.swift
//  FinderHover
//
//  Centralized date formatters to avoid repeated creation
//

import Foundation

/// Provides reusable date formatters to avoid creating new instances repeatedly
enum DateFormatters {

    /// Short date and short time (e.g., "11/10/25, 4:30 PM")
    /// Used for: creation date, last access date
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    /// Medium date and short time (e.g., "Nov 10, 2025 at 4:30 PM")
    /// Used for: modification date
    static let mediumDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
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

    /// Format a date with medium date and short time style
    static func formatMediumDateTime(_ date: Date) -> String {
        return mediumDateTime.string(from: date)
    }

    /// Parse EXIF date string and return formatted medium date/time
    /// - Parameter exifDateString: Date string in EXIF format ("YYYY:MM:DD HH:MM:SS")
    /// - Returns: Formatted date string, or original string if parsing fails
    static func parseAndFormatExifDate(_ exifDateString: String) -> String {
        if let date = exifParser.date(from: exifDateString) {
            return mediumDateTime.string(from: date)
        }
        return exifDateString
    }
}
