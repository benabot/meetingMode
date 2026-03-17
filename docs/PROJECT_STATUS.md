# Project Status

Date: 2026-03-15

## Current State

- Clean macOS SwiftUI Xcode project in place.
- Single app target: `MeetingMode`.
- Menu bar app configured as a background-only app with a native `NSStatusItem`.
- The menu bar interaction uses a compact graphical `NSPopover` hosting SwiftUI content.
- The popover width is now aligned with its real content width so it stays readable near the right edge of the menu bar.
- The popover, settings window, and preset editor now share a more transparent glass-style visual system with reusable cards and inset surfaces.
- That visual system is now tuned back toward readability first: stronger text contrast, lighter material overlays, and less milk-white fill on the surfaces.
- Buttons now use a stricter contrast-first hierarchy on top of the glass UI: strong filled primary, solid filled secondary, clear destructive, and visibly inactive disabled states.
- Text on the lighter glass surfaces now uses a dark grey / anthracite palette for primary and secondary copy, so sections, plans, settings descriptions, and helper labels stay readable without relying on pale white text.
- The current target is not App Sandbox-enabled, so local launch and restore behavior can work predictably during MVP development.
- `Settings...` now opens a dedicated settings window from the menu bar panel.
- `Settings...` now includes configurable shortcuts for `Start Session` and `Restore Session`.
- `Settings...` now includes a native `Launch at login` toggle backed by macOS login items.
- The app now supports a coherent FR / EN UI with an explicit language choice in `Settings`.
- A lightweight tutorial window now exists for first-run guidance and quick re-entry later from `Settings`.
- Models and services compile and stay intentionally small.
- Presets are now loaded from a simple local JSON source under Application Support.
- The app seeds one local `Quick Test` preset when no preset data exists yet.
- Multiple presets are supported by the local store and the lightweight editor, but the runtime seed stays intentionally limited to one default preset.
- A minimal preset editor is available directly from the menu bar content.
- The preset editor is now split into `Basics`, `What starts`, and `Checklist` so the intent stays readable.
- The preset editor now opens in a dedicated fixed-width window instead of a sheet attached to the menu bar popover, so it stays fully visible near the right edge of the screen.
- The currently selected preset is persisted across relaunches with a small local preference.
- Start and Restore shortcuts are now persisted locally and restored on relaunch.
- Launch at login state is now read from the real macOS login item registration instead of a separate local preference.
- The chosen app language is now persisted locally and restored on relaunch.
- Tutorial first-run state is now persisted locally so the tutorial auto-opens only once.
- `Preset` now stores apps, URLs, local files, checklist items, and clean screen intent.
- Selected apps are now stored as app references with bundle identifier and bundle path, with fallback to display name for older data.
- The session UI now exposes explicit `Inactive`, `Active`, and `Restored` states.
- The active session now creates a minimal snapshot for best-effort restore, including only the exact app instances that were actually hidden by Meeting Mode during the session.
- Apps, URLs, and local files are now opened with simple `NSWorkspace` calls.
- A small `AppVisibilityService` now hides regular visible apps that are outside the active preset, excluding Meeting Mode itself.
- A simple clean screen overlay window is available on the main screen as an independent visual background complement.
- Restore now hides the clean screen and uses a two-step close path for apps launched by Meeting Mode: polite quit first, force quit fallback if needed.
- Restore now re-shows only the apps that Meeting Mode itself actually hid during the current session.
- The active session snapshot is now persisted to a local JSON file so a crash or force quit does not lose restore capability.
- On relaunch after a crash, the session resumes as `.active` and `Restore Session` is available.
- The persisted snapshot includes the latest confirmed `hiddenApplications` from the deferred visibility phase.
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
- Start and Restore shortcuts now trigger the same session actions as the popover buttons.
- The visible app UI is now localized across the menu bar popover, preset editor, settings, overlay, and session / restore messaging.
- A small tutorial explains what Meeting Mode does, what a preset contains, what `Start Session` does, what `Restore Session` does, and the main product limits.
- The popover is now intentionally shorter and split into `Preset`, `Plan` or `Session`, and `Actions`.
- Outside a session, the summary reflects preset intent. During a session, the summary reflects only actions actually applied and tracked.
- The visibility rule stays intentionally narrow: only regular apps are considered, Meeting Mode itself is excluded, and only apps actually hidden with success are tracked for restore.
- Simple clean screen and simple restore are no longer treated as later polish work because `Start Session` and `Restore Session` already exist in the UI.
- What remains later is narrower: more precise permission messaging, more robust local persistence, and UI polish.

## Visible Behavior Confirmed

- `xcodebuild -scheme MeetingMode -destination 'platform=macOS' build` succeeds.
- The app bundle now carries a custom Meeting Mode icon through `AppIcon`, so Finder and normal app launching use app-specific icon metadata.
- Because `MeetingMode` still runs as a background-only menu bar app, that bundle icon is used for Finder and app launch surfaces, but the app is still not meant to stay in the Dock after launch.
- The app launches without a main window.
- The menu bar item remains visible at launch.
- Clicking the menu bar item opens a compact graphical panel reliably.
- The menu bar panel, settings window, and preset editor now use the same visual hierarchy: clear status card first, then grouped surfaces for preset, session, and actions.
- The menu bar actions now use full-width primary buttons, so localized labels such as `Démarrer la session` and `Restaurer la session` no longer need to truncate.
- Secondary actions now keep more visible tint in the menu bar so `Settings`, `New`, `Edit`, `Restore`, and destructive actions remain distinct at a glance.
- Clicking `Settings...` closes the panel and opens a dedicated settings window.
- On first launch, the tutorial opens automatically once in a small dedicated window.
- After that first-launch tutorial closes, the main menu bar panel opens automatically so the user lands directly in the primary UI.
- The menu bar content handles both the seeded preset path and an explicit empty state.
- Production no longer ships with built-in demo presets, but it seeds one functional local `Quick Test` preset when storage is empty.
- Legacy local `Quick Test` data that still points to `TextEdit` is migrated automatically to `Calculator` so the seed stays deterministic and avoids document dialogs.
- Only one preset is seeded by default. Additional presets are created manually from `New Preset`.
- `New Preset` opens a lightweight editor and persists to the local JSON source.
- `Edit Preset` updates the currently selected preset with the same lightweight editor.
- `New Preset` and `Edit Preset` now open a fixed-width editor window with vertical scrolling only, so `Open apps`, `Add App…`, and row actions stay inside the visible layout.
- That preset editor now keeps the same fixed-width layout but uses the same glass-style surfaces as the rest of the app, without adding horizontal scroll or layout drift.
- The visible hierarchy is now more explicit: hero status card first, more transparent section cards for preset and plan, stronger action surface, and a quieter footer.
- The button system has been simplified further so the UI no longer depends on thin tinted outlines: buttons are now more solid, more contrast-driven, and easier to read on translucent surfaces.
- `Open apps` now uses `Add App…` and an `NSOpenPanel` rooted on `/Applications`, instead of free text entry by app name.
- Deleting a preset now goes through a simple confirmation and keeps selection coherent.
- The selected preset is restored after relaunch when it still exists.
- Start and Restore shortcuts can be set, changed, or cleared from Settings.
- The `Launch at login` checkbox reflects the real macOS login item state and can register or unregister the app without adding a helper app.
- The language can be switched explicitly between French and English in Settings.
- The language change applies coherently to the popover, settings window, preset editor, and session text without mixing major app strings.
- The tutorial can be skipped, completed, or reopened later from `Settings` without resetting the first-launch behavior.
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
- The Restore shortcut leaves the app in a safe state when no session is active.
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
- If the app is force-quit during an active session and relaunched, the session snapshot is loaded from disk, the phase resumes as `Active`, and `Restore Session` becomes available immediately.
- After a crash recovery, the overlay is not re-shown because the overlay window was lost with the previous process, but restore of hidden apps still works from the persisted snapshot.
- Permission messaging now states that Accessibility, Automation, and Screen Recording are not required by the current implementation, with a concrete technical reason for each.
- The `Settings` window no longer shows internal developer sections (`Project Status`, `Scope Guardrails`).
- The `Launch at login` toggle is now disabled when macOS cannot register the login item.
- Shortcut display now correctly shows punctuation keys (`-`, `=`, `[`, `]`, `;`, `'`, `,`, `.`, `/`, `\\`, `` ` ``) instead of falling back to `Key N`.
- A few native macOS strings still remain system-managed, such as standard `NSOpenPanel` chrome outside the app-provided title and prompt.
- The login-item flow can still require approval from macOS, and that approval wording remains system-managed by the OS.
- The tutorial remains intentionally lightweight: a few pages, plain navigation, no blocking wizard, and no marketing copy.

## Still Intentionally Stubbed

- Restore of opened URLs and local files
- Multi-screen overlay management

## Out Of Scope For This Pass

- Advanced window management
- Perfect restoration of windows, tabs, or Spaces
- Cloud sync
- AI features
- Deep Slack / Zoom / Teams / Calendar integrations
