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

        /// Default auto-hide behavior
        static let autoHideEnabled: Bool = true

        /// Default launch at login behavior
        static let launchAtLogin: Bool = false

        /// Default blur effect enabled
        static let enableBlur: Bool = true

        /// Default compact mode
        static let compactMode: Bool = false

        /// Default show creation date
        static let showCreationDate: Bool = true

        /// Default show modification date
        static let showModificationDate: Bool = true

        /// Default show file size
        static let showFileSize: Bool = true

        /// Default show file type
        static let showFileType: Bool = true

        /// Default show file path
        static let showFilePath: Bool = true

        /// Default show icon
        static let showIcon: Bool = true

        /// Default show last access date
        static let showLastAccessDate: Bool = false

        /// Default show permissions
        static let showPermissions: Bool = false

        /// Default show owner
        static let showOwner: Bool = false

        /// Default show item count
        static let showItemCount: Bool = true

        /// Default show EXIF
        static let showEXIF: Bool = true

        /// Default show EXIF camera
        static let showEXIFCamera: Bool = true

        /// Default show EXIF lens
        static let showEXIFLens: Bool = true

        /// Default show EXIF settings
        static let showEXIFSettings: Bool = true

        /// Default show EXIF date taken
        static let showEXIFDateTaken: Bool = true

        /// Default show EXIF dimensions
        static let showEXIFDimensions: Bool = true

        /// Default show EXIF GPS
        static let showEXIFGPS: Bool = false

        /// Default show video
        static let showVideo: Bool = true

        /// Default show video duration
        static let showVideoDuration: Bool = true

        /// Default show video resolution
        static let showVideoResolution: Bool = true

        /// Default show video codec
        static let showVideoCodec: Bool = true

        /// Default show video frame rate
        static let showVideoFrameRate: Bool = true

        /// Default show video bitrate
        static let showVideoBitrate: Bool = true

        /// Default show audio
        static let showAudio: Bool = true

        /// Default show audio title
        static let showAudioTitle: Bool = true

        /// Default show audio artist
        static let showAudioArtist: Bool = true

        /// Default show audio album
        static let showAudioAlbum: Bool = true

        /// Default show audio genre
        static let showAudioGenre: Bool = true

        /// Default show audio year
        static let showAudioYear: Bool = true

        /// Default show audio duration
        static let showAudioDuration: Bool = true

        /// Default show audio bitrate
        static let showAudioBitrate: Bool = true

        /// Default show audio sample rate
        static let showAudioSampleRate: Bool = true

        /// Default follow cursor
        static let followCursor: Bool = true

        /// Default include prereleases
        static let includePrereleases: Bool = false
    }
}
