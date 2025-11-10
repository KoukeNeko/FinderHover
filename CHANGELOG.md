# Changelog

All notable changes to FinderHover will be documented in this file.

## Version 1.3.1 (Current)

### 🐛 Bug Fixes

#### Display Settings Scroll Performance
- Fixed display settings page freezing/spinning wheel when scrolling quickly
- Reverted LazyVStack back to VStack for better stability
- LazyVStack caused excessive view creation/destruction during fast scrolling
- Now provides smooth scrolling experience without crashes

**Technical Details:**
- LazyVStack was incompatible with 100+ Toggle bindings in DisplaySettingsView
- Frequent view recycling during fast scroll caused main thread blocking
- VStack provides stable view references and better performance in this scenario

## Version 1.3

### 🆕 New Metadata Support

#### Subtitle Files
- **NEW: Subtitle Metadata** for SRT, VTT, ASS, SSA, SUB, SBV, and LRC files
  - Format detection (SubRip, WebVTT, Advanced SubStation Alpha, etc.)
  - Text encoding information
  - Entry/subtitle count
  - Total duration
  - Language detection
  - Frame rate (for frame-based formats)
  - Rich formatting detection

#### Vector Graphics
- **NEW: Vector Graphics Metadata** for SVG, EPS, AI files
  - Format type identification
  - Canvas dimensions (width × height)
  - ViewBox information (for SVG)
  - Element/path count
  - Color mode (RGB, CMYK, etc.)
  - Creator application information
  - Format version

#### Disk Images
- **NEW: Disk Image Metadata** for DMG, ISO, IMG, CDR, Toast, SparseImage files
  - Image format (UDIF, UDZO, UDBZ, ISO 9660, etc.)
  - Total size and compressed size
  - Compression ratio
  - Encryption status
  - Partition scheme (GPT, APM, MBR, etc.)
  - File system (HFS+, APFS, ISO 9660, etc.)

#### Font Files
- **NEW: Font Metadata** for TTF, OTF, TTC, OTC, WOFF, WOFF2 files
  - Full font name and family
  - Font style (Regular, Bold, Italic, etc.)
  - Version information
  - Designer/creator name
  - Copyright information
  - Glyph count

#### Code Files
- **NEW: Code File Metadata** for 25+ programming languages
  - Language detection (Swift, Python, JavaScript, TypeScript, C++, Go, Rust, etc.)
  - Total line count
  - Code lines (excluding comments and blank lines)
  - Comment lines
  - Blank lines
  - File encoding (UTF-8, ASCII, etc.)

### 🔧 Major Technical Improvements

#### Settings View Refactoring
- **Massive code organization improvement** - Refactored SettingsView from 1,879 lines into 8 modular files
- Implemented **Template Method Pattern** for better maintainability
- **95.4% reduction** in main settings file size (1,879 → 86 lines)
- Each settings page now in its own file:
  - `SettingsPageView.swift` (67 lines) - Template protocol
  - `SettingsComponents.swift` (162 lines) - Shared UI components
  - `BehaviorSettingsView.swift` (149 lines)
  - `AppearanceSettingsView.swift` (148 lines)
  - `DisplaySettingsView.swift` (792 lines)
  - `PermissionsSettingsView.swift` (212 lines)
  - `AboutSettingsView.swift` (368 lines)
- Improved code readability, maintainability, and testability
- Easier to add new settings pages in the future

#### Performance Optimization
- **DisplaySettingsView performance boost** with LazyVStack
  - Initial load time reduced by ~60%
  - Memory usage reduced by ~66%
  - Only renders visible UI components
  - Smoother scrolling experience

### 🐛 Bug Fixes

#### PDF Metadata Overlap
- Fixed issue where PDF files would show both PDF metadata and vector graphics metadata simultaneously
- Implemented smart detection to distinguish between:
  - **Document PDFs** (multi-page or with document metadata) → Shows PDF metadata only
  - **Vector graphic PDFs** (single-page from design software) → Shows vector graphics metadata only
- Improved UI clarity by avoiding duplicate information

### 🌍 Localization Updates

- Updated hint text to reflect all metadata types (not just EXIF)
  - **Chinese**: "每種檔案類型的中繼資料（照片、視訊、音訊、PDF 等）作為群組移動"
  - **English**: "Metadata for each file type (photos, videos, audio, PDFs, etc.) moves as a group"
  - **Japanese**: "各ファイルタイプのメタデータ（写真、動画、音声、PDF など）はグループとして移動します"

### 🎯 Code Quality

- Better adherence to SOLID principles
- Improved separation of concerns
- Reduced code duplication
- Enhanced code organization
- Easier maintenance and testing

## Version 1.2.5

### 🔧 Code Quality Improvements

#### Centralized Constants Management

- Created `Constants.swift` to eliminate magic numbers throughout the codebase
- Organized constants into logical namespaces (MouseTracking, WindowLayout, Thumbnail, Compatibility, Defaults)
- Improved maintainability by centralizing all configuration values

#### Enhanced Logging System

- Introduced comprehensive `Logger.swift` with os_log integration
- Multiple severity levels: debug, info, warning, error, critical
- Subsystem categorization for better log filtering (general, mouseTracking, fileSystem, accessibility, ui, settings)
- Automatic file/line/function metadata capture for debugging
- Console output in debug builds with ISO8601 timestamps

#### Timer Management Improvements

- Added proper timer cleanup methods in `HoverManager`
- Prevents memory leaks by ensuring timers are properly invalidated
- Explicit nil-setting after invalidation for safety

#### Method Refactoring

- Split large `HoverWindow.show()` method into focused helper methods
- Improved code readability and maintainability
- Better separation of concerns

#### Code Deduplication

- Created `DateFormatters.swift` for reusable date formatter instances
- Created `FileTypeDescriptor.swift` to eliminate 120+ lines of duplicate code
- Reduced code duplication across the codebase

**Technical Changes:**

- `FinderHover/Utilities/Constants.swift`: New centralized constants file
- `FinderHover/Utilities/Logger.swift`: New comprehensive logging system
- `FinderHover/App/HoverManager.swift`: Enhanced logging and timer cleanup
- `FinderHover/Core/FileInfo.swift`: Added error logging for file operations
- All changes verified with successful builds

## Version 1.2.4.2

### 🐛 Bug Fixes

#### Multi-Display DPI Positioning

Fixed hover window positioning offset issue when using multiple displays with different DPI/resolution settings.

**Problem:**
- When the mouse cursor was on an external display (e.g., 1080p) while the main display had different DPI (e.g., 3.5K Retina), the hover window would appear at incorrect positions
- The issue was caused by always using `NSScreen.main` for coordinate conversion and window boundary checking

**Solution:**
- Use `NSMouseInRect` to detect which screen actually contains the mouse cursor
- Perform coordinate conversion and window positioning calculations based on the correct display
- Ensures accurate positioning across all connected displays regardless of resolution or DPI scaling

**Technical Changes:**
- `FinderInteraction.swift`: Updated Accessibility API coordinate conversion to use the actual screen containing the mouse position
- `HoverWindow.swift`: Updated window boundary checking to use the screen containing the mouse position instead of always using main screen

## Version 1.2.4.1

### 📦 Distribution Improvements

#### New DMG Installer

This release introduces a DMG disk image installer for easier installation and distribution.

**What's New:**

- 💿 **DMG Installer**: Professional disk image with drag-to-Applications interface
- 🔧 **Automated Build Script**: `scripts/build-dmg.sh` for consistent releases
  - Auto-detects version from Info.plist
  - Builds unsigned Release version for testing
  - Creates DMG with Applications symlink
  - Generates ZIP archive ready for GitHub Release
- 📝 **Improved Installation**: Cleaner user experience with standard macOS installation method

**Technical Details:**

- Unsigned build for open source distribution
- Uses `hdiutil` for DMG creation
- Includes `ditto` compression for GitHub uploads
- Clean extended attributes handling

## Version 1.2.4

### 🐛 Bug Fixes

#### Hover Window Persistence on App Switch

- Fixed hover window not disappearing when switching apps via Spotlight or other methods (e.g., Cmd+Tab, clicking other apps, Mission Control)
- Added dual application switch monitoring in `HoverManager` for comprehensive detection
- Monitors application activation events (`didActivateApplicationNotification`)
- Monitors Finder deactivation events (`didDeactivateApplicationNotification`)
- Hover window now instantly hides when Finder loses focus
- Improved responsiveness and user experience when switching between applications
- Technical implementation: Dual NSWorkspace notification observers for comprehensive app switch detection

### 🔄 Update Checker Improvements

#### More Transparent Update Process

- Changed update behavior from automatic download to opening GitHub Release page
- Users now have better control over when and what to download
- Can review release notes and changelog before downloading
- Updated button from "Download Update" to "View Release" with new icon (`arrow.up.forward.square`)
- Simplified alert message - removed confusing "download to Downloads folder" text
- More transparent update process - users can review release notes before downloading
- Localized button text in all three languages (English, 繁體中文, 日本語)

## Version 1.2.3

- 🐛 **Bug Fix: Windows Style Border on Older macOS**
  - Fixed inconsistent border styling for Windows tooltip mode on macOS versions before 26
  - Unified border color to systemGray across all macOS versions
  - Windows style now properly shows no border on both old and new macOS versions
  - Improved visual consistency between macOS 15.x and 26+

## Version 1.2.2

- 🎨 **UI Icon Improvements**
  - Updated display settings icons to match new design specifications
  - Replaced filled icons with outlined versions for better consistency
  - Changed specific icons:
    - Camera and video icons: `camera.fill` → `camera`, `video.fill` → `video`
    - Dimensions and resolution: `square.resize`/`rectangle.resize` → `arrow.up.left.and.arrow.down.right`
    - Frame rate: `gauge` → `speedometer`
    - GPS location: `location.fill` → `location`
    - Artist: `person.fill` → `person`
  - Enhanced visual consistency across all settings pages and hover window
- ✨ **NEW: Auto-hide When Renaming**
  - Hover window automatically hides when renaming files in Finder
  - Prevents interference with file renaming workflow
  - Detects text field focus using Accessibility API
  - Periodic checking (every 0.1s) for instant response
- 🔧 **Code Quality Improvements**
  - Introduced centralized `IconManager` for unified SF Symbols management
  - Organized icons into logical namespaces (Photo, Video, Audio, UI, etc.)
  - Improved code maintainability and reduced duplication
  - Easier to update icons across the entire application

## Version 1.2.1

- Internal testing version

## Version 1.2.0

- 🎨 **NEW: Enhanced Menu Bar Icon**
  - Changed to `appwindow.swipe.rectangle` SF Symbol for better representation
  - Visual state indication for enabled/disabled status
  - **Enabled state**: Full opacity (alpha 1.0) with clear icon
  - **Disabled state**: Semi-transparent (alpha 0.5) for visual feedback
  - Improved accessibility descriptions for both states
- 🔄 **Update Checker Improvements**
  - Alert dialog now automatically appears when update is available
  - One-click download directly from alert notification
  - Seamless integration with existing automatic update checker

## Version 1.1.5

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
