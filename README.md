# Meeting Mode

Meeting Mode is a macOS menu bar app for preparing a Mac before a meeting, a demo, or a screen share.

The product goal is narrow:

- start the right apps, links, and files quickly
- reduce visible distractions before sharing a screen
- show a simple clean screen overlay when needed
- keep restore understandable and best effort

## Target Session Behavior

### Start Session

Target behavior for `Start Session`:

1. launch the apps configured in the preset
2. open the preset links and local files
3. hide, in best effort, the visible apps that are not part of the active preset
4. show the clean screen overlay as an independent visual background if the preset enables it
5. mark the session as active and keep a small snapshot of what Meeting Mode actually changed

Important limits:

- hiding non-preset apps is a best-effort product direction, not a promise of full macOS control
- the overlay is independent from any specific app and does not rely on some apps magically staying above it
- keeping preset apps accessible should come mainly from app visibility rules, not from window-level exceptions
- Meeting Mode should not force-close every other app
- Meeting Mode should not try to manage windows, tabs, Spaces, or desktop state in v1

### Restore Session

Target behavior for `Restore Session`:

1. hide the clean screen overlay
2. restore only what Meeting Mode actually changed during the current session
3. re-show only the apps that Meeting Mode itself actually hid
4. best-effort quit only the apps launched by Meeting Mode when that is part of the current restore scope
5. clear the active session state

Important limits:

- restore stays best effort
- no promise of perfect window restoration
- no promise of tab restoration
- no promise of Spaces restoration
- no hidden system magic

## Current Implementation Status

What is already implemented in the current build:

- menu bar app with a compact popover UI
- local presets with create, edit, delete, and selected preset persistence
- app and file selection in the preset editor via `NSOpenPanel` (no free-text path entry)
- app launch from preset data
- best-effort hiding of regular visible apps that are outside the active preset
- link and local file opening
- clean screen overlay covering all connected screens as an independent visual complement
- active session state
- restore UI flow
- best-effort re-show of only the apps that Meeting Mode actually hid during the current session
- best-effort quit for apps launched by Meeting Mode during the session
- the current runtime flow has been revalidated with `Safari` and `Notes` as hidden apps, then shown again by `Restore Session`
- session snapshot persisted to disk so restore remains available after a crash or force quit
- unit test suite: 17 tests across `PresetStore` (8 tests) and `SessionRunner` (9 tests)

What is not implemented yet:

- cleanup of URLs and local files opened by the session
- advanced window management

## Planned Next Versions

### V2 — Session-opened URLs and files cleanup

Planned scope:

- track which URLs and local files were opened by the current session
- attempt a best-effort cleanup when `Restore Session` runs
- keep the product contract narrow and explicit

What this means in practice:

- if Meeting Mode opened a file in an app it launched for the session, restore may quit that app as part of the existing launched-app cleanup path
- if Meeting Mode opened a URL in a browser that was already running, the app should not claim it can close the exact tab reliably
- if Meeting Mode opened a file inside an app that was already running, the app should not claim it can close the exact document reliably

V2 limits:

- no per-tab browser control
- no per-document control inside already-running apps
- no promise of perfect cleanup
- restore remains best effort and session-scoped

### V3 — Mac App Store release track

Planned scope:

- prepare a sandbox-compatible release variant
- migrate file access to security-scoped bookmarks
- replace deprecated / weakly documented launch paths with sandbox-compatible APIs
- reduce the restore contract where sandbox rules make the current DMG behavior impossible

Known impact from the current audit:

- `NSRunningApplication.terminate()` and `forceTerminate()` are not available as a normal App Sandbox strategy
- an App Store build therefore cannot promise the same launched-app closing behavior as the current non-sandbox MVP build
- file reopening from persisted presets requires security-scoped bookmarks instead of raw stored paths

V3 product consequence:

- the DMG track can keep the current best-effort launched-app closing behavior
- the App Store track must present a narrower, more explicit restore contract
- no App Store release should pretend to offer a full system rollback

Important caveat:

- app hiding is limited to regular apps and stays best effort
- the overlay is intentionally simple and independent; it is not a per-app exception system
- the real end-to-end behavior still depends on what macOS lets Meeting Mode hide or re-show on the current machine, even though the current Safari / Notes path now works on the validation machine
- restore scope remains intentionally narrow and explicit

## MVP Scope

In scope for the MVP:

- macOS only
- Swift + SwiftUI
- menu bar app
- presets
- app launch
- link opening
- local file opening
- clean screen overlay
- checklist
- one active session at a time
- best-effort restore
- simple local persistence

Out of scope for the MVP:

- advanced window management
- perfect restoration of windows, tabs, or Spaces
- cloud sync
- AI features
- deep Slack / Zoom / Teams / Calendar integrations
- broad productivity features outside the meeting flow

## Product Rules

- prefer reliability over clever automation
- prefer explicit restore scope over “magic”
- keep one active session at a time
- keep services small and separate
- treat inter-app behavior as permission-sensitive and best effort
- do not claim system behavior that macOS does not guarantee

## Current App Shape

- macOS menu bar app
- SwiftUI-first UI with small AppKit bridges where needed
- `NSStatusItem` + `NSPopover`
- local JSON persistence for presets
- no third-party dependencies
- no Core Data or SwiftData

## Development Direction

The product path is now split into two pragmatic tracks:

1. finish the non-sandbox product flow with better cleanup of session-opened URLs and files
2. prepare a separate App Store-compatible release track with a deliberately reduced restore contract

The guiding rule stays the same:

- if macOS behavior is ambiguous, degrade conservatively
- if sandbox rules block a behavior, remove the promise instead of faking it
- do not drift into window-management or tab-management behavior
