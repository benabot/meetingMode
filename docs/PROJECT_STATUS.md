# Project Status

Date: 2026-03-15

## Current State

- Clean macOS SwiftUI Xcode project in place.
- Single app target: `MeetingMode`.
- Menu bar app configured as a background-only app with a native `NSStatusItem`.
- The menu bar interaction uses a compact graphical `NSPopover` hosting SwiftUI content.
- The current target is not App Sandbox-enabled, so local launch and restore behavior can work predictably during MVP development.
- `Settings...` now opens a dedicated settings window from the menu bar panel.
- Models and services compile and stay intentionally small.
- Presets are now loaded from a simple local JSON source under Application Support.
- The app seeds one local `Quick Test` preset when no preset data exists yet.
- Multiple presets are supported by the local store and the lightweight editor, but the runtime seed stays intentionally limited to one default preset.
- A minimal preset editor is available directly from the menu bar content.
- The preset editor is now split into `Basics`, `What starts`, and `Checklist` so the intent stays readable.
- The currently selected preset is persisted across relaunches with a small local preference.
- `Preset` now stores apps, URLs, local files, checklist items, and clean screen intent.
- Selected apps are now stored as app references with bundle identifier and bundle path, with fallback to display name for older data.
- The session UI now exposes explicit `Inactive`, `Active`, and `Restored` states.
- The active session now creates a minimal snapshot for best-effort restore.
- Apps, URLs, and local files are now opened with simple `NSWorkspace` calls.
- A simple clean screen overlay window is available on the main screen.
- Restore now hides the clean screen and uses a two-step close path for apps launched by Meeting Mode: polite quit first, force quit fallback if needed.
- No app hiding logic and no multi-screen overlay management are implemented yet.

## MVP Flow Status

- The current MVP test flow is already end-to-end in the menu bar: select preset, start session, see a visible clean screen effect, then restore.
- `Quick Test` is sufficient to verify the core flow without any manual preset setup.
- `Start Session` opens `TextEdit`, shows the clean screen overlay, and switches the session to `Active`.
- The current `Quick Test` preset contains only `TextEdit` plus clean screen. Finder is not part of the preset data.
- `Restore Session` hides the overlay and restores the UI state correctly.
- The restore path now escalates from polite quit to force quit for apps launched by the session to improve reliability on `TextEdit`.
- A targeted local verifier confirmed that `TextEdit` no longer remained running after restore through the service path. The full menu bar flow should still be rechecked manually.
- The popover is now intentionally shorter and split into `Preset`, `Plan` or `Session`, and `Actions`.
- Outside a session, the summary reflects preset intent. During a session, the summary reflects only actions actually applied and tracked.
- Simple clean screen and simple restore are no longer treated as later polish work because `Start Session` and `Restore Session` already exist in the UI.
- What remains later is narrower: more precise permission messaging, more robust local persistence, and UI polish.

## Visible Behavior Confirmed

- `xcodebuild -scheme MeetingMode -destination 'platform=macOS' build` succeeds.
- The app launches without a main window.
- The menu bar item remains visible at launch.
- Clicking the menu bar item opens a compact graphical panel reliably.
- Clicking `Settings...` closes the panel and opens a dedicated settings window.
- The menu bar content handles both the seeded preset path and an explicit empty state.
- Production no longer ships with built-in demo presets, but it seeds one functional local `Quick Test` preset when storage is empty.
- Only one preset is seeded by default. Additional presets are created manually from `New Preset`.
- `New Preset` opens a lightweight editor and persists to the local JSON source.
- `Edit Preset` updates the currently selected preset with the same lightweight editor.
- `Open apps` now uses `Add App…` and an `NSOpenPanel` rooted on `/Applications`, instead of free text entry by app name.
- Deleting a preset now goes through a simple confirmation and keeps selection coherent.
- The selected preset is restored after relaunch when it still exists.
- If the local JSON file is invalid, the app falls back to an empty preset state instead of silently reseeding demo data.
- If the local JSON file is present but empty (`[]`), the app keeps the empty state.
- The preset summary shows counts for apps, URLs, files, checklist items, and clean screen.
- Presets without any real start action are blocked early instead of starting a no-op session.
- While a session is active, preset selection and editing are disabled to make the single-session rule explicit.
- While a session is active, the menu shows tracked restore data from the session snapshot rather than preset intent.
- `Start Session` is only shown when a preset is actually selectable.
- `Restore Session` stays disabled while no session is active.
- The stub session flow goes `inactive -> active -> restored` without getting stuck.
- A second `start` call does not replace the current session.
- The snapshot tracks only Meeting Mode changes currently handled by the scaffold: launched apps, opened URLs, opened files, and clean screen state.
- Invalid app names, URLs, or file paths do not crash the session flow; they are counted as non-blocking open failures.
- The clean screen overlay uses one borderless window on the main screen visible frame, so the menu bar stays reachable for restore.
- Restore hides the clean screen and attempts a polite quit followed by force quit if needed for apps launched by the session, but it does not attempt to close URLs or files.
- The restore path now distinguishes between an app that actually closed and an app that may still be open after the quit request.
- Apps that were already running before the session are not included in the restore quit scope.
- Permission messaging states only what is true today: nothing is checked or requested yet.

## Still Intentionally Stubbed

- App hiding
- Restore of opened URLs and local files
- Permission inspection or permission requests
- Multi-screen overlay management

## Out Of Scope For This Pass

- Advanced window management
- Perfect restoration of windows, tabs, or Spaces
- Cloud sync
- AI features
- Deep Slack / Zoom / Teams / Calendar integrations
- Onboarding flow
