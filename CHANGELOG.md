# Changelog

All notable changes to FinderHover will be documented in this file.

## Version 1.6.4 (Current)

### 🎨 Improvements

- Hover window now hides when Option key is released
- Copy feedback changed from checkmark icon to "Copied" text shown after the value

---

## Version 1.6.3

### 🐛 Bug Fixes

- Fixed copy button layout stability using opacity instead of conditional rendering
- Copy button is now always present in layout, preventing height shifts when Option key is pressed

---

## Version 1.6.2

### 🐛 Bug Fixes

- Fixed copy button still causing row height to increase
- Removed lock icon indicator

---

## Version 1.6.1

### 🐛 Bug Fixes

- Fixed copy button causing row height to increase
- Fixed clicking copy marking multiple rows with same value as copied

---

## Version 1.6.0

### 🆕 New Feature: Copy Metadata Values

Press **Option (⌥)** key while the hover window is visible to:
- Lock the window in place (won't disappear on mouse movement)
- Show copy icons on the right side of each metadata value
- Click any copy icon to copy that value to clipboard
- Visual feedback when copying (checkmark icon)

Release Option key or press Escape to unlock and return to normal behavior.

### 🌐 Localization

- Added translations for copy feature in all supported languages

---

## Version 1.5.1

### 🎨 UI Improvements

- Widened label column for better readability (65 → 75 points)
- Fixed Japanese localization for "Hard Links" label

---

## Version 1.5.0

### 🆕 New Feature: System Metadata

A comprehensive new metadata section displaying macOS-specific file information:

#### Finder Integration
- **Finder Tags** - Display color-coded tags assigned in Finder
- **Finder Comments** - Show comments added via Get Info
- **Alias Resolution** - Display original file path for Finder aliases

#### Download Information
- **Download Source** - URL where the file was downloaded from
- **Download Date** - When the file was downloaded
- **Downloaded By** - Application used for downloading
- Powered by macOS quarantine attributes

#### File System Details
- **Symbolic Link Target** - Show where symlinks point to
- **Hard Link Count** - Number of hard links to the same inode
- **iCloud Status** - Downloaded, Cloud Only, Downloading, Uploading
- **UTI (Uniform Type Identifier)** - System type identifier
- **Extended Attributes Count** - Number of xattrs on the file

#### Usage Statistics
- **Open Count** - How many times the file has been opened
- **Last Used Date** - When the file was last accessed

### 🎬 Video HDR Detection

- Detects and displays HDR format for video files
- Supported formats: **Dolby Vision**, **HDR10**, **HLG**
- Shows color primaries (BT.709, BT.2020, P3) and transfer function

### 🌐 Localization

- Full localization for all new metadata fields
- Supported languages: English, Traditional Chinese (繁體中文), Japanese (日本語)

## Version 1.4.5

### 🐛 Bug Fixes

#### Multi-Monitor Positioning

- Fixed hover window appearing at incorrect position on secondary monitors
- Root cause: Coordinate conversion was using the current screen's height instead of the primary screen's height
- The Accessibility API uses a coordinate system with origin at the top-left of the primary screen, requiring primary screen height for correct conversion
- Improved screen detection logic for better multi-display support

#### Localization Fixes

- Fixed 40+ missing localization keys in Settings UI
- Added translations for all new metadata types (HTML, Markdown, Config, PSD, Executable, App Bundle, SQLite, Git)
- Full localization coverage for English, Traditional Chinese, and Japanese

#### Code Signing Fix

- Fixed accessibility permission not being recognized after app updates
- Ad-hoc sign with correct bundle identifier (`dev.koukeneko.FinderHover`) for TCC compatibility
- macOS TCC now properly tracks permissions across app updates

## Version 1.4.4

### 🐛 Bug Fixes

- Fixed duplicate/orphan divider lines in the hover window
  - Removed trailing dividers from all metadata sections
  - Prevents empty dividers when a section has no visible data
  - Cleaner UI when certain metadata fields are hidden

## Version 1.4.3

### 🐛 Bug Fixes

- Fixed Markdown files showing duplicate code file section
  - Markdown files now only display dedicated Markdown metadata
  - Removed redundant code file metrics for `.md` files

## Version 1.4.2

### 🐛 Bug Fixes

- Fixed missing localization keys for new metadata types
  - Added all missing hover window keys for HTML, Markdown, Image Extended, PSD, Executable, App Bundle, SQLite, and Git metadata
  - Full localization support for English, Traditional Chinese, and Japanese

## Version 1.4.1

### 🔧 Maintenance

- Minor stability improvements

## Version 1.4.0

### 🆕 Major Metadata Update - 9 New File Types

#### HTML/Web Files

- Page title and meta description
- Keywords and author
- Language attribute
- Supports `.html`, `.htm`, `.xhtml` files

#### Extended Image Metadata (IPTC/XMP)

- Creator and creator tool
- Headline and description
- Copyright information
- Enhanced metadata beyond basic EXIF

#### Markdown Files

- Title detection from frontmatter or first heading
- Frontmatter presence indicator
- Heading, image, link, and code block counts
- Supports `.md`, `.markdown` files

#### Config Files (JSON/YAML/TOML)

- Key count and nesting depth
- Array count detection
- Format-specific parsing
- Supports `.json`, `.yaml`, `.yml`, `.toml` files

#### PSD Files

- Layer count
- Color mode (RGB, CMYK, etc.)
- Bit depth
- Resolution (DPI)
- Transparency support

#### Executable Files (Mach-O)

- Architecture detection (arm64, x86_64, Universal)
- Code signing status
- Minimum OS version
- SDK version
- File type (executable, dylib, bundle)

#### App Bundles (.app)

- Bundle ID
- App version and build number
- Minimum macOS version
- Code signing status
- Entitlements count

#### SQLite Databases

- Table, index, trigger, and view counts
- Total row count across all tables
- Schema version
- Text encoding
- Native SQLite3 C API for better performance

#### Git Repositories

- Current branch name
- Total commit count
- Remote URL
- Uncommitted changes count
- Tag count

### 🔧 Technical Improvements

- **Native SQLite3 API**: Uses C API directly instead of CLI for faster database inspection
- **Settings Toggles**: Per-field visibility controls for all new metadata types
- **Full Localization**: All new metadata fields localized in English, Traditional Chinese, and Japanese

## Version 1.3.2

### 🌍 Localization Improvements

#### Shortened Field Labels for Better Layout

- **English labels** reduced to maximum 10 characters
  - "Uncompressed" → "Unpacked" (8 chars)
  - "Compressed" → "Packed" (6 chars)
  - "Compression" → "Ratio" (5 chars)
  - "Partition Scheme" → "Partition" (9 chars)
  - "PDF Version" → "Version" (7 chars)
- **Japanese labels** reduced to maximum 6 characters
  - "エンコーディング" → "文字符号" (4 chars)
  - "パーティション方式" → "方式" (2 chars)
  - "ファイルシステム" → "形式" (2 chars)
  - "ビューボックス" → "表示範囲" (4 chars)
  - "フレームレート" → "レート" (3 chars)
- **Chinese labels** already optimal (≤6 characters)
- Improves display consistency in compact windows
- Better layout for non-English locales
- Enhanced readability across all supported languages

## Version 1.3.1

### 🐛 Bug Fixes

#### Display Settings Scroll Performance

- Fixed display settings page freezing/spinning wheel when scrolling quickly
- Reverted LazyVStack back to VStack for better stability
- LazyVStack caused excessive view creation/destruction during fast scrolling
- Now provides smooth scrolling experience without crashes

### 🌍 Localization Improvements

#### Shortened Field Labels for Better Layout

- **English labels** reduced to maximum 10 characters
  - "Uncompressed" → "Unpacked" (8 chars)
  - "Compressed" → "Packed" (6 chars)
  - "Compression" → "Ratio" (5 chars)
  - "Partition Scheme" → "Partition" (9 chars)
- **Japanese labels** reduced to maximum 6 characters
  - "エンコーディング" → "文字符号" (4 chars)
  - "パーティション方式" → "方式" (2 chars)
  - "ファイルシステム" → "形式" (2 chars)
  - "ビューボックス" → "表示範囲" (4 chars)
  - "フレームレート" → "レート" (3 chars)
- **Chinese labels** already optimal (≤6 characters)
- Improves display consistency in compact windows
- Better layout for non-English locales
- Enhanced readability across all supported languages

**Technical Details:**

- LazyVStack was incompatible with 100+ Toggle bindings in DisplaySettingsView
- Frequent view recycling during fast scroll caused main thread blocking
- VStack provides stable view references and better performance in this scenario

## Version 1.3.0

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

## Version 1.1.0

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

## Version 1.0.0

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
