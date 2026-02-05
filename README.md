# FinderHover

**The missing "Data HUD" for macOS.**
Inspect file metadata instantly. No `Cmd+I` required.

<p align="center">
  <a href="README.md">🇺🇸 English</a> | <a href="README_zh-Hant.md">🇹🇼 繁體中文</a> | <a href="README_ja.md">🇯🇵 日本語</a>
</p>

<p align="center">
  <img src="/FinderHover/Assets.xcassets/AppIcon.appiconset/Icon-256.png" alt="FinderHover Icon" width="128">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-000000.svg?style=flat&logo=apple&logoColor=white" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Swift-5.0-F05138.svg?style=flat&logo=swift&logoColor=white" alt="Swift 5.0">
  <img src="https://img.shields.io/badge/SwiftUI-007AFF.svg?style=flat&logo=swift&logoColor=white" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Privacy%20First-00C853.svg?style=flat&logo=apple&logoColor=white" alt="Privacy First">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat" alt="License MIT">
</p>

---

> **🎬 Demo Coming Soon:** We're preparing a GIF/Video demo showing FinderHover in action.
> *For now, check out the [screenshots below](#-screenshots) to see what it looks like.*

<img width="1926" height="1324" alt="Feature Overview" src="https://github.com/user-attachments/assets/7d27934e-5e11-4196-a6ac-5c7ebc6a1f17" />

---

## ⚡️ Why FinderHover?

**The Problem:**
Want to check image resolution? Video codec? Zip contents? You have to:
1. Right-click → Get Info (or press `Cmd+I`)
2. Wait for the window to open
3. Close it manually
4. Repeat for every file

**The Solution:**
FinderHover acts as an **X-ray layer** over Finder. Just hover your mouse over any file, and see the data that matters—instantly.

### Comparison: Get Info vs FinderHover

|  | macOS Get Info (`Cmd+I`) | FinderHover |
|---|---|---|
| **Trigger** | Right-click → Get Info (or `Cmd+I`) | Hover mouse |
| **Speed** | Slow, window stacks up | Instant, auto-hides |
| **Depth** | Basic (size, kind, dates) | **Deep metadata** (EXIF, codecs, archive contents, Git info) |
| **Workflow** | Interrupts your flow | Non-intrusive overlay |

---

## ✨ Features

### 🔍 Beyond Finder
FinderHover reveals metadata that Finder **never shows**:

#### 📦 X-Ray for Archives
Peek inside `zip`, `rar`, `7z`, `tar.gz`, and `iso` files **without extracting them**.
- 📋 Instantly see file lists & file counts
- 🔐 Detect encryption status (know if it's password-protected before opening)
- 📊 Check compression ratios and real uncompressed sizes

#### 💻 Developer Centric
Built by a developer, for developers.
- **Code Insights:** Instant line counts and syntax detection for **38+ languages**
- **Git Aware:** See current branch, commit count, remote URL, and uncommitted changes on repo folders
- **Binary Analysis:** Inspect Mach-O headers, architectures (`arm64`/`x86_64`/Universal), code signing status, and SDK versions for executables
- **Xcode Projects:** View targets, build configurations, Swift version, and deployment targets

#### 📸 Photography & Media
- **Photos:** Camera model, lens info, focal length, ISO, aperture, shutter speed, GPS coordinates, IPTC/XMP metadata (author, copyright, keywords, rating)
- **Videos:** Codec (H.264, HEVC, etc.), resolution, bitrate, frame rate, HDR format (Dolby Vision, HDR10, HLG), chapters, subtitle tracks
- **Audio:** Track name, artist, album, genre, duration, bitrate, sample rate, channels

---

### 🎨 Smart & Customizable

#### 🧠 Intelligent Context Awareness
- **Instant Preview:** Adjustable hover delay (0.1s - 2.0s)
- **Auto-Hide:** Disappears when renaming files, dragging items, or using context menus
- **QuickLook Integration:** Native thumbnails for PDFs, images, and documents

#### 🌈 Dual Personalities
- **macOS Style:** Rich visual presentation with thumbnails, icons, and full metadata
- **Windows Style:** Minimal tooltip-style display with essential info only

#### 🎛️ Full Control
- Adjustable window size, opacity (70-100%), and font scaling
- **Layout Editor:** Drag-to-reorder metadata fields and toggle visibility per category
- **Localization:** Native support for **English**, **Traditional Chinese (繁體中文)**, and **Japanese (日本語)**

---

### 📊 Rich Metadata Support (120+ File Formats)

| Category | Supported Metadata |
|----------|-------------------|
| **📷 Photography** | Camera model, lens, ISO, aperture, shutter speed, GPS, IPTC/XMP data, color profiles, HDR gain maps |
| **🎬 Video** | Codec, resolution, bitrate, frame rate, HDR formats (Dolby Vision, HDR10, HLG), chapters, subtitle tracks |
| **🎵 Audio** | Track name, artist, album, genre, duration, bitrate, sample rate, channels |
| **💻 Code** | Line counts for 38+ languages, file encoding, syntax detection |
| **📝 Markdown** | Title, frontmatter (YAML/TOML/JSON), heading/image/link/code block counts |
| **🌐 HTML/Web** | Title, meta description, keywords, author, language, Open Graph tags |
| **⚙️ Config** | JSON/YAML/TOML key counts, nesting depth, syntax validity |
| **🎨 Design** | PSD layers/color mode/bit depth, SVG/AI dimensions, font glyphs |
| **📦 Archives** | Format type, file count, compression ratio, encryption status |
| **📚 eBooks** | Title, author, publisher, ISBN, language |
| **🖼️ Vector** | SVG viewBox, EPS color mode, element counts |
| **📱 App Bundles** | Bundle ID, version, minimum macOS, code signing, entitlements, architectures |
| **⚡ Executables** | Architecture (arm64/x86_64), code signing, minimum OS, SDK version |
| **🗄️ SQLite** | Table/index/trigger/view counts, total rows, schema version, encoding |
| **📂 Git Repos** | Current branch, commit count, remote URL, uncommitted changes, tags |
| **💿 Disk Images** | Format (DMG, ISO), compression ratio, encryption status, partition scheme |
| **🧊 3D Models** | Vertex/face counts, mesh/material counts, animations, bounding box |
| **🛠️ Xcode** | Project name, targets, build configs, Swift version, deployment target |
| **🏷️ System** | Finder tags, download source, quarantine info, iCloud status, symlink targets |

---

## 🛡️ Privacy First

> **100% Local Processing.**
> FinderHover uses the macOS **Accessibility API** to detect the file under your cursor. All metadata extraction happens **on your machine**—no network requests, no analytics, no tracking.

- ✅ **Zero Network Access:** All processing happens locally
- ✅ **Open Source:** Inspect the code yourself on GitHub
- ✅ **Apple Native:** Built with Swift, AVFoundation, PDFKit, and other native frameworks

**Why Accessibility API?**
Unlike legacy tools that rely on slow AppleScript polling, FinderHover listens to the system's accessibility event stream for high performance and minimal overhead.

---

## 📦 Installation

### Homebrew (Recommended)

```bash
brew install koukeneko/tap/finderhover
```

**Why Homebrew?** It automatically handles Gatekeeper verification, so you don't need to manually allow the app in System Settings.

---

### Direct Download

1. Download `FinderHover.app.zip` from [Releases](../../releases)
2. Extract and move to Applications folder
3. Right-click → Open (to bypass Gatekeeper)
4. Grant Accessibility permission when prompted

---

### Build from Source

```bash
git clone https://github.com/KoukeNeko/FinderHover.git
cd FinderHover
xcodebuild -scheme FinderHover -configuration Release
```

**Requirements:** Xcode 15+ and macOS Sonoma 14.0+

---

## ⚙️ Setup & Usage

### First Launch

1. Launch FinderHover from Launchpad or Applications
2. The app appears in your **Menu Bar**
3. Grant **Accessibility permission** (System Settings → Privacy & Security → Accessibility)
4. Hover over any file in Finder to see metadata

### Settings

Click the menu bar icon or press `Cmd+,` to access the settings panel.

**Tip:** Enable "Launch at Login" to start FinderHover automatically when you boot your Mac.

---

## 🚀 Technical Highlights

### ⚡️ High-Performance Architecture
- **Reactive UI Updates:** Leverages **Combine** framework with `debounce` operators to ensure fluid UI updates while keeping CPU usage negligible
- **Native Frameworks:** Built on Apple's `AVFoundation`, `PDFKit`, `QuickLookThumbnailing`, `SQLite3`, and `CoreGraphics`—no external dependencies
- **Smart Caching:** Thumbnail and metadata caching reduces redundant processing

### 🛠️ Robust Metadata Engine
Supports **120+ file formats** with deep inspection capabilities:
- **Archives:** Reads zip/rar/7z/iso structure without extraction (using `libarchive` and native APIs)
- **Media:** Extracts video codecs, HDR metadata, and audio specs using `AVFoundation`
- **Code:** Detects 38+ programming languages with accurate line counting
- **Git:** Parses `.git` directory for branch, commit, and remote info
- **Binaries:** Analyzes Mach-O headers for architecture and code signing

---

## 🛠️ Project Structure

```
FinderHover/
├── App/          # Application lifecycle (FinderHoverApp, HoverManager)
├── Core/         # MouseTracker, FinderInteraction, FileInfo
├── Extractors/   # Metadata extraction logic (ArchiveExtractor, DeveloperExtractor, etc.)
├── UI/
│   ├── Windows/  # Floating hover window, settings container
│   └── Settings/ # Modular settings pages
└── Utilities/    # Localization, logging, formatting helpers
```

---

## 📸 Screenshots

<p float="left">
  <img src="https://github.com/user-attachments/assets/fe969256-a07d-4db6-8715-a3bb3226782b" width="45%" />
  <img src="https://github.com/user-attachments/assets/f492dc51-9fd8-49f2-b854-d9fc4ac026a6" width="45%" />
</p>
<p float="left">
  <img src="https://github.com/user-attachments/assets/dc04ba05-2bcb-4308-b0cc-bd5ed2259d07" width="45%" />
  <img src="https://github.com/user-attachments/assets/140accdd-6034-4b2d-b4d9-ccc55a28586c" width="45%" />
</p>

---

## 📝 What's New

### v1.7.0 - Advanced Metadata Update
- **New:** 3D model metadata (USDZ, OBJ, GLTF, FBX)
- **New:** Xcode project inspection (targets, Swift version, deployment target)
- **New:** Advanced file system metadata (allocated space, resource fork, volume info)
- **Enhanced:** Archive format support (added ISO, TAR, CPIO)
- **Enhanced:** System metadata (Finder tags, download source, iCloud status)

[View Full Changelog](CHANGELOG.md)

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

- **Add Extractors:** Check out [Core/FileInfo.swift](FinderHover/Core/FileInfo.swift) for metadata extraction logic
- **UI Improvements:** Explore [UI/Windows/](FinderHover/UI/Windows/) for visual enhancements
- **Localization:** Add translations in [Localizable.strings](FinderHover/Utilities/Localizable.strings)

**Feature Requests & Bug Reports:** Open an issue on [GitHub Issues](../../issues).

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

<p align="center">
  <strong>Made with ❤️ and Swift</strong><br>
  Built for Power Users, Developers, and File Hoarders
</p>
