# FinderHover

A beautiful, highly customizable macOS menu bar app that displays rich file information when hovering over files in Finder, similar to Windows file preview behavior.

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue.svg" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg" alt="Swift 5.0">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License MIT">
</p>

## ✨ Features

### 🎯 Smart Hover Preview
- **Instant response**: Adjustable hover delay (0.1s - 2.0s, default: 0.1s)
- Automatically shows detailed file information when you hover over selected files in Finder
- Smart window positioning that avoids screen edges
- Auto-hide when mouse moves away from file

### 📊 Rich Information Display
- **Full filename** with automatic wrapping for long names
- **Large file icon** (48x48) for easy recognition
- **Smart file type descriptions** (recognizes 50+ file types)
  - "PDF Document", "PowerPoint Presentation", "Photoshop Document", etc.
- **File size** in human-readable format (KB, MB, GB)
- **Creation date** with date and time
- **Modification date** with date and time
- **Complete file path** with text selection support (no truncation)
- **Perfect icon alignment** across all information rows

### 🎨 Modern & Customizable Design
- Beautiful gradient border with subtle shadow
- Adjustable window opacity (70% - 100%)
- Customizable window size (300px - 600px)
- Adjustable font size (9pt - 14pt)
- Toggle individual information fields on/off
- Adapts to filename and path length automatically

### ⚙️ Professional Settings Interface
- **macOS-native sidebar navigation** (like System Settings)
- Three organized setting pages:
  - **Behavior**: Hover delay, auto-hide, window positioning
  - **Appearance**: Opacity, window size, font size
  - **Display**: Toggle which information to show
- Real-time preview of all changes
- One-click reset to defaults
- Keyboard shortcut: `Cmd+,`

### ⚡ Performance & Privacy
- **Lightweight**: Minimal CPU and memory usage
- **Menu bar app**: Runs quietly in the background
- **Privacy-first**: Uses only Accessibility APIs (no AppleScript)
- **No network access**: Runs entirely locally on your Mac
- **No analytics or tracking**
- **Open source**: Inspect the code yourself

## 📦 Installation

### Option 1: Build from Source
1. Clone this repository
   ```bash
   git clone https://github.com/yourusername/FinderHover.git
   cd FinderHover
   ```
2. Open `FinderHover.xcodeproj` in Xcode
3. Build and run the app (`Cmd+R`)
4. The app will appear in your menu bar with an eye icon

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
3. **Click to select a file** (it will highlight in blue)
4. **Hover your mouse** over the selected file
5. **Wait 0.1 seconds** (customizable)
6. A beautiful preview window appears showing file details!

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
- **Window Position**: Adjust horizontal/vertical offset from cursor (0-50px)

#### Appearance Tab
- **Window Opacity**: 70% - 100% (transparency level)
- **Maximum Width**: 300px - 600px (window size)
- **Font Size**: 9pt - 14pt (all text scales proportionally)

#### Display Tab
Toggle what information to show:
- ☑️ File Icon
- ☑️ File Type
- ☑️ File Size
- ☑️ Creation Date
- ☑️ Modification Date
- ☑️ File Path

> **💡 Tip**: All settings apply **instantly** - no need to restart!

## 🔧 How It Works

The app uses modern macOS technologies:

- **Accessibility API**: Monitors mouse position globally and retrieves file information from Finder
- **SwiftUI**: Renders the beautiful hover window with adaptive sizing and reactive updates
- **AppKit**: Manages window positioning, screen boundary detection, and visual effects
- **Combine**: Reactive updates for settings and mouse tracking
- **UserDefaults**: Persistent settings storage
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
- **Accessibility Framework** - File detection and mouse tracking
- **Combine** - Reactive programming for settings and events
- **UserDefaults** - Persistent settings storage

### Project Structure
```
FinderHover/
├── FinderHoverApp.swift      # Main app & menu bar
├── AppSettings.swift          # Settings model with UserDefaults
├── SettingsView.swift         # Settings UI (sidebar navigation)
├── HoverWindow.swift          # Preview window with SwiftUI
├── HoverManager.swift         # Coordination layer
├── MouseTracker.swift         # Global mouse events
├── FinderInteraction.swift   # Accessibility API integration
├── FileInfo.swift             # File metadata model
└── Info.plist                # App permissions
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

### Building from Source

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

### Contributing

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
![Hover Window](screenshots/hover-window.png)
*Beautiful preview with complete file information*

### Settings - Sidebar Navigation
![Settings](screenshots/settings-sidebar.png)
*Professional macOS-native settings interface*

### Settings Tabs
![Behavior](screenshots/settings-behavior.png) ![Appearance](screenshots/settings-appearance.png) ![Display](screenshots/settings-display.png)
*Customize every aspect of the app*

## 📝 Changelog

### Version 1.0 (Current)
- ✨ Initial release
- 🎯 Smart hover preview with adjustable delay (default: 0.1s)
- 📊 Rich file information display with 50+ file type recognition
- 🎨 Modern design with gradient borders and shadows
- ⚙️ Comprehensive settings with sidebar navigation
- 🔒 Privacy-first: Accessibility API only (no AppleScript)
- ⚡ Instant auto-hide when mouse moves away
- 📏 Perfect icon and text alignment
- 📄 Complete file path display (no truncation)
- 🎛️ Toggle individual information fields
- 💾 Persistent settings with UserDefaults
- 🚀 Lightweight and efficient
- 🌐 Full Unicode support for international file names

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

## 🙏 Acknowledgments

- Inspired by Windows file preview functionality
- Built with Apple's SwiftUI and Accessibility frameworks
- Icons from SF Symbols

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

Created with ❤️ for macOS users who want a better Finder experience.

## 🔗 Links

- [Report an Issue](../../issues)
- [Request a Feature](../../issues/new)
- [View Releases](../../releases)
- [Discussions](../../discussions)

---

**Note**: This app requires **Accessibility permission** to function. Your privacy is protected - the app:
- ✅ Only reads file metadata (name, size, dates, path)
- ✅ Does NOT read file contents
- ✅ Does NOT send any data over the network
- ✅ Does NOT collect analytics or telemetry
- ✅ Runs entirely locally on your Mac
- ✅ Open source - inspect the code yourself

**Made with Swift & SwiftUI** 🚀
