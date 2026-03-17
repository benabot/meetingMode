# Release Build — Meeting Mode

`scripts/build-release.sh` builds, signs, packages, notarizes, and staples Meeting Mode for direct distribution outside the App Store.

## Prerequisites

- macOS with Xcode installed and `xcodebuild` available
- Active Apple Developer Program membership
- **Developer ID Application** certificate installed in your keychain for team `3Q33594A3N`
- An **app-specific password** for your Apple ID (used for notarization)

## Required environment variables

| Variable | Description | Example |
|---|---|---|
| `APPLE_ID` | Apple ID for notarization | `you@example.com` |
| `TEAM_ID` | Developer team ID | `3Q33594A3N` |
| `APP_SPECIFIC_PASSWORD` | App-specific password | `xxxx-xxxx-xxxx-xxxx` |

### How to generate an app-specific password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in → **Security** → **App-Specific Passwords**
3. Click **+** and give it a label (e.g. "MeetingMode notarytool")
4. Copy the generated password — it is only shown once

## Usage

Run from the project root:

```bash
APPLE_ID="you@example.com" \
TEAM_ID="3Q33594A3N" \
APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
./scripts/build-release.sh
```

The script produces `build/MeetingMode.dmg` — signed, notarized, and stapled.

## What the script does

1. Archives the app in Release configuration (`build/MeetingMode.xcarchive`)
2. Exports the archive using `scripts/ExportOptions.plist` (Developer ID, automatic signing)
3. Creates a DMG with the app and a symlink to `/Applications`
4. Submits the DMG to Apple's notarization service and waits for approval
5. Staples the notarization ticket to the DMG

## Manual steps if the script fails

### Archive step fails
- Check that the Developer ID Application certificate is installed: `security find-identity -v -p codesigning`
- Check that `DEVELOPMENT_TEAM = 3Q33594A3N` is set in the project build settings

### Export step fails
- Check that `scripts/ExportOptions.plist` has the correct `teamID`
- Open the archive in Xcode Organizer to inspect signing errors

### Notarization step fails
- Verify `APPLE_ID`, `TEAM_ID`, and `APP_SPECIFIC_PASSWORD` are correct
- Check the notarization log: `xcrun notarytool log <submission-id> --apple-id $APPLE_ID --team-id $TEAM_ID --password $APP_SPECIFIC_PASSWORD`
- Common reason: hardened runtime entitlements missing — verify `ENABLE_HARDENED_RUNTIME = YES` in Release build settings

### Staple step fails
- Stapling requires a successful notarization first
- If notarization succeeded but stapling fails, retry: `xcrun stapler staple build/MeetingMode.dmg`

## Build settings reference

| Setting | Value |
|---|---|
| `ENABLE_HARDENED_RUNTIME` | `YES` (Debug + Release) |
| `ENABLE_APP_SANDBOX` | `NO` — required for `NSWorkspace` app launch/hide, `NSRunningApplication.terminate`, and Carbon `RegisterEventHotKey` |
| `CODE_SIGN_STYLE` | `Automatic` |
| `DEVELOPMENT_TEAM` | `3Q33594A3N` |
| `PRODUCT_BUNDLE_IDENTIFIER` | `fr.beabot.meetingmode` |
| `MARKETING_VERSION` | `0.1.0` |

## Distribution channel

Direct distribution only (DMG). Not submitted to the Mac App Store.
App Store submission would require sandbox entitlements incompatible with the current `NSWorkspace` and `NSRunningApplication` APIs used for app visibility management.
