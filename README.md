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

<!-- 
TODO: Add a high-quality GIF or Video here showing the hover interaction in action.
Example: <img src="docs/demo.gif" width="100%" />
-->

<img width="1926" height="1324" alt="Feature Overview" src="https://github.com/user-attachments/assets/7d27934e-5e11-4196-a6ac-5c7ebc6a1f17" />

## 🚀 Technical Highlights & Implementation Details

FinderHover isn't just a UI wrapper; it's a deep dive into macOS system integration. Here is how we built it:

### 🛡️ Privacy-First Architecture
We prioritize user privacy and system performance by utilizing the **macOS Accessibility API** directly (`Core/FinderInteraction.swift`). Unlike legacy tools that rely on slow, invasive AppleScript polling, FinderHover listens to the system's accessibility event stream.
- **Zero Network Access**: All processing happens locally.
- **High Performance**: Direct API calls minimize overhead.
- **Context Awareness**: Intelligently detects if you are renaming a file to avoid interrupting your workflow.

### ⚡️ Robust Metadata Engine
Built on top of Apple's native frameworks (`AVFoundation`, `PDFKit`, `QuickLookThumbnailing`), our metadata engine (`Core/FileInfo.swift`) is a lightweight powerhouse. It supports over **50 file formats**—from analyzing raw EXIF data in images to counting lines of code in source files—without external heavyweight dependencies.

### 🌊 Reactive UI Updates
A smooth user experience is paramount. We leverage **Combine** (`App/HoverManager.swift`) to manage the stream of mouse events. By applying reactive operators like `debounce`, we ensure the UI updates fluidly only when you intend to hover, eliminating visual jitter and keeping CPU usage negligible.

## ✨ Features

### 🔍 Smart Detection
- **Instant Preview**: Smart hover preview with adjustable delay (0.1s - 2.0s).
- **QuickLook Integration**: Native thumbnails for PDFs, images, and documents.
- **Intelligent Context**: Auto-hides when renaming files or dragging items.

### 📊 Rich Metadata
- **Photography (EXIF)**: Camera model, lens, ISO, aperture, shutter speed, GPS.
- **Multimedia**: Video codec, resolution, bitrate; Audio sample rate, channels.
- **Development**: Line counts for 25+ code languages, file encoding.
- **Typography & Design**: Font family/glyphs, Vector graphics (SVG/AI) dimensions.
- **System**: Permissions, owner, file paths, disk image compression ratios.

### 🎨 Customizable UI
- **Dual Personalities**: Choose between a rich **macOS** style or a minimal **Windows** tooltip style.
- **Full Control**: Adjustable window size, opacity (70-100%), and font scaling.
- **Layout Editor**: Drag-to-reorder metadata fields and toggle visibility per category.
- **Localization**: Native support for English, Traditional Chinese (繁體中文), and Japanese (日本語).

## 🛠️ For Developers

Interested in the code? Here is how the project is structured:

- **`App/`**: Application lifecycle and coordination (`FinderHoverApp`, `HoverManager`).
- **`Core/`**: The engine room. Contains `MouseTracker` for event monitoring, `FinderInteraction` for Accessibility API logic, and `FileInfo` for metadata extraction.
- **`UI/`**: Pure SwiftUI views.
    - `Windows/`: The floating hover window and main settings container.
    - `Settings/`: Modular, component-based settings pages.
- **`Utilities/`**: Shared helpers for localization, logging, and formatting.

We follow **Clean Code** principles and **SOLID** architecture to ensure maintainability.

## 📦 Installation

### Homebrew (Recommended)

```bash
brew install koukeneko/tap/finderhover
```

### Download Release

1. Download `FinderHover.dmg.zip` from [Releases](../../releases)
2. Extract and move to Applications folder
3. Launch FinderHover

### Build from Source

```bash
git clone https://github.com/KoukeNeko/FinderHover.git
cd FinderHover
./scripts/build-dmg.sh
```

## ⚙️ Setup & Usage

**Permission Required**: On first launch, you must grant **Accessibility permission** (System Settings > Privacy & Security > Accessibility). This is required to detect the file under your mouse cursor.

**Settings**: Press `Cmd+,` to access the configuration panel.

## 📸 Screenshots

<p float="left">
  <img src="https://github.com/user-attachments/assets/fe969256-a07d-4db6-8715-a3bb3226782b" width="45%" />
  <img src="https://github.com/user-attachments/assets/f492dc51-9fd8-49f2-b854-d9fc4ac026a6" width="45%" /> 
</p>
<p float="left">
  <img src="https://github.com/user-attachments/assets/dc04ba05-2bcb-4308-b0cc-bd5ed2259d07" width="45%" />
  <img src="https://github.com/user-attachments/assets/140accdd-6034-4b2d-b4d9-ccc55a28586c" width="45%" />
</p>

## 📝 What's New (v1.3.2)

- **Localization Improvements**: Optimized label lengths for better layout consistency in compact modes.
- **Performance**: Fixed scrolling freeze in Settings view.
- **Refactoring**: Massive cleanup of Settings code for better stability.

[View Full Changelog](CHANGELOG.md)

## 🤝 Contributing

Contributions are welcome! Please check out the `Core/` directory if you're interested in the file detection logic, or `UI/` for visual improvements.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Made with ❤️ and Swift**
