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

## ✨ Features

<img width="1926" height="1324" alt="image" src="https://github.com/user-attachments/assets/7d27934e-5e11-4196-a6ac-5c7ebc6a1f17" />


### 🎯 Core Features

- **Smart hover preview** with adjustable delay (0.1s - 2.0s)
- **QuickLook thumbnails** for PDFs, images, and documents
- **Rich file metadata** - size, dates, permissions, owner, path
- **Photo EXIF data** - camera, lens, settings, dimensions, GPS
- **Video metadata** - duration, resolution, codec, frame rate, bitrate
- **Audio metadata** - title, artist, album, genre, duration, bitrate, sample rate
- **Two UI styles** - macOS (rich) or Windows (minimal) tooltip design
- **Multi-language support** - English, 繁體中文, 日本語
- **Customizable display** - drag to reorder fields, toggle visibility
- **Auto-hide when renaming** - prevents interference with file operations

### 🎨 Customization

- Adjustable window size (300-600px) and font size (9-14pt)
- Native blur effect or custom opacity (70-100%)
- Compact mode for reduced spacing
- Launch at login support
- Recognizes 50+ file types with smart descriptions

### 🔒 Privacy First

- No network access - runs entirely locally
- No analytics or tracking
- Open source - inspect the code yourself

## 📦 Installation

### Download Release (Recommended)

1. Download `FinderHover.app.zip` from [Releases](../../releases)
2. Extract and move to Applications folder
3. Launch FinderHover

### Build from Source

```bash
git clone https://github.com/KoukeNeko/FinderHover.git
cd FinderHover
open FinderHover.xcodeproj
```

Press `Cmd+R` to build and run.

Or build from command line:

```bash
xcodebuild -project FinderHover.xcodeproj -scheme FinderHover -configuration Release build
```

Requires Xcode 15.0+ and macOS 14.0+.

## ⚙️ Setup

On first launch, grant **Accessibility permission**:

1. The app will prompt you to open System Settings
2. Navigate to **Privacy & Security** > **Accessibility**
3. Enable **FinderHover** (or **Xcode** during development)
4. **Restart the app**

> **Why?** FinderHover needs to monitor mouse position and detect which file is selected in Finder.

## 🚀 Usage

### Quick Start

1. Launch FinderHover - it appears in your menu bar
2. Open Finder and hover over any file
3. Wait 0.1 seconds (customizable)
4. Preview window appears with file details

> **Note**: On macOS Sonoma (14.x), you may need to select a file first. On Sequoia (15.x)+, just hover.

### Settings

Press `Cmd+,` to customize:

#### Behavior

- Hover delay, auto-hide, launch at login, window position, language

#### Appearance

- UI style (macOS/Windows), blur effect, opacity, compact mode, window size, font size

#### Display

- Toggle fields (icon, type, size, dates, permissions, owner, path)
- Photo EXIF (camera, lens, settings, GPS, dimensions)
- Video (duration, resolution, codec, frame rate, bitrate)
- Audio (title, artist, album, genre, year, duration, bitrate, sample rate)
- Drag to reorder

## 📸 Screenshots

### Hover Preview

<img width="942" height="454" alt="image" src="https://github.com/user-attachments/assets/fe969256-a07d-4db6-8715-a3bb3226782b" />
<img width="938" height="513" alt="image" src="https://github.com/user-attachments/assets/f492dc51-9fd8-49f2-b854-d9fc4ac026a6" />

### Settings Interface

<img width="762" height="644" alt="image" src="https://github.com/user-attachments/assets/7978cc15-cf16-455b-856b-683a5fc82b19" />
<img width="762" height="644" alt="image" src="https://github.com/user-attachments/assets/33bbc116-ded6-481c-876b-32ee35199845" />

## 📝 What's New in Version 1.2.4.1

### 📦 New DMG Installer

Now available as a DMG disk image for easier installation! Simply drag FinderHover.app to your Applications folder.

**What's New:**

- 💿 DMG installer with drag-to-Applications interface
- 🔧 Automated build script for consistent releases
- 📝 Improved installation experience

### Previous Update (v1.2.4)

- 🐛 **Bug Fix**: Hover window persistence on app switch - Fixed window not disappearing when switching apps via Spotlight
- 🔄 **Update Checker**: Changed from automatic download to opening GitHub Release page for transparency

### Previous Update (v1.2.3)

- 🐛 Bug Fix: Windows Style Border - Fixed inconsistent border styling for Windows tooltip mode
- 🎨 UI Icon Improvements - Updated icons to outlined versions
- ✨ Auto-hide When Renaming - Hides hover window when renaming files

📋 [View Full Changelog](CHANGELOG.md)

## ❓ Troubleshooting

**Hover window not appearing?**

1. Check Accessibility permission (System Settings > Privacy & Security > Accessibility)
2. Ensure file is selected (highlighted in blue) - macOS requirement
3. Verify app is running (check menu bar)
4. Adjust hover delay in Settings if needed

**Settings not saving?**

```bash
defaults delete dev.doeshing.FinderHover
```

Then restart to reset to defaults.

## 🛠️ Development

### Tech Stack

- Swift 5.0, SwiftUI, AppKit
- QuickLookThumbnailing, ImageIO, AVFoundation
- Accessibility Framework, Combine

### Requirements

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Apple Silicon or Intel Mac

### Project Structure

```
FinderHover/
├── FinderHoverApp.swift      # Main app & menu bar
├── AppSettings.swift          # Settings model
├── SettingsView.swift         # Settings UI
├── HoverWindow.swift          # Preview window
├── HoverManager.swift         # Coordination
├── MouseTracker.swift         # Mouse events
├── FinderInteraction.swift   # Accessibility API
├── FileInfo.swift             # File metadata
├── IconManager.swift          # Centralized SF Symbols management
└── Resources/                 # Localizations (en, zh-Hant, ja)
```

## 🤝 Contributing

Contributions welcome!

- Report bugs via [Issues](../../issues)
- Suggest features via [Discussions](../../discussions)
- Submit pull requests

## 🙏 Acknowledgments

- Inspired by [my final dream ULTIMATE productivity desk setup. (2026)](https://youtu.be/veum1I6G__g?si=CDWpYV9anOszM6ai&t=375)
- Built with Apple's SwiftUI and Accessibility frameworks
- Icons from SF Symbols

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Made with Swift & SwiftUI** 🚀

**Privacy Protected** - Only reads file metadata, never file contents. No network access, no analytics, fully open source.
