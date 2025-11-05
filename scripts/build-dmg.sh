#!/bin/bash
set -e

echo "🚀 Starting DMG creation..."

# Change to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "📂 Working directory: $PROJECT_ROOT"

# Configuration
APP_NAME="FinderHover"
INFO_PLIST="FinderHover/Info.plist"

# Read version from Info.plist
if [ ! -f "$INFO_PLIST" ]; then
    echo "❌ Error: Cannot find $INFO_PLIST"
    echo "   Current directory: $(pwd)"
    exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$INFO_PLIST")
echo "📌 Detected version: $VERSION"

DMG_NAME="${APP_NAME}-v${VERSION}"

# Clean extended attributes that can cause code signing issues
echo "🧹 Cleaning extended attributes..."
find . -not -path "./.git/*" -not -path "./build/*" -exec xattr -c {} \; 2>/dev/null || true

# Build Release version (unsigned, for testing)
echo "🔨 Building Release version (unsigned)..."
xcodebuild -project FinderHover.xcodeproj \
    -scheme FinderHover \
    -configuration Release \
    -derivedDataPath ./build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    clean build

# Check if Release build succeeded
if [ ! -d "build/Build/Products/Release/${APP_NAME}.app" ]; then
    echo "❌ Error: Build failed, cannot find build/Build/Products/Release/${APP_NAME}.app"
    exit 1
fi

echo "✅ Build completed!"

# Clean old files
echo "🧹 Cleaning old files..."
rm -rf dmg-temp
rm -f "${DMG_NAME}.dmg"

# Create temporary directory
echo "📁 Creating temporary directory..."
mkdir -p dmg-temp
cp -R "build/Build/Products/Release/${APP_NAME}.app" dmg-temp/
ln -s /Applications dmg-temp/Applications

# Create DMG
echo "📦 Creating DMG..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder dmg-temp \
    -ov -format UDZO \
    "${DMG_NAME}.dmg"

# Cleanup
echo "🧹 Cleaning up temporary files..."
rm -rf dmg-temp

# Create ZIP for distribution
echo "📦 Creating ZIP archive..."
ditto -c -k --sequesterRsrc "${DMG_NAME}.dmg" "${DMG_NAME}.zip"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Done! Build completed successfully"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 Created files:"
echo "   • ${DMG_NAME}.dmg"
echo "   • ${DMG_NAME}.zip (ready for GitHub Release)"
echo ""
echo "⚠️  Note: This is an UNSIGNED build for testing purposes"
echo "   Users will need to allow it in System Settings > Privacy & Security"
echo ""