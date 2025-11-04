#!/bin/bash

# FinderHover Release Script
# Automates the entire release process with Sparkle

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   FinderHover Release Automation      ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo ""

# Function to print step header
print_step() {
    echo -e "${GREEN}▶ $1${NC}"
}

# Function to print error and exit
print_error() {
    echo -e "${RED}✗ Error: $1${NC}"
    exit 1
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ Warning: $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Check if version argument is provided
if [ -z "$1" ]; then
    print_error "Usage: ./release.sh <version> [build_number]

Example: ./release.sh 1.1.5 7
         ./release.sh 1.1.5    (auto-increment build number)"
fi

VERSION=$1
BUILD=${2:-}

# Validate version format
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format. Use: X.Y.Z (e.g., 1.1.5)"
fi

print_step "Release Version: $VERSION"

# Step 1: Get current build number if not provided
if [ -z "$BUILD" ]; then
    print_step "Reading current build number from Info.plist..."
    CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PROJECT_DIR/FinderHover/Info.plist")
    BUILD=$((CURRENT_BUILD + 1))
    print_success "Auto-incremented build number: $CURRENT_BUILD → $BUILD"
else
    print_success "Using build number: $BUILD"
fi

# Step 2: Update Info.plist
print_step "Updating version in Info.plist..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PROJECT_DIR/FinderHover/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$PROJECT_DIR/FinderHover/Info.plist"
print_success "Updated Info.plist: v$VERSION (build $BUILD)"

# Step 3: Clean build directory
print_step "Cleaning build directory..."
rm -rf "$PROJECT_DIR/build"
mkdir -p "$PROJECT_DIR/build"
print_success "Build directory cleaned"

# Step 4: Build and Archive
print_step "Building and archiving app..."
xcodebuild archive \
    -project "$XCODE_PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    | xcpretty || xcodebuild archive \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO

if [ ! -d "$ARCHIVE_PATH" ]; then
    print_error "Archive failed. Check build logs."
fi
print_success "Archive created successfully"

# Step 5: Export .app
print_step "Exporting .app bundle..."
mkdir -p "$EXPORT_PATH"
cp -R "$ARCHIVE_PATH/Products/Applications/FinderHover.app" "$EXPORT_PATH/"
if [ ! -d "$EXPORT_PATH/FinderHover.app" ]; then
    print_error "Export failed. .app not found."
fi
print_success "Exported to: $EXPORT_PATH/FinderHover.app"

# Step 6: Create ZIP
print_step "Creating distribution ZIP..."
cd "$EXPORT_PATH"
ditto -c -k --sequesterRsrc --keepParent FinderHover.app "$ZIP_PATH"
cd "$PROJECT_DIR"
if [ ! -f "$ZIP_PATH" ]; then
    print_error "ZIP creation failed"
fi
print_success "Created: $ZIP_PATH"

# Step 7: Get file size
FILE_SIZE=$(stat -f%z "$ZIP_PATH")
print_success "File size: $FILE_SIZE bytes"

# Step 8: Sign the update
print_step "Signing update with EdDSA..."
if [ ! -f "$SIGN_UPDATE" ]; then
    print_error "sign_update tool not found at: $SIGN_UPDATE

Install Sparkle: brew install sparkle"
fi

SIGNATURE=$("$SIGN_UPDATE" "$ZIP_PATH" 2>&1 | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2)
if [ -z "$SIGNATURE" ]; then
    print_error "Failed to sign update. Check if private key is in Keychain."
fi
print_success "Signature generated successfully"

# Step 9: Display information for GitHub release
echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        GitHub Release Information      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Tag:${NC}          v$VERSION"
echo -e "${YELLOW}Title:${NC}        Version $VERSION"
echo -e "${YELLOW}File:${NC}         $ZIP_PATH"
echo -e "${YELLOW}File Size:${NC}    $FILE_SIZE bytes"
echo -e "${YELLOW}Signature:${NC}    $SIGNATURE"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Create GitHub release with tag: v$VERSION"
echo "2. Upload: $ZIP_PATH"
echo "3. Get download URL from GitHub"
echo ""

# Step 10: Ask if user wants to update appcast.xml
read -p "Update appcast.xml now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Please provide GitHub release download URL:"
    read -p "URL: " DOWNLOAD_URL

    if [ -z "$DOWNLOAD_URL" ]; then
        print_warning "No URL provided. Skipping appcast update."
        print_warning "You'll need to manually update appcast.xml"
    else
        # Generate RFC 822 date
        PUB_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

        # Create new release entry
        NEW_ENTRY="    <!-- Version $VERSION - $(date +"%Y-%m-%d") -->
    <item>
        <title>Version $VERSION</title>
        <link>https://github.com/KoukeNeko/FinderHover/releases/tag/v$VERSION</link>
        <sparkle:version>$BUILD</sparkle:version>
        <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
        <description><![CDATA[
            <h2>What's New in $VERSION</h2>
            <ul>
                <li>TODO: Add release notes</li>
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

        # Backup appcast.xml
        cp "$APPCAST_PATH" "$APPCAST_PATH.backup"

        # Insert new entry after the opening <channel> tag
        # Using awk to insert after the line containing "</language>"
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
        print_warning "Don't forget to edit release notes in appcast.xml!"
        print_warning "Backup saved: $APPCAST_PATH.backup"
    fi
else
    print_warning "Skipping appcast.xml update"
    echo -e "${YELLOW}Manual update required:${NC}"
    echo "- File size: $FILE_SIZE"
    echo "- Signature: $SIGNATURE"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Release Summary               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ Version:${NC}     $VERSION (build $BUILD)"
echo -e "${GREEN}✓ Archive:${NC}     $ARCHIVE_PATH"
echo -e "${GREEN}✓ ZIP:${NC}         $ZIP_PATH"
echo -e "${GREEN}✓ Size:${NC}        $FILE_SIZE bytes"
echo -e "${GREEN}✓ Signature:${NC}   $SIGNATURE"
echo ""
echo -e "${YELLOW}TODO:${NC}"
echo "1. ✗ Create GitHub release (tag: v$VERSION)"
echo "2. ✗ Upload ZIP file"
echo "3. ✗ Update release notes in appcast.xml (if auto-updated)"
echo "4. ✗ Commit and push appcast.xml"
echo "5. ✗ Verify appcast.xml is accessible"
echo ""
print_success "Release build completed successfully!"
