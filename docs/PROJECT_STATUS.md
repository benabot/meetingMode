# Project Status

Date: 2026-03-15

## Current State

- Clean macOS SwiftUI Xcode project in place.
- Single app target: `MeetingMode`.
- Menu bar app configured as a background-only app with `MenuBarExtra`.
- Minimal Settings scene available.
- Models and services compile and stay stub-based.
- Presets are now loaded from a simple local JSON source under Application Support.
- The app starts empty by default until real presets are saved locally.
- No real app automation and no real overlay window implemented yet.

## Visible Behavior Confirmed

- `xcodebuild -scheme MeetingMode -destination 'platform=macOS' build` succeeds.
- The app launches without a main window.
- The menu bar item remains visible at launch.
- The menu bar content handles both sample presets and an explicit empty state.
- Production no longer ships with built-in demo presets.
- `Start Session` is only shown when a preset is actually selectable.
- `Restore Session` stays disabled while no session is active.
- The stub session flow goes `inactive -> active -> inactive` without getting stuck.
- Permission messaging states only what is true today: nothing is checked or requested yet.

## Still Intentionally Stubbed

- Real app launch and hide logic
- Real clean screen overlay window
- Restore beyond a simple best-effort state reset
- Permission inspection or permission requests
- Local preset writing
- Preset editing UI

## Out Of Scope For This Pass

- Advanced window management
- Perfect restoration of windows, tabs, or Spaces
- Cloud sync
- AI features
- Deep Slack / Zoom / Teams / Calendar integrations
- Onboarding flow
