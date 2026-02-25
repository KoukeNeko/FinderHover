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
  <img src="https://img.shields.io/github/v/release/KoukeNeko/FinderHover?style=for-the-badge&logo=github&logoColor=white&label=Release" alt="Release">
  <img src="https://img.shields.io/github/downloads/KoukeNeko/FinderHover/total?style=for-the-badge&logo=github&logoColor=white&label=Downloads" alt="Downloads">
  <img src="https://img.shields.io/badge/Homebrew-Available-FBB040?style=for-the-badge&logo=homebrew&logoColor=white" alt="Homebrew">
  <img src="https://img.shields.io/badge/macOS-14.0+-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Swift-5.0-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 5.0">
  <img src="https://img.shields.io/github/license/KoukeNeko/FinderHover?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/github/stars/KoukeNeko/FinderHover?style=for-the-badge&logo=github&logoColor=white" alt="Stars">
</p>

---

<p align="center">
  <img src="docs/demo.gif" alt="FinderHover Demo" width="800">
</p>

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

---

### Direct Download

1. Download `FinderHover.app.zip` from [Releases](../../releases)
2. Extract and move to Applications folder
3. Grant Accessibility permission when prompted

---

### Build from Source

```bash
git clone https://github.com/KoukeNeko/FinderHover.git
cd FinderHover
xcodebuild -scheme FinderHover -configuration Release
```

**Requirements:** Xcode 15+ and macOS Sonoma 14.0+

> **Note:** macOS 26.4 Beta 1 is not supported. Please update to Beta 2 or later.

---

## ⚙️ Setup & Usage

### First Launch

1. Launch FinderHover from Launchpad or Applications
2. The app appears in your **Menu Bar**
3. Grant **Accessibility permission** (System Settings → Privacy & Security → Accessibility)
4. Hover over any file in Finder to see metadata

### Settings

Click the menu bar icon to access the settings panel.

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

<img width="892" height="652" alt="image" src="https://github.com/user-attachments/assets/3632e479-b156-4927-b4fe-cca9a195895a" />


  <img src="https://github.com/user-attachments/assets/fe969256-a07d-4db6-8715-a3bb3226782b" width="45%" />
  <img src="https://github.com/user-attachments/assets/f492dc51-9fd8-49f2-b854-d9fc4ac026a6" width="45%" />
  <img src="https://github.com/user-attachments/assets/dc04ba05-2bcb-4308-b0cc-bd5ed2259d07" width="45%" />

---

## 📝 What's New

### v1.8.0 - Official Code Signing & Liquid Glass
- **Signed & Notarized:** No more Gatekeeper bypass — app opens immediately
- **Liquid Glass:** New visual effect option for macOS 26 (Tahoe)
- **Universal Binary:** arm64 + x86_64 with Hardened Runtime

### v1.8.1 - Bug Fix
- **Fixed:** Shortened English download metadata labels for better alignment

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
