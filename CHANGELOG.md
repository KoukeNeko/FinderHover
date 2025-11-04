# Changelog

All notable changes to FinderHover will be documented in this file.

## Version 1.1.5 (Current)

- 🔄 **NEW: Automatic Update Checker with One-Click Download**
  - Built-in update checker in About settings
  - One-click check for latest releases from GitHub
  - Smart version comparison with semantic versioning
  - **Automatic Download**: When an update is available, shows alert dialog with direct download button
  - **One-Click Installation**: Downloads `FinderHover.app.zip` directly to Downloads folder
  - **Auto-Reveal in Finder**: Automatically opens Finder and highlights the downloaded file
  - **Prerelease Support**: Optional toggle to check for beta/RC versions
  - **Rate Limiting Protection**: 5-second cooldown between checks
  - **Fixed Height UI**: Prevents content jumping between states
  - Displays current version when up-to-date
  - Fully localized error messages in all three languages
- 🌍 **Localization Enhancements**
  - Complete localization of all update checker messages
  - Improved error handling with user-friendly translated messages
  - Alert dialog localized in English, 繁體中文, 日本語
  - Version comparison messages in all supported languages
- 🔧 **Technical Improvements**
  - GitHub API integration with fallback for prereleases
  - URLSession-based download with automatic file management
  - Intelligent endpoint selection based on release preference
  - Proper handling of draft releases
  - HTTP error code handling (403, 404, etc.)
  - SwiftUI alert integration for update notifications

## Version 1.1.4

- 🐛 **Fixed: macOS 15.x Corner Radius Issue**
  - Fixed rounded corners not rendering properly on macOS 15.x (Sequoia)
  - Implemented container view approach with proper layer masking
  - Added subtle gray border (0.5pt) matching native macOS HUD windows
  - Enhanced visual consistency across all macOS versions
- 👥 **NEW: GitHub Contributors Display**
  - Added dynamic contributor avatars in About settings
  - Contributors shown in responsive grid layout (32x32px avatars)
  - Clickable avatars linking to contributor GitHub profiles
  - Shows contribution count for each contributor
  - Offline cache support (24-hour expiration)
- 🌍 **Localization Updates**
  - Added contributor feature strings for all languages
  - Maintained full support for English, 繁體中文, 日本語
- 🔧 **Technical Improvements**
  - Cross-version compatibility (macOS 11-26+)
  - Optimized window rendering for different OS versions

## Version 1.1.3

- 🎨 **NEW: Windows Style Tooltip Option**
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
- 🌍 **Enhanced Localization**
  - Added Windows style translations for all three languages (en, zh-Hant, ja)
- 🔧 **UI Improvements**
  - Moved UI Style setting from Behavior to Appearance tab for better organization
  - Improved settings structure and navigation

## Version 1.1.2

- 🎬 **NEW: Video Metadata Support**
  - Duration formatted as hours:minutes:seconds
  - Resolution (width × height in pixels)
  - Video codec information
  - Frame rate (fps)
  - Bitrate (Mbps or kbps)
  - Supports 13 video formats: MP4, MOV, M4V, AVI, MKV, FLV, WMV, WebM, MPEG, MPG, 3GP, MTS, M2TS
  - Individual toggles for each video metadata field
- 🎵 **NEW: Audio Metadata Support**
  - Song title, artist, album, genre, year from ID3 tags
  - Duration formatted as minutes:seconds
  - Bitrate (kbps)
  - Sample rate (kHz or Hz)
  - Channel configuration (Mono, Stereo, multi-channel)
  - Supports 11 audio formats: MP3, M4A, AAC, WAV, FLAC, AIFF, AIF, WMA, OGG, Opus, ALAC
  - Individual toggles for each audio metadata field
- 🎨 **UI Improvements**
  - Optimized label width for Japanese localization
  - Improved icon visibility for resolution field
  - Consistent text wrapping prevention across all languages
- 🌐 **Localization Updates**
  - Refined Japanese translations for better readability

## Version 1.1.1

- 🌐 **NEW: Multi-Language Support**
  - Three languages fully supported: English, 繁體中文 (Traditional Chinese), 日本語 (Japanese)
  - System Default option automatically follows macOS language settings
  - In-app language switcher with one-click restart
  - Complete localization of all UI elements, settings, and menus
  - Consistent vertical slider layouts across all settings pages

## Version 1.1

- 📸 **NEW: Photo EXIF Information**
  - Camera model and lens information
  - Camera settings (focal length, aperture, shutter speed, ISO)
  - Date taken with original timestamp
  - Image dimensions (width × height)
  - GPS location data (optional)
  - Supports JPEG, PNG, TIFF, HEIC, RAW (CR2, NEF, ARW, DNG, etc.)
  - Individual toggles for each EXIF field
- 🎨 **NEW: Customizable Display Order**
  - Drag and drop to reorder information fields
  - EXIF moves as a complete group
  - Changes save automatically and apply in real-time
- 🐛 Bug fixes:
  - Fixed display order not persisting to UserDefaults
  - Improved compatibility with older macOS versions (pre-11.0) for blur effects

## Version 1.0

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
