# FinderHover

A beautiful, highly customizable macOS app that displays rich file information when hovering over files in Finder, similar to Windows file preview behavior.

<p align="center">
  <img src="/FinderHover/Assets.xcassets/AppIcon.appiconset/Icon-256.png" alt="Icon-256" width="128">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-000000.svg?style=flat&logo=apple&logoColor=white" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Swift-5.0-F05138.svg?style=flat&logo=swift&logoColor=white" alt="Swift 5.0">
  <img src="https://img.shields.io/badge/SwiftUI-007AFF.svg?style=flat&logo=swift&logoColor=white" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Combine-F05138.svg?style=flat&logo=swift&logoColor=white" alt="Combine">
  <img src="https://img.shields.io/badge/Accessibility%20API-success.svg?style=flat" alt="Accessibility API">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat" alt="License MIT">
</p>

<img width="1926" height="1324" alt="Feature Overview" src="https://github.com/user-attachments/assets/7d27934e-5e11-4196-a6ac-5c7ebc6a1f17" />

## ✨ Features

### 🔍 Smart Detection
- **Instant Preview**: Smart hover preview with adjustable delay (0.1s - 2.0s)
- **QuickLook Integration**: Native thumbnails for PDFs, images, and documents
- **Intelligent Context**: Auto-hides when renaming files or dragging items

### 📊 Rich Metadata Support

| Category | Supported Metadata |
|----------|-------------------|
| **📷 Photography** | Camera model, lens, ISO, aperture, shutter speed, GPS, IPTC/XMP data |
| **🎬 Multimedia** | Video codec, resolution, bitrate, frame rate, audio sample rate, channels |
| **💻 Development** | Line counts for 30+ languages, file encoding, syntax detection |
| **📝 Markdown** | Title, frontmatter, heading/image/link/code block counts |
| **🌐 HTML/Web** | Title, meta description, keywords, author, language |
| **⚙️ Config Files** | JSON/YAML/TOML key counts, nesting depth, array counts |
| **🎨 Design** | PSD layers/color mode/bit depth, SVG/AI dimensions, font glyphs |
| **📦 App Bundles** | Bundle ID, version, minimum macOS, code signing, entitlements |
| **⚡ Executables** | Architecture, code signing, minimum OS, SDK version |
| **🗄️ SQLite** | Table/index/trigger/view counts, total rows, schema version, encoding |
| **📂 Git Repos** | Current branch, commit count, remote URL, uncommitted changes, tags |
| **💿 System** | Permissions, owner, file paths, disk image compression ratios |

### 🎨 Customizable UI
- **Dual Personalities**: Choose between rich **macOS** style or minimal **Windows** tooltip style
- **Full Control**: Adjustable window size, opacity (70-100%), and font scaling
- **Layout Editor**: Drag-to-reorder metadata fields and toggle visibility per category
- **Localization**: Native support for English, Traditional Chinese (繁體中文), and Japanese (日本語)

## 📦 Installation

### Homebrew (Recommended)

```bash
brew install koukeneko/tap/finderhover
```

### Download Release

1. Download `FinderHover.app.zip` from [Releases](../../releases)
2. Extract and move to Applications folder
3. Launch FinderHover

### Build from Source

```bash
git clone https://github.com/KoukeNeko/FinderHover.git
cd FinderHover
xcodebuild -scheme FinderHover -configuration Release
```

## ⚙️ Setup & Usage

**Permission Required**: On first launch, grant **Accessibility permission** (System Settings → Privacy & Security → Accessibility). This is required to detect the file under your mouse cursor.

**Settings**: Click the menu bar icon or press `Cmd+,` to access the configuration panel.

## 🚀 Technical Highlights

### 🛡️ Privacy-First Architecture
We utilize the **macOS Accessibility API** directly. Unlike legacy tools that rely on slow AppleScript polling, FinderHover listens to the system's accessibility event stream.
- **Zero Network Access**: All processing happens locally
- **High Performance**: Direct API calls minimize overhead
- **Context Awareness**: Intelligently detects if you are renaming a file

### ⚡️ Robust Metadata Engine
Built on Apple's native frameworks (`AVFoundation`, `PDFKit`, `QuickLookThumbnailing`, `SQLite3`), our metadata engine supports **50+ file formats** without external dependencies.

### 🌊 Reactive UI Updates
We leverage **Combine** to manage mouse events. By applying reactive operators like `debounce`, we ensure fluid UI updates while keeping CPU usage negligible.

## 🛠️ Project Structure

```
FinderHover/
├── App/          # Application lifecycle (FinderHoverApp, HoverManager)
├── Core/         # MouseTracker, FinderInteraction, FileInfo
├── UI/
│   ├── Windows/  # Floating hover window, settings container
│   └── Settings/ # Modular settings pages
└── Utilities/    # Localization, logging, formatting helpers
```

## 📸 Screenshots

<p float="left">
  <img src="https://github.com/user-attachments/assets/fe969256-a07d-4db6-8715-a3bb3226782b" width="45%" />
  <img src="https://github.com/user-attachments/assets/f492dc51-9fd8-49f2-b854-d9fc4ac026a6" width="45%" />
</p>
<p float="left">
  <img src="https://github.com/user-attachments/assets/dc04ba05-2bcb-4308-b0cc-bd5ed2259d07" width="45%" />
  <img src="https://github.com/user-attachments/assets/140accdd-6034-4b2d-b4d9-ccc55a28586c" width="45%" />
</p>

## 📝 What's New (v1.4.x)

### v1.4.3
- Fix Markdown files showing duplicate code file section

### v1.4.0 - Major Metadata Update
- **9 New Metadata Types**: HTML/Web, Extended Image (IPTC/XMP), Markdown, Config (JSON/YAML/TOML), PSD, Executable, App Bundle, SQLite, Git Repository
- **Native SQLite3 API**: Better performance for database inspection
- **Settings Toggles**: Per-field visibility controls for all metadata

[View Full Changelog](CHANGELOG.md)

## 🤝 Contributing

Contributions are welcome! Check out `Core/FileInfo.swift` for metadata extraction logic or `UI/` for visual improvements.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Made with ❤️ and Swift**
