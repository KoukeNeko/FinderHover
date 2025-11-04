# FinderHover

A beautiful, highly customizable macOS menu bar app that displays rich file information when hovering over files in Finder, similar to Windows file preview behavior.



<p align="center">
  <img src="/FinderHover/Assets.xcassets/AppIcon.appiconset/Icon-256.png" alt="Icon-256">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue.svg" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg" alt="Swift 5.0">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License MIT">
</p>

## 📑 Table of Contents
- [Features](#-features)
- [Installation](#-installation)
- [Usage](#-usage)
- [How It Works](#-how-it-works)
- [Settings](#-settings)
- [Development](#-development)
- [Troubleshooting](#-troubleshooting)
- [Privacy](#-privacy)
- [Screenshots](#-screenshots)
- [Changelog](#-changelog)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features
![A6700471](https://github.com/user-attachments/assets/455d868a-7e7d-4e8c-84bb-e032a6feffbf)


### 🎯 Smart Hover Preview
- **Instant response**: Adjustable hover delay (0.1s - 2.0s, default: 0.1s)
- Automatically shows detailed file information when you hover over selected files in Finder
- Smart window positioning that avoids screen edges
- Auto-hide when mouse moves away from file
- **Drag operation detection** - Automatically hides during file drag operations
- **Launch at login** - Optional automatic startup with macOS

### 📊 Rich Information Display
- **Full filename** with automatic wrapping for long names
- **QuickLook thumbnails** - Shows actual file previews for PDFs, images, documents
  - Async loading for instant window display
  - Falls back to standard icons if preview unavailable
- **Smart file type descriptions** (recognizes 50+ file types)
  - "PDF Document", "PowerPoint Presentation", "Photoshop Document", etc.
- **Comprehensive file metadata**:
  - File size in human-readable format (KB, MB, GB)
  - Creation date with date and time
  - Modification date with date and time
  - **Last access date** (optional)
  - **Item count** for folders (optional)
  - **File permissions** in octal format with rwx notation (optional)
  - **Owner information** (optional)
- **Photo EXIF Information** - Detailed metadata for image files:
  - Camera model (e.g., "Canon EOS R5")
  - Lens information (e.g., "RF 24-70mm F2.8 L IS USM")
  - Camera settings (focal length, aperture, shutter speed, ISO)
  - Date taken with original timestamp
  - Image dimensions (width × height)
  - GPS location data (optional, privacy-aware)
  - Supports: JPEG, PNG, TIFF, HEIC, RAW formats (CR2, NEF, ARW, DNG, etc.)
- **Video Metadata** - Comprehensive information for video files:
  - Duration (formatted as hours:minutes:seconds)
  - Resolution (width × height in pixels)
  - Video codec (e.g., "avc1", "hvc1")
  - Frame rate (e.g., "30 fps", "60 fps")
  - Bitrate (Mbps or kbps)
  - Supports: MP4, MOV, M4V, AVI, MKV, FLV, WMV, WebM, MPEG, MPG, 3GP, MTS, M2TS
- **Audio Metadata** - Detailed information for audio files:
  - Song title, artist, album, genre, year
  - Duration (formatted as minutes:seconds)
  - Bitrate (kbps)
  - Sample rate (kHz or Hz)
  - Channel configuration (Mono, Stereo, multi-channel)
  - Supports: MP3, M4A, AAC, WAV, FLAC, AIFF, AIF, WMA, OGG, Opus, ALAC
- **Complete file path** with text selection support (no truncation)
- **Perfect icon alignment** across all information rows
- **Dynamic window height** - Automatically adjusts to content length
- **Customizable display order** - Drag and drop to reorder information fields

### 🎨 Modern & Customizable Design
- **Two UI Styles** - Choose between macOS and Windows tooltip styles
  - **macOS Style**: Rich preview with icons, thumbnails, rounded corners, and detailed metadata
  - **Windows Style**: Clean, minimalist text-only display inspired by Windows File Explorer
- **Native blur effect** - macOS-style background blur (toggleable)
  - Professional HUD window appearance
  - Smooth rounded corners (macOS style only)
- **Adjustable transparency** - Window opacity (70% - 100%)
  - Note: Only available when blur effect is disabled
- **Compact mode** - Reduced spacing and padding for a more compact layout
- Customizable window size (300px - 600px)
- Adjustable font size (9pt - 14pt)
- Toggle individual information fields on/off
- Adapts to filename and path length automatically

### ⚙️ Professional Settings Interface
- **macOS-native sidebar navigation** (like System Settings)
- Three organized setting pages:
  - **Behavior**: Hover delay, auto-hide, launch at login, window positioning, language selection
  - **Appearance**: Blur effect, opacity, compact mode, window size, font size
  - **Display**: Toggle which information to show (10+ options)
- Real-time preview of all changes
- Contextual hints (e.g., opacity setting availability)
- One-click reset to defaults
- Keyboard shortcut: `Cmd+,`

### 🌐 Multi-Language Support
- **Three languages fully supported**:
  - 🇺🇸 English
  - 🇹🇼 繁體中文 (Traditional Chinese)
  - 🇯🇵 日本語 (Japanese)
- **System Default option** - Automatically follows your macOS language settings
- **In-app language switcher** - Change language without leaving the app
- **One-click restart** - Apply language changes instantly
- **Complete localization** - All UI elements, settings, and menus translated

### ⚡ Performance & Privacy
- **Lightweight**: Minimal CPU and memory usage
- **Menu bar app**: Runs quietly in the background
- **Privacy-first**: Uses only Accessibility APIs (no AppleScript)
- **No network access**: Runs entirely locally on your Mac
- **No analytics or tracking**
- **Open source**: Inspect the code yourself

## 📦 Installation

### Option 1: Build from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/FinderHover.git
   cd FinderHover
   ```

2. **Open in Xcode**
   ```bash
   open FinderHover.xcodeproj
   ```

3. **Configure signing**
   - Select your development team in project settings
   - Update bundle identifier if needed

4. **Build and run**
   - Press `Cmd+R` or click the Run button
   - App will launch with Xcode's entitlements
   - The app will appear in your menu bar with an eye icon

#### Building from Command Line

For command line builds without opening Xcode:

1. **Build the app (Debug)**
   ```bash
   xcodebuild -project FinderHover.xcodeproj -scheme FinderHover -configuration Debug build
   ```

2. **Find the built .app file**
   ```bash
   # The .app is located in DerivedData:
   find ~/Library/Developer/Xcode/DerivedData/FinderHover-* -name "FinderHover.app" -type d
   ```

3. **Copy to Applications or Desktop**
   ```bash
   # Copy to Desktop
   cp -r ~/Library/Developer/Xcode/DerivedData/FinderHover-*/Build/Products/Debug/FinderHover.app ~/Desktop/

   # Or copy to Applications
   cp -r ~/Library/Developer/Xcode/DerivedData/FinderHover-*/Build/Products/Debug/FinderHover.app /Applications/
   ```

4. **Build for Release**
   ```bash
   xcodebuild -project FinderHover.xcodeproj -scheme FinderHover -configuration Release build
   ```

> **Note**: Debug builds can be run locally without an Apple Developer Program membership. Release builds for distribution require signing with a valid developer certificate.

### Option 2: Download Release
- Download the latest `.app` from [Releases](../../releases)
- Move to Applications folder
- Launch FinderHover

## ⚙️ Setup

### First Launch
On first launch, you only need to grant **one permission**:

#### Accessibility Permission
The app will automatically prompt you to enable Accessibility access:

1. Click **"Open System Settings"** when prompted (or manually go to System Settings)
2. Navigate to **Privacy & Security** > **Accessibility**
3. Click the **🔒 lock icon** to unlock (enter your password)
4. Enable **FinderHover** (or **Xcode** during development) in the list
5. **Restart the app**

> **Why this permission?**
> FinderHover needs Accessibility permission to:
> - Monitor mouse position globally
> - Detect which file is selected in Finder
> - Display the hover window at the correct position

## 🚀 Usage

### Basic Usage
1. **Launch FinderHover** - it will appear in your menu bar with an 👁️ icon
2. **Open Finder** and navigate to any folder
3. **Hover your mouse** over any file name
4. **Wait 0.1 seconds** (customizable)
5. A beautiful preview window appears showing file details!

> **Note for macOS Sonoma (14.x) users**: On older macOS versions, you may need to click to select a file first before hovering. On macOS Sequoia (15.x) and later, simply hovering over the file name is sufficient - the Finder window doesn't even need to be focused!

### Menu Bar Options
Click the 👁️ icon in your menu bar to access:

- **Enable/Disable Hover Preview** - Toggle the hover functionality on/off (`Cmd+E`)
- **Settings...** - Open the settings window (`Cmd+,`)
- **About FinderHover** - View app information (`Cmd+A`)
- **Quit** - Close the application (`Cmd+Q`)

### Customization
Open **Settings** (`Cmd+,`) to customize:

#### Behavior Tab
- **Hover Delay**: 0.1s - 2.0s (how long to wait before showing preview)
- **Auto-hide**: Instantly hide window when mouse moves away
- **Launch at Login**: Automatically start FinderHover when you log in
- **Window Position**: Adjust horizontal/vertical offset from cursor (0-50px)
- **Language**: Choose app language (English, 繁體中文, 日本語, or System Default)
  - One-click restart button appears when language is changed

#### Appearance Tab
- **UI Style**: Choose between macOS or Windows tooltip style
  - **macOS Style**: Rich preview with icons, thumbnails, and detailed metadata
  - **Windows Style**: Clean, text-only display with essential information (Type, Size, Date modified)
- **Blur Effect**: Enable/disable native macOS background blur
- **Window Opacity**: 70% - 100% (transparency level)
  - Only available when blur effect is disabled
- **Compact Mode**: Reduced spacing and padding for a more compact layout
- **Maximum Width**: 300px - 600px (window size)
- **Font Size**: 9pt - 14pt (all text scales proportionally)

#### Display Tab
Toggle what information to show:
- ☑️ File Icon
- ☑️ File Type
- ☑️ File Size
- ☑️ Item Count (for folders)
- ☑️ Creation Date
- ☑️ Modification Date
- ☑️ Last Access Date
- ☑️ Permissions (file mode)
- ☑️ Owner
- ☑️ File Path
- ☑️ **Photo Information (EXIF)** - for image files
  - Camera Model
  - Lens Model
  - Camera Settings (focal length, aperture, shutter speed, ISO)
  - Date Taken
  - Image Dimensions
  - GPS Location
- ☑️ **Video Information** - for video files
  - Duration
  - Resolution
  - Codec
  - Frame Rate
  - Bitrate
- ☑️ **Audio Information** - for audio files
  - Song Title
  - Artist
  - Album
  - Genre
  - Year
  - Duration
  - Bitrate
  - Sample Rate

**Display Order Customization:**

- Drag and drop items to reorder them in the hover window
- EXIF information moves as a complete group
- Changes save automatically and apply in real-time

> **💡 Tip**: All settings apply **instantly** - no need to restart!

## 🔧 How It Works

The app uses modern macOS technologies:

- **Accessibility API**: Monitors mouse position globally and retrieves file information from Finder
- **QuickLook API**: Generates thumbnail previews for files asynchronously
- **ImageIO**: Extracts EXIF metadata from image files (camera, lens, settings, GPS)
- **AVFoundation**: Extracts video and audio metadata (duration, codec, bitrate, ID3 tags)
- **SwiftUI**: Renders the beautiful hover window with adaptive sizing and reactive updates
- **AppKit**: Manages window positioning, screen boundary detection, and visual effects
- **NSVisualEffectView**: Native blur effects with HUD window material
- **Combine**: Reactive updates for settings and mouse tracking
- **UserDefaults**: Persistent settings storage with JSON encoding for complex data
- **Menu Bar Integration**: Runs as a lightweight background app (LSUIElement)

### Technical Architecture

```
FinderHoverApp (Menu Bar)
    ↓
HoverManager (Coordination)
    ↓
    ├── MouseTracker (Global mouse events)
    ├── FinderInteraction (Accessibility API)
    └── HoverWindow (SwiftUI preview)
            ↓
        AppSettings (User preferences)
```

**Note**: The app works with **selected files** in Finder. Select a file (click it), then hover your mouse over it to see the preview.

### Limitations
Due to macOS security restrictions:
- Requires file to be **selected first** (highlighted in blue)
- True "hover-only" detection (without selection) is not possible
- Requires Accessibility permission to function

## 📋 Requirements

- **macOS 14.0 or later** (Sonoma)
  - Compatible with macOS 15.0 (Sequoia) and future versions
- **Accessibility permissions** (automatically prompted on first launch)
- **Xcode 15.0+** for building from source
- **Apple Silicon** or **Intel** Mac

## Privacy & Security

FinderHover is designed with privacy in mind:
- ✅ Only accesses file metadata (name, size, dates, paths)
- ✅ Does not read file contents
- ✅ Does not send any data over the network
- ✅ No analytics or tracking
- ✅ Runs entirely locally on your Mac
- ✅ Uses Accessibility API only (no AppleScript automation)
- ✅ Open source - inspect the code yourself!

## 🛠️ Development

### Technology Stack
- **Swift 5.0** - Modern, safe programming language
- **SwiftUI** - Declarative UI framework with reactive updates
- **AppKit** - Native window management and visual effects
- **QuickLookThumbnailing** - File preview thumbnail generation
- **ImageIO** - EXIF metadata extraction from image files
- **AVFoundation** - Video and audio metadata extraction (duration, codec, bitrate, ID3 tags)
- **NSVisualEffectView** - Native blur and vibrancy effects
- **Accessibility Framework** - File detection and mouse tracking
- **Combine** - Reactive programming for settings and events
- **UserDefaults** - Persistent settings storage with Codable support

### Project Structure
```
FinderHover/
├── FinderHoverApp.swift      # Main app & menu bar
├── AppSettings.swift          # Settings model with UserDefaults & language
├── SettingsView.swift         # Settings UI (sidebar navigation)
├── HoverWindow.swift          # Preview window with SwiftUI
├── HoverManager.swift         # Coordination layer
├── MouseTracker.swift         # Global mouse events
├── FinderInteraction.swift   # Accessibility API integration
├── FileInfo.swift             # File metadata model
├── Info.plist                 # App permissions
└── Resources/                 # Localization files
    ├── en.lproj/
    │   └── Localizable.strings      # English
    ├── zh-Hant.lproj/
    │   └── Localizable.strings      # Traditional Chinese
    └── ja.lproj/
        └── Localizable.strings      # Japanese
```

### Key Components

**HoverManager**
- Coordinates mouse tracking and window display
- Manages hover delay and auto-hide behavior
- Integrates with AppSettings for customization

**MouseTracker**
- Monitors global mouse movement events
- Publishes location updates via Combine
- Detects hover duration

**FinderInteraction**
- Uses Accessibility API to query Finder
- Retrieves selected file information
- No AppleScript required (pure Accessibility)

**HoverWindow**
- SwiftUI-based preview window
- Adapts size based on content and settings
- Smart positioning with screen boundary detection

**AppSettings**
- ObservableObject for reactive updates
- Persists all user preferences
- Publishes changes to SwiftUI views

### Supported File Types (50+)

The app recognizes and provides smart descriptions for:

**Documents**
- PDF, Word (.doc, .docx), Excel (.xls, .xlsx), PowerPoint (.ppt, .pptx)
- Pages, Numbers, Keynote (Apple iWork)
- Text (.txt, .rtf, .md), CSV, JSON, XML

**Images**
- JPEG, PNG, GIF, SVG, BMP, TIFF
- Photoshop (.psd), Illustrator (.ai), Sketch

**Media**
- Video: MP4, MOV, AVI, MKV
- Audio: MP3, WAV, AAC, FLAC

**Archives**
- ZIP, RAR, 7Z, TAR, GZIP
- DMG, ISO, PKG (macOS installers)

**Code**
- Swift, Python, JavaScript, TypeScript
- Java, C, C++, PHP
- HTML, CSS, Shell scripts

**Other**
- Applications (.app)
- And any file type with extension

## 🤝 Contributing

Contributions are welcome! Please feel free to:
- Report bugs via [Issues](../../issues)
- Suggest features via [Discussions](../../discussions)
- Submit pull requests

**Development Guidelines:**
- Follow Swift API Design Guidelines
- Maintain SwiftUI best practices
- Keep accessibility in mind
- Test on multiple macOS versions
- Update README for new features

## ❓ Troubleshooting

### Hover window not appearing?

1. **Check Accessibility Permission**
   - Go to System Settings > Privacy & Security > Accessibility
   - Ensure FinderHover is enabled and checked ✓
   - If not listed, click **+** and add the app manually

2. **Ensure File is Selected**
   - The app requires you to **click the file first** (it should highlight in blue)
   - Then hover your mouse over the selected file
   - This is a macOS security limitation

3. **Check App is Running**
   - Look for the 👁️ icon in your menu bar
   - Click it and ensure "Enable Hover Preview" is checked

4. **Verify Hover Delay**
   - Open Settings (`Cmd+,`) > Behavior
   - Check your hover delay setting (default: 0.1s)
   - Try increasing it to 0.5s if it appears too fast

5. **Try Restarting**
   - Quit FinderHover from menu bar
   - Relaunch the app

### Window appears in wrong position?

- Open Settings > Behavior > Window Position
- Adjust horizontal/vertical offset values
- Window should stay within screen bounds automatically

### Text is too small/large?

- Open Settings > Appearance > Font Size
- Adjust between 9pt - 14pt
- All text scales proportionally

### Performance issues?

- The app is highly optimized and uses minimal resources
- Try disabling unused information in Settings > Display
- Reduce window opacity in Settings > Appearance
- You can temporarily disable it from the menu bar

### Settings not saving?

- Settings are automatically saved to UserDefaults
- If issues persist, try:
  ```bash
  defaults delete dev.doeshing.FinderHover
  ```
- Then restart the app (settings will reset to defaults)

## 📸 Screenshots

### Hover Preview Window
<img width="942" height="454" alt="image" src="https://github.com/user-attachments/assets/fe969256-a07d-4db6-8715-a3bb3226782b" />
<img width="938" height="513" alt="image" src="https://github.com/user-attachments/assets/f492dc51-9fd8-49f2-b854-d9fc4ac026a6" />
*Beautiful preview with complete file information*

### Settings - Sidebar Navigation
<img width="762" height="644" alt="image" src="https://github.com/user-attachments/assets/7978cc15-cf16-455b-856b-683a5fc82b19" />
*Professional macOS-native settings interface*

### Settings Tabs
<img width="762" height="644" alt="image" src="https://github.com/user-attachments/assets/33bbc116-ded6-481c-876b-32ee35199845" />
*Customize every aspect of the app*

## 📝 Changelog

### Version 1.1.3 (Current)

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

### Version 1.1.2

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

### Version 1.1.1

- 🌐 **NEW: Multi-Language Support**
  - Three languages fully supported: English, 繁體中文 (Traditional Chinese), 日本語 (Japanese)
  - System Default option automatically follows macOS language settings
  - In-app language switcher with one-click restart
  - Complete localization of all UI elements, settings, and menus
  - Consistent vertical slider layouts across all settings pages

### Version 1.1

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

### Version 1.0

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

## 🙏 Acknowledgments

- Inspired by [this video showcasing Windows file preview functionality](https://youtu.be/veum1I6G__g?si=CDWpYV9anOszM6ai&t=375)
- Built with Apple's SwiftUI and Accessibility frameworks
- Icons from SF Symbols

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

Created with ❤️ for macOS users who want a better Finder experience.
---

**Note**: This app requires **Accessibility permission** to function. Your privacy is protected - the app:
- ✅ Only reads file metadata (name, size, dates, path)
- ✅ Does NOT read file contents
- ✅ Does NOT send any data over the network
- ✅ Does NOT collect analytics or telemetry
- ✅ Runs entirely locally on your Mac
- ✅ Open source - inspect the code yourself

**Made with Swift & SwiftUI** 🚀
