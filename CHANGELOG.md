# Changelog

All notable changes to FinderHover will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.5] - 2025-11-04

### Added
- 🚀 **Automatic Updates with Sparkle**
  - Integrated Sparkle framework for seamless automatic updates
  - EdDSA cryptographic signature verification for security
  - In-app update notifications and installation
  - Configurable automatic update checks (24-hour interval)
  - User control over automatic update checking in Settings
- 📜 **Release Automation Scripts**
  - Semi-automatic release script (`release.sh`)
  - Fully automatic release script (`release-auto.sh`)
  - Comprehensive documentation for release process

### Changed
- Updated Settings UI to use Sparkle's native update checker
- Replaced custom UpdateChecker with industry-standard Sparkle framework

### Fixed
- Improved update notification reliability
- Enhanced security with code signing verification

## [1.1.4] - 2025-11-03

### Fixed
- 🐛 **macOS 15.x Corner Radius Issue**
  - Fixed rounded corners not rendering properly on macOS 15.x (Sequoia)
  - Implemented container view approach with proper layer masking
  - Added subtle gray border (0.5pt) matching native macOS HUD windows
  - Enhanced visual consistency across all macOS versions

### Added
- 👥 **GitHub Contributors Display**
  - Added dynamic contributor avatars in About settings
  - Contributors shown in responsive grid layout (32x32px avatars)
  - Clickable avatars linking to contributor GitHub profiles
  - Shows contribution count for each contributor
  - Offline cache support (24-hour expiration)

### Changed
- 🌍 **Localization Updates**
  - Added contributor feature strings for all languages
  - Maintained full support for English, 繁體中文, 日本語
- 🔧 **Technical Improvements**
  - Cross-version compatibility (macOS 11-26+)
  - Optimized window rendering for different OS versions

## [1.1.3] - 2025-11-02

### Added
- 🎨 **Windows Style Tooltip Option**
  - Added UI style selector in Settings > Appearance tab
  - Choose between macOS and Windows tooltip styles
  - **Windows Style features**:
    - No icons or thumbnails - Pure text-based display
    - Compact layout with reduced spacing (10px padding)
    - Left-aligned text in simple `Label: Value` format
    - Square corners (0px border radius)
    - Three essential fields: Type, Size, Date modified
    - Inspired by Windows File Explorer tooltips
  - **macOS Style features**:
    - Rich preview with icons and thumbnails
    - Detailed metadata display
    - Rounded corners (10px border radius)
    - Multiple information fields and customization options

### Changed
- 🌍 **Enhanced Localization**
  - Added Windows style translations for all three languages (en, zh-Hant, ja)
- 🔧 **UI Improvements**
  - Moved UI Style setting from Behavior to Appearance tab for better organization
  - Improved settings structure and navigation

## [1.1.2] - 2025-11-01

### Added
- 🎬 **Video Metadata Support**
  - Duration formatted as hours:minutes:seconds
  - Resolution (width × height in pixels)
  - Video codec information
  - Frame rate (fps)
  - Bitrate (Mbps or kbps)
  - Supports 13 video formats: MP4, MOV, M4V, AVI, MKV, FLV, WMV, WebM, MPEG, MPG, 3GP, MTS, M2TS
  - Individual toggles for each video metadata field
- 🎵 **Audio Metadata Support**
  - Song title, artist, album, genre, year from ID3 tags
  - Duration formatted as minutes:seconds
  - Bitrate (kbps)
  - Sample rate (kHz or Hz)
  - Channel configuration (Mono, Stereo, multi-channel)
  - Supports 11 audio formats: MP3, M4A, AAC, WAV, FLAC, AIFF, AIF, WMA, OGG, Opus, ALAC
  - Individual toggles for each audio metadata field

### Changed
- 🎨 **UI Improvements**
  - Optimized label width for Japanese localization
  - Improved icon visibility for resolution field
  - Consistent text wrapping prevention across all languages
- 🌐 **Localization Updates**
  - Refined Japanese translations for better readability

## [1.1.1] - 2025-10-30

### Added
- 🌐 **Multi-Language Support**
  - Three languages fully supported: English, 繁體中文 (Traditional Chinese), 日本語 (Japanese)
  - System Default option automatically follows macOS language settings
  - In-app language switcher with one-click restart
  - Complete localization of all UI elements, settings, and menus
  - Consistent vertical slider layouts across all settings pages

## [1.1.0] - 2025-10-28

### Added
- 📸 **Photo EXIF Information**
  - Camera model and lens information
  - Camera settings (focal length, aperture, shutter speed, ISO)
  - Date taken with original timestamp
  - Image dimensions (width × height)
  - GPS location data (optional)
  - Supports JPEG, PNG, TIFF, HEIC, RAW (CR2, NEF, ARW, DNG, etc.)
  - Individual toggles for each EXIF field
- 🎨 **Customizable Display Order**
  - Drag and drop to reorder information fields
  - EXIF moves as a complete group
  - Changes save automatically and apply in real-time

### Fixed
- Fixed display order not persisting to UserDefaults
- Improved compatibility with older macOS versions (pre-11.0) for blur effects

## [1.0.0] - 2025-10-25

### Added
- ✨ Initial release
- 🎯 Smart hover preview with adjustable delay (default: 0.1s)
- 📊 Rich file information display with 50+ file type recognition
- 🖼️ QuickLook thumbnail previews for files (PDFs, images, documents)
  - Asynchronous loading for instant window display
  - Falls back to standard icons if preview unavailable
- 🎨 Native macOS blur effect (toggleable)
  - HUD-style background blur
  - Smooth rounded corners
- 📐 Dynamic window height - Automatically adjusts to content
- ⚙️ Comprehensive settings with sidebar navigation
- 🎛️ Contextual UI hints (e.g., opacity availability)
- 🔒 Privacy-first: Accessibility API only (no AppleScript)
- ⚡ Instant auto-hide when mouse moves away
- 🚫 Drag operation detection - Hides during file drag operations
- 🚀 Launch at login support
- 📏 Perfect icon and text alignment
- 📄 Complete file path display (no truncation)
- 📊 Extended file metadata display:
  - Item count for folders
  - Last access date
  - File permissions (octal + rwx notation)
  - Owner information
- 🗜️ Compact mode for reduced spacing
- 💾 Persistent settings with UserDefaults
- 🚀 Lightweight and efficient
- 🌐 Full Unicode support for international file names

[Unreleased]: https://github.com/KoukeNeko/FinderHover/compare/v1.1.5...HEAD
[1.1.5]: https://github.com/KoukeNeko/FinderHover/compare/v1.1.4...v1.1.5
[1.1.4]: https://github.com/KoukeNeko/FinderHover/compare/v1.1.3...v1.1.4
[1.1.3]: https://github.com/KoukeNeko/FinderHover/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/KoukeNeko/FinderHover/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/KoukeNeko/FinderHover/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/KoukeNeko/FinderHover/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/KoukeNeko/FinderHover/releases/tag/v1.0.0
