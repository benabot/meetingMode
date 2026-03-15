# Xcode Setup

## Project Path

- Project: `/Users/benoitabot/Sites/meetingMode/MeetingMode.xcodeproj`
- Scheme: `MeetingMode`

## Open In Xcode

```bash
open /Users/benoitabot/Sites/meetingMode/MeetingMode.xcodeproj
```

## Discover Schemes

```bash
xcodebuild -project /Users/benoitabot/Sites/meetingMode/MeetingMode.xcodeproj -list
```

## Build

```bash
xcodebuild \
  -project /Users/benoitabot/Sites/meetingMode/MeetingMode.xcodeproj \
  -scheme MeetingMode \
  -destination 'platform=macOS' \
  build
```

## Notes

- The app is configured as a menu bar app with `LSUIElement = YES`.
- The current target is intentionally minimal and contains no business implementation.
- Assets live under `MeetingMode/Resources/Assets.xcassets`.
