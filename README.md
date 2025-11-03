# FinderHover

A macOS menu bar app that displays file information when hovering over files in Finder, similar to Windows file preview behavior.

## Features

- **Hover Preview**: Automatically shows file information when you hover over files in Finder
- **Detailed Info**: Displays file name, type, size, modification date, and path
- **Menu Bar App**: Runs quietly in the background from your menu bar
- **Easy Toggle**: Enable/disable hover preview with a simple menu option

## Installation

1. Open the project in Xcode
2. Build and run the app (Cmd + R)
3. The app will appear in your menu bar with an eye icon

## Setup

On first launch, you'll need to grant the app permissions:

1. **Accessibility Permission**: The app will prompt you to enable accessibility access
   - Go to System Settings > Privacy & Security > Accessibility
   - Enable FinderHover in the list

2. **AppleEvents Permission**: You may be prompted to allow the app to control Finder
   - Click "OK" to allow

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

The app uses several macOS technologies:

- **Accessibility API**: Monitors mouse position globally
- **AppleScript**: Interacts with Finder to get file information
- **SwiftUI**: Displays the hover window with file details
- **Menu Bar Integration**: Runs as a lightweight background app

## Requirements

- macOS 14.0 or later
- Accessibility permissions
- AppleEvents permissions for Finder interaction

## Privacy

FinderHover:
- Only accesses file metadata (name, size, dates)
- Does not read file contents
- Does not send any data over the network
- Runs entirely locally on your Mac

## Development

Built with:
- Swift 5.0
- SwiftUI
- AppKit
- Accessibility Framework

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
