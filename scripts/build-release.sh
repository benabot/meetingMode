#!/usr/bin/env bash
# build-release.sh — Build, export, package, notarize, and staple Meeting Mode for direct distribution.
#
# Required environment variables:
#   APPLE_ID              — Apple ID used for notarization (e.g. you@example.com)
#   TEAM_ID               — Apple Developer team ID (e.g. 3Q33594A3N)
#   APP_SPECIFIC_PASSWORD — App-specific password generated at appleid.apple.com
#
# Usage:
#   APPLE_ID="you@example.com" TEAM_ID="3Q33594A3N" APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx" ./scripts/build-release.sh

set -euo pipefail

SCHEME="MeetingMode"
ARCHIVE_PATH="build/MeetingMode.xcarchive"
EXPORT_PATH="build/release"
EXPORT_OPTIONS="scripts/ExportOptions.plist"
DMG_PATH="build/MeetingMode.dmg"
APP_NAME="MeetingMode"
VOL_NAME="Meeting Mode"

echo "==> Checking required environment variables"
: "${APPLE_ID:?APPLE_ID is not set}"
: "${TEAM_ID:?TEAM_ID is not set}"
: "${APP_SPECIFIC_PASSWORD:?APP_SPECIFIC_PASSWORD is not set}"

echo "==> Cleaning previous build artifacts"
rm -rf build/MeetingMode.xcarchive build/release build/MeetingMode.dmg

echo "==> Archiving (Release)"
xcodebuild \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'platform=macOS' \
    -archivePath "$ARCHIVE_PATH" \
    archive

echo "==> Exporting archive"
xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$EXPORT_PATH"

APP_PATH="$EXPORT_PATH/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: exported app not found at $APP_PATH"
    exit 1
fi

echo "==> Creating DMG"
STAGING_DIR=$(mktemp -d)
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "==> Notarizing DMG (this may take a few minutes)"
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --wait

echo "==> Stapling notarization ticket"
xcrun stapler staple "$DMG_PATH"

echo ""
echo "Done. Signed, notarized, and stapled DMG:"
echo "  $(pwd)/$DMG_PATH"
