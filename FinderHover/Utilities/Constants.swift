//
//  Constants.swift
//  FinderHover
//
//  Centralized constants to eliminate magic numbers throughout the codebase
//

import Foundation
import CoreGraphics

/// Application-wide constants
enum Constants {

    // MARK: - Mouse Tracking
    enum MouseTracking {
        /// Debounce delay for hover detection (milliseconds)
        /// This prevents showing the window on brief mouse movements
        static let hoverDebounceDelay: Int = 300

        /// Timer interval for checking if file is being renamed (seconds)
        /// Checks frequently to quickly hide window when renaming starts
        static let renamingCheckInterval: TimeInterval = 0.1
    }

    // MARK: - Window Layout
    enum WindowLayout {
        /// Temporary container height for size calculation
        /// Large enough to accommodate any reasonable content
        static let tempContainerHeight: CGFloat = 5000

        /// Default corner radius for macOS style windows
        static let macOSCornerRadius: CGFloat = 10

        /// Corner radius for Windows style windows (no rounding)
        static let windowsCornerRadius: CGFloat = 0

        /// Border width for macOS style with blur effect
        static let macOSBorderWidth: CGFloat = 0.5

        /// Minimum padding from screen edge
        static let screenEdgePadding: CGFloat = 10
    }

    // MARK: - Thumbnail Generation
    enum Thumbnail {
        /// Standard thumbnail size for file icons
        static let standardSize: CGFloat = 128

        /// Compact mode icon size
        static let compactIconSize: CGFloat = 32

        /// Normal mode icon size
        static let normalIconSize: CGFloat = 48
    }

    // MARK: - Version Compatibility
    enum Compatibility {
        /// macOS version where blur effect behavior changed
        /// Versions <= 15.x require special workaround for corner radius
        static let blurLayoutChangeVersion: Int = 15
    }

    // MARK: - Settings Defaults
    enum Defaults {
        /// Default hover delay in seconds
        static let hoverDelay: Double = 0.1

        /// Default window opacity (0.0 - 1.0)
        static let windowOpacity: Double = 0.98

        /// Default window maximum width in points
        static let windowMaxWidth: Double = 400

        /// Default font size in points
        static let fontSize: Double = 11

        /// Default window offset from cursor (horizontal)
        static let windowOffsetX: Double = 15

        /// Default window offset from cursor (vertical)
        static let windowOffsetY: Double = 15
    }
}
