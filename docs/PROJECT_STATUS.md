# Project Status

Date: 2026-03-15

## Current State

- Clean macOS SwiftUI Xcode project in place.
- Single app target: `MeetingMode`.
- Menu bar app configured as a background-only app with a native `NSStatusItem`.
- The menu bar interaction uses a compact graphical `NSPopover` hosting SwiftUI content.
- The popover width is now aligned with its real content width so it stays readable near the right edge of the menu bar.
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
- The active session now creates a minimal snapshot for best-effort restore, including only the exact app instances that were actually hidden by Meeting Mode during the session.
- Apps, URLs, and local files are now opened with simple `NSWorkspace` calls.
- A small `AppVisibilityService` now hides regular visible apps that are outside the active preset, excluding Meeting Mode itself.
- A simple clean screen overlay window is available on the main screen as an independent visual background complement.
- Restore now hides the clean screen and uses a two-step close path for apps launched by Meeting Mode: polite quit first, force quit fallback if needed.
- Restore now re-shows only the apps that Meeting Mode itself actually hid during the current session.
- No multi-screen overlay management is implemented yet.

## MVP Flow Status

- The current MVP test flow is already end-to-end in the menu bar: select preset, start session, see a visible clean screen effect, then restore.
- `Quick Test` is sufficient to verify the core flow without any manual preset setup.
- `Start Session` opens `Calculator`, shows the clean screen overlay, and switches the session to `Active`.
- The current `Quick Test` preset contains only `Calculator` plus clean screen.
- The start flow now also attempts to hide regular visible apps that are outside the active preset, in best effort only.
- The visible session result is intended to come primarily from app visibility rules. The overlay stays independent and does not use per-app window-level exceptions.
- `Restore Session` hides the overlay and restores the UI state correctly.
- `Restore Session` now explicitly attempts to re-show only the apps that were actually hidden by Meeting Mode during the current session.
- The visibility restore path now targets the exact tracked app instances first, then falls back only when needed for older snapshot data.
- The visibility restore path now requests `unhide` and window activation first, then confirms actual visibility only after the main run loop has had time to apply those changes.
- If a tracked app still remains hidden after that deferred confirmation, Meeting Mode now retries through a targeted `openApplication` fallback on that same running app bundle, still without broad restore scope.
- Restore now closes session-launched apps before attempting to make previously hidden apps visible again, so the session app does not immediately steal focus back.
- The restore path still escalates from polite quit to force quit for apps launched by the session, but this remains best effort rather than a guaranteed system rollback.
- The popover is now intentionally shorter and split into `Preset`, `Plan` or `Session`, and `Actions`.
- Outside a session, the summary reflects preset intent. During a session, the summary reflects only actions actually applied and tracked.
- The visibility rule stays intentionally narrow: only regular apps are considered, Meeting Mode itself is excluded, and only apps actually hidden with success are tracked for restore.
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
- Legacy local `Quick Test` data that still points to `TextEdit` is migrated automatically to `Calculator` so the seed stays deterministic and avoids document dialogs.
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
- Outside a session, the menu now warns that other visible apps may be hidden in best effort.
- After restore, the menu keeps the last restore result visible instead of immediately falling back to an overly optimistic ready state.
- `Start Session` is only shown when a preset is actually selectable.
- `Restore Session` stays disabled while no session is active.
- The stub session flow goes `inactive -> active -> restored` without getting stuck.
- A second `start` call does not replace the current session.
- The snapshot tracks only Meeting Mode changes currently handled by the scaffold: launched apps, exact hidden app instances, opened URLs, opened files, and clean screen state.
- Invalid app names, URLs, or file paths do not crash the session flow; they are counted as non-blocking open failures.
- Only regular apps outside the preset are candidates for hiding, and only apps that were actually confirmed hidden after the start flow are tracked for restore.
- The clean screen overlay uses one borderless window on the main screen visible frame, so the menu bar stays reachable for restore.
- The overlay now sits below regular app windows on purpose. Preset apps stay accessible because they are not hidden, not because they pierce the overlay through fragile window-level tricks.
- Restore hides the clean screen, explicitly re-shows only the tracked apps that Meeting Mode itself hid, and attempts a polite quit followed by force quit if needed for apps launched by the session, but it does not attempt to close URLs or files.
- While restore visibility is still being confirmed, the popover summary now says `Checking hidden apps` instead of reporting a finished restore too early.
- The restore path now distinguishes between an app that actually closed and an app that may still be open after the quit request.
- Visibility restore remains best effort only. Meeting Mode does not attempt advanced window or Space restoration.
- A targeted local Safari / Notes probe now confirms the runtime path used by the app: apps can hide and re-show only after control returns to the main event loop, so visibility confirmation is intentionally deferred.
- The real menu bar flow has now been revalidated on the machine with `Safari` and `Notes`: they hide during the session and become visible again after `Restore Session`.
- Apps that were already running before the session are not included in the restore quit scope.
- Permission messaging states only what is true today: nothing is checked or requested yet.

## Still Intentionally Stubbed

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
