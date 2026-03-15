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
4. show the clean screen overlay if the preset enables it
5. mark the session as active and keep a small snapshot of what Meeting Mode actually changed

Important limits:

- hiding non-preset apps is a best-effort product direction, not a promise of full macOS control
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
- app launch from preset data
- best-effort hiding of regular visible apps that are outside the active preset
- link and local file opening
- clean screen overlay
- active session state
- restore UI flow
- best-effort re-show of only the apps that Meeting Mode actually hid during the current session
- best-effort quit for apps launched by Meeting Mode during the session
- the current runtime flow has been revalidated with `Safari` and `Notes` as hidden apps, then shown again by `Restore Session`

What is not implemented yet:

- restore of opened links and opened files
- advanced window management

Important caveat:

- app hiding is limited to regular apps and stays best effort
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

The next product step is not a new big surface area. It is to make the current session flow more reliable and more explicit:

1. revalidate the visibility rule against real macOS behavior
2. keep clearer feedback when some apps stay visible
3. preserve the narrow restore scope
4. avoid drifting into window-management behavior

If macOS behavior is ambiguous, the app should degrade conservatively instead of pretending the restore is perfect.
