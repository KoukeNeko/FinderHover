#!/bin/bash

# FinderHover Fully Automated Release Script
# Requires: gh (GitHub CLI)
# Install: brew install gh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCODE_PROJECT="$PROJECT_DIR/FinderHover.xcodeproj"
SCHEME="FinderHover"
CONFIGURATION="Release"
ARCHIVE_PATH="$PROJECT_DIR/build/FinderHover.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"
ZIP_PATH="$PROJECT_DIR/build/FinderHover.zip"
APPCAST_PATH="$PROJECT_DIR/appcast.xml"
SIGN_UPDATE="/opt/homebrew/Caskroom/sparkle/2.8.0/bin/sign_update"

print_step() { echo -e "${GREEN}▶ $1${NC}"; }
print_error() { echo -e "${RED}✗ Error: $1${NC}"; exit 1; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  FinderHover Automated Release (gh)    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check arguments
if [ -z "$1" ]; then
    print_error "Usage: ./release-auto.sh <version> [--prerelease] [--notes \"Release notes\"]

Examples:
  ./release-auto.sh 1.1.5
  ./release-auto.sh 1.1.6 --prerelease
  ./release-auto.sh 1.1.5 --notes \"Bug fixes and improvements\""
fi

VERSION=$1
shift

# Parse optional arguments
PRERELEASE=false
RELEASE_NOTES=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --prerelease)
            PRERELEASE=true
            shift
            ;;
        --notes)
            RELEASE_NOTES="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            ;;
    esac
done

# Validate version
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format. Use: X.Y.Z"
fi

# Check for gh CLI
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) not found.

Install: brew install gh
Then:    gh auth login"
fi

# Check gh authentication
if ! gh auth status &> /dev/null; then
    print_error "GitHub CLI not authenticated.

Run: gh auth login"
fi

print_step "Release Version: $VERSION $([ "$PRERELEASE" = true ] && echo "(prerelease)")"

# Get current build number and increment
print_step "Reading current build number..."
CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PROJECT_DIR/FinderHover/Info.plist")
BUILD=$((CURRENT_BUILD + 1))
print_success "Build number: $CURRENT_BUILD → $BUILD"

# Update Info.plist
print_step "Updating Info.plist..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PROJECT_DIR/FinderHover/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$PROJECT_DIR/FinderHover/Info.plist"
print_success "Updated to v$VERSION (build $BUILD)"

# Clean build
print_step "Cleaning build directory..."
rm -rf "$PROJECT_DIR/build"
mkdir -p "$PROJECT_DIR/build"

# Build and Archive
print_step "Building and archiving... (this may take a minute)"
xcodebuild archive \
    -project "$XCODE_PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    > "$PROJECT_DIR/build/xcodebuild.log" 2>&1

if [ ! -d "$ARCHIVE_PATH" ]; then
    print_error "Archive failed. Check: build/xcodebuild.log"
fi
print_success "Archive created"

# Export .app
print_step "Exporting .app bundle..."
mkdir -p "$EXPORT_PATH"
cp -R "$ARCHIVE_PATH/Products/Applications/FinderHover.app" "$EXPORT_PATH/"
print_success "Exported app"

# Create ZIP
print_step "Creating ZIP..."
cd "$EXPORT_PATH"
ditto -c -k --sequesterRsrc --keepParent FinderHover.app "$ZIP_PATH"
cd "$PROJECT_DIR"
FILE_SIZE=$(stat -f%z "$ZIP_PATH")
print_success "ZIP created ($FILE_SIZE bytes)"

# Sign update
print_step "Signing with EdDSA..."
SIGNATURE=$("$SIGN_UPDATE" "$ZIP_PATH" 2>&1 | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2)
if [ -z "$SIGNATURE" ]; then
    print_error "Signing failed. Check Keychain for private key."
fi
print_success "Signed successfully"

# Generate release notes
if [ -z "$RELEASE_NOTES" ]; then
    RELEASE_NOTES="## What's New in $VERSION

- TODO: Add release notes

See [CHANGELOG](CHANGELOG.md) for full details."
fi

# Create GitHub release
print_step "Creating GitHub release..."
PRERELEASE_FLAG=""
if [ "$PRERELEASE" = true ]; then
    PRERELEASE_FLAG="--prerelease"
fi

gh release create "v$VERSION" \
    "$ZIP_PATH" \
    --title "Version $VERSION" \
    --notes "$RELEASE_NOTES" \
    $PRERELEASE_FLAG

if [ $? -ne 0 ]; then
    print_error "GitHub release creation failed"
fi
print_success "GitHub release created"

# Get download URL
print_step "Getting download URL..."
DOWNLOAD_URL="https://github.com/KoukeNeko/FinderHover/releases/download/v$VERSION/FinderHover.zip"
print_success "Download URL: $DOWNLOAD_URL"

# Update appcast.xml
print_step "Updating appcast.xml..."
PUB_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

NEW_ENTRY="    <!-- Version $VERSION - $(date +"%Y-%m-%d") -->
    <item>
        <title>Version $VERSION</title>
        <link>https://github.com/KoukeNeko/FinderHover/releases/tag/v$VERSION</link>
        <sparkle:version>$BUILD</sparkle:version>
        <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
        <description><![CDATA[
            <h2>What's New in $VERSION</h2>
            <ul>
                <li>TODO: Edit release notes in appcast.xml</li>
            </ul>
        ]]]]><![CDATA[></description>
        <pubDate>$PUB_DATE</pubDate>
        <enclosure
            url=\"$DOWNLOAD_URL\"
            sparkle:version=\"$BUILD\"
            sparkle:shortVersionString=\"$VERSION\"
            length=\"$FILE_SIZE\"
            type=\"application/octet-stream\"
            sparkle:edSignature=\"$SIGNATURE\" />
    </item>

"

# Backup and update appcast
cp "$APPCAST_PATH" "$APPCAST_PATH.backup"
awk -v entry="$NEW_ENTRY" '
    /<\/language>/ {
        print
        print ""
        print entry
        next
    }
    {print}
' "$APPCAST_PATH.backup" > "$APPCAST_PATH"
print_success "Updated appcast.xml"

# Commit and push
print_step "Committing changes..."
git add Info.plist appcast.xml
git commit -m "Release v$VERSION (build $BUILD)

- Updated version to $VERSION
- Updated appcast.xml with new release
- Build number: $BUILD"

print_step "Pushing to GitHub..."
git push origin main

if [ $? -ne 0 ]; then
    print_warning "Git push failed. You may need to push manually."
else
    print_success "Pushed to GitHub"
fi

# Wait for appcast to be available
print_step "Waiting for appcast.xml to be available on GitHub..."
sleep 5

# Verify appcast
APPCAST_URL="https://raw.githubusercontent.com/KoukeNeko/FinderHover/main/appcast.xml"
if curl -f -s "$APPCAST_URL" > /dev/null; then
    print_success "Appcast verified: $APPCAST_URL"
else
    print_warning "Could not verify appcast. Check manually: $APPCAST_URL"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Release Complete! 🎉            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ Version:${NC}       $VERSION (build $BUILD)"
echo -e "${GREEN}✓ Release:${NC}       https://github.com/KoukeNeko/FinderHover/releases/tag/v$VERSION"
echo -e "${GREEN}✓ Download:${NC}      $DOWNLOAD_URL"
echo -e "${GREEN}✓ File Size:${NC}     $FILE_SIZE bytes"
echo -e "${GREEN}✓ Appcast:${NC}       $APPCAST_URL"
echo ""
echo -e "${YELLOW}TODO:${NC}"
echo "1. Edit release notes on GitHub (optional)"
echo "2. Edit release notes in appcast.xml (recommended)"
echo "3. Test update from previous version"
echo ""
print_success "All done! Users will receive update within 24 hours."
