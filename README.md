# FinderHover

A beautiful macOS menu bar app that displays rich file information when hovering over files in Finder, similar to Windows file preview behavior.

## Features

- **🎯 Hover Preview**: Automatically shows detailed file information when you hover over selected files in Finder
- **📊 Rich Information Display**:
  - Full filename (with automatic wrapping for long names)
  - File type with smart descriptions (recognizes 50+ file types)
  - File size in human-readable format
  - Creation and modification dates
  - Full file path (with text selection support)
  - Large file icon for easy recognition
- **🎨 Modern Design**:
  - Beautiful gradient border
  - Smooth shadows and transparency
  - Smart positioning (stays on screen)
  - Adapts to filename length
- **⚡ Lightweight**: Runs quietly in the background from your menu bar
- **🔒 Privacy-First**: Uses only Accessibility APIs (no AppleScript)
- **🎛️ Easy Control**: Toggle on/off from menu bar

## Installation

1. Open the project in Xcode
2. Build and run the app (Cmd + R)
3. The app will appear in your menu bar with an eye icon

## Setup

On first launch, you only need to grant one permission:

1. **Accessibility Permission**: The app will automatically prompt you
   - Click "Open System Settings" when prompted
   - Go to System Settings > Privacy & Security > Accessibility
   - Enable FinderHover (or Xcode during development) in the list
   - Restart the app

## Usage

1. Launch FinderHover - it will appear in your menu bar
2. Open Finder and navigate to any folder
3. Hover your mouse over a file and wait ~0.8 seconds
4. A tooltip will appear showing:
   - File icon and name
   - File type and size
   - Last modified date
   - Full file path

### Menu Bar Options

- **Enable/Disable Hover Preview**: Toggle the hover functionality on/off
- **About FinderHover**: View app information
- **Quit**: Close the application

## How It Works

The app uses modern macOS technologies:

- **Accessibility API**: Monitors mouse position globally and retrieves file information from Finder
- **SwiftUI**: Renders the beautiful hover window with adaptive sizing
- **AppKit**: Manages window positioning and screen boundary detection
- **Menu Bar Integration**: Runs as a lightweight background app

**Note**: The app works with **selected files** in Finder. Select a file (click it), then hover your mouse over it to see the preview.

## Requirements

- macOS 14.0 or later (compatible with macOS 15+ and future versions)
- Accessibility permissions only
- Xcode 15.0+ for building

## Privacy & Security

FinderHover is designed with privacy in mind:
- ✅ Only accesses file metadata (name, size, dates, paths)
- ✅ Does not read file contents
- ✅ Does not send any data over the network
- ✅ No analytics or tracking
- ✅ Runs entirely locally on your Mac
- ✅ Uses Accessibility API only (no AppleScript automation)
- ✅ Open source - inspect the code yourself!

## Development

**Technology Stack:**
- Swift 5.0
- SwiftUI for modern UI
- AppKit for window management
- Accessibility Framework for file detection
- Combine for reactive updates

**Project Structure:**
- `FinderHoverApp.swift` - Main app and menu bar setup
- `HoverWindow.swift` - Floating preview window UI
- `HoverManager.swift` - Coordinates mouse tracking and display
- `MouseTracker.swift` - Global mouse movement monitoring
- `FinderInteraction.swift` - Accessibility API integration
- `FileInfo.swift` - File metadata model

**Supported File Types:**
The app recognizes and provides descriptions for 50+ file types including:
- Documents: PDF, Word, Excel, PowerPoint, Pages, Numbers, Keynote
- Images: JPEG, PNG, GIF, SVG, PSD, AI, Sketch
- Media: MP4, MOV, AVI, MP3, WAV, FLAC
- Archives: ZIP, RAR, 7Z, DMG, ISO
- Code: Swift, Python, JavaScript, TypeScript, Java, C/C++, HTML, CSS
- And many more...

## Troubleshooting

**Hover window not appearing?**
- Check that the app has Accessibility permission
- Ensure the app is enabled (check menu bar icon)
- Make sure you're hovering over a selected file in Finder

**Performance issues?**
- The app uses minimal resources
- You can temporarily disable it from the menu bar

## License

Created for personal use. Feel free to modify and distribute.
