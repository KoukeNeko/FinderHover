#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────
# build-dmg-signed.sh
#
# Produces a fully signed, notarized, and stapled DMG for
# distribution via Homebrew Cask or direct download.
#
# Required environment variables (or edit defaults below):
#   APPLE_ID          - your Apple ID email
#   APPLE_TEAM_ID     - your 10-char Apple Team ID
#   APPLE_APP_PASSWORD- an App-Specific Password from appleid.apple.com
#   SIGN_IDENTITY     - codesign identity string (Developer ID Application)
#
# Usage:
#   APPLE_ID="you@email.com" \
#   APPLE_TEAM_ID="XXXXXXXXXX" \
#   APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
#   SIGN_IDENTITY="Developer ID Application: Your Name (XXXXXXXXXX)" \
#   ./scripts/build-dmg-signed.sh
# ─────────────────────────────────────────────────────────────

# ── Load .env file if present ────────────────────────────────
DOTENV_PATH="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.env"
if [ -f "$DOTENV_PATH" ]; then
    echo "📄 Loading $DOTENV_PATH ..."
    # Export only KEY=VALUE lines; skip comments and blank lines
    set -a
    # shellcheck source=/dev/null
    source "$DOTENV_PATH"
    set +a
fi
# ─────────────────────────────────────────────────────────────
validate_required_vars() {
    if [ -z "$APPLE_APP_PASSWORD" ]; then
        echo "❌ Error: APPLE_APP_PASSWORD is not set."
        echo "   Generate one at https://appleid.apple.com → App-Specific Passwords"
        echo "   Then run: APPLE_APP_PASSWORD='xxxx-xxxx-xxxx-xxxx' ./scripts/build-dmg-signed.sh"
        exit 1
    fi
}

resolve_paths() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    cd "$PROJECT_ROOT"
    echo "📂 Working directory: $PROJECT_ROOT"
}

read_project_metadata() {
    APP_NAME="FinderHover"
    INFO_PLIST="FinderHover/Info.plist"

    if [ ! -f "$INFO_PLIST" ]; then
        echo "❌ Error: Cannot find $INFO_PLIST"
        exit 1
    fi

    VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$INFO_PLIST")
    BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$INFO_PLIST")
    DMG_NAME="${APP_NAME}-v${VERSION}"

    echo "📌 Version:   $VERSION"
    echo "📌 Bundle ID: $BUNDLE_ID"
    echo "📌 Identity:  $SIGN_IDENTITY"
}

clean_extended_attributes() {
    echo "🧹 Cleaning extended attributes..."
    find . -not -path "./.git/*" -not -path "./build/*" \
        -exec xattr -c {} \; 2>/dev/null || true
}

build_release() {
    # Clean manually to avoid APFS build.db disk I/O errors when using `clean build` together
    echo "🧹 Cleaning previous build..."
    rm -rf "${PROJECT_ROOT}/build"
    mkdir -p "${PROJECT_ROOT}/build"
    xattr -w com.apple.xcode.CreatedByBuildSystem true "${PROJECT_ROOT}/build" 2>/dev/null || true

    echo "🔨 Building Release..."
    xcodebuild -project FinderHover.xcodeproj \
        -scheme FinderHover \
        -configuration Release \
        SYMROOT="${PROJECT_ROOT}/build" \
        CODE_SIGN_STYLE=Manual \
        CODE_SIGN_IDENTITY="${SIGN_IDENTITY}" \
        CODE_SIGNING_REQUIRED=YES \
        CODE_SIGNING_ALLOWED=YES \
        DEVELOPMENT_TEAM="${APPLE_TEAM_ID}" \
        OTHER_CODE_SIGN_FLAGS="--timestamp" \
        ENABLE_HARDENED_RUNTIME=YES \
        build

    APP_PATH="build/Release/${APP_NAME}.app"
    if [ ! -d "$APP_PATH" ]; then
        echo "❌ Error: Build failed — cannot find $APP_PATH"
        exit 1
    fi
    echo "✅ Build succeeded"
}

sign_app() {
    ENTITLEMENTS_PATH="FinderHover/FinderHover.entitlements"

    if [ ! -f "$ENTITLEMENTS_PATH" ]; then
        echo "❌ Error: Entitlements file not found at $ENTITLEMENTS_PATH"
        exit 1
    fi

    echo "🔏 Signing .app with hardened runtime + entitlements..."
    codesign --force --deep \
        --sign "$SIGN_IDENTITY" \
        --timestamp \
        --options runtime \
        --entitlements "$ENTITLEMENTS_PATH" \
        --identifier "$BUNDLE_ID" \
        "build/Release/${APP_NAME}.app"

    echo "🔍 Verifying signature..."
    codesign --verify --deep --strict --verbose=2 "build/Release/${APP_NAME}.app"
    echo "🔍 Entitlements embedded:"
    codesign -d --entitlements - "build/Release/${APP_NAME}.app" 2>&1 | head -20
    echo "✅ App signature verified (notarization check will happen after DMG submission)"
}

create_dmg() {
    echo "🧹 Removing old build artifacts..."
    rm -rf dmg-temp
    rm -f "${DMG_NAME}.dmg" "${DMG_NAME}-unsigned.dmg"

    echo "📁 Assembling DMG contents..."
    mkdir -p dmg-temp
    cp -R "build/Release/${APP_NAME}.app" dmg-temp/
    ln -s /Applications dmg-temp/Applications

    echo "📦 Creating DMG..."
    hdiutil create -volname "${APP_NAME}" \
        -srcfolder dmg-temp \
        -ov -format UDZO \
        "${DMG_NAME}-unsigned.dmg"

    rm -rf dmg-temp

    echo "🔏 Signing DMG..."
    codesign --force --sign "$SIGN_IDENTITY" --timestamp "${DMG_NAME}-unsigned.dmg"

    mv "${DMG_NAME}-unsigned.dmg" "${DMG_NAME}.dmg"
    echo "✅ DMG created and signed: ${DMG_NAME}.dmg"
}

notarize_dmg() {
    echo "📤 Submitting DMG for notarization..."
    xcrun notarytool submit "${DMG_NAME}.dmg" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_PASSWORD" \
        --wait \
        --verbose

    echo "📎 Stapling notarization ticket..."
    xcrun stapler staple "${DMG_NAME}.dmg"

    echo "🔍 Verifying notarization..."
    spctl --assess --type open --context context:primary-signature --verbose "${DMG_NAME}.dmg"
    echo "✅ DMG notarized and stapled"
}

create_signed_zip() {
    echo "📦 Creating signed ZIP for Homebrew Cask..."
    rm -f "${APP_NAME}.app.zip"
    cd "build/Release"
    ditto -c -k --keepParent "${APP_NAME}.app" "${PROJECT_ROOT}/${APP_NAME}.app.zip"
    cd "$PROJECT_ROOT"

    echo "📤 Submitting ZIP for notarization..."
    xcrun notarytool submit "${APP_NAME}.app.zip" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_PASSWORD" \
        --wait \
        --verbose

    echo "📎 Stapling notarization ticket to ZIP..."
    xcrun stapler staple "${APP_NAME}.app.zip" 2>/dev/null || \
        echo "ℹ️  Note: Stapling ZIP is not supported; the notarization ticket is embedded in the app."
    echo "✅ ZIP created and notarized"
}

print_checksums() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Done! Signed & notarized build complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📦 Created files:"
    echo "   • ${DMG_NAME}.dmg"
    echo "   • ${APP_NAME}.app.zip  (for Homebrew Cask / GitHub Release)"
    echo ""
    echo "🔑 SHA-256 checksums (for Homebrew Cask formula):"
    echo "   DMG: $(shasum -a 256 "${DMG_NAME}.dmg" | awk '{print $1}')"
    echo "   ZIP: $(shasum -a 256 "${APP_NAME}.app.zip" | awk '{print $1}')"
    echo ""
}

main() {
    echo "🚀 Starting signed DMG build..."
    validate_required_vars
    resolve_paths
    read_project_metadata
    clean_extended_attributes
    build_release
    sign_app
    create_dmg
    notarize_dmg
    create_signed_zip
    print_checksums
}

main
