# Meeting Mode

Meeting Mode is a macOS menu bar app that prepares your Mac for meetings, demos, interviews, and screen sharing in one click.

The goal is simple: reduce last-minute friction before a call and restore a clean working state afterward.

## Why this project exists

Before a meeting, users often need to:

- open the right apps
- hide distracting or private apps
- open a brief, notes, or a specific URL
- prepare a clean screen for screen sharing
- avoid wasting time on repetitive setup

Meeting Mode turns that manual routine into reusable presets.

## Core idea

A **preset** represents a repeatable meeting context, for example:

- Client Call
- Product Demo
- Interview
- Internal Standup
- Screen Recording

When a preset starts, the app can:

- launch selected apps
- hide selected apps
- open URLs or local documents
- show a clean screen overlay
- display a pre-call checklist
- keep enough session state to support a practical restore flow

## MVP scope

The first version should stay intentionally small.

### Included in v1

- macOS menu bar app
- preset creation and editing
- launch selected apps
- hide selected apps
- open URLs and local files
- clean screen overlay
- pre-call checklist
- restore button
- optional keyboard shortcut
- local persistence

### Explicitly out of scope for v1

- advanced window positioning
- perfect session restoration
- cloud sync
- calendar integrations
- Slack, Zoom, or Teams deep integrations
- AI features
- analytics complexity
- multi-user collaboration

## Product principles

1. **Fast** — users should be able to start a preset in seconds.
2. **Predictable** — actions should be visible and reversible.
3. **Small surface area** — avoid building a generic productivity suite.
4. **Safe by default** — do not promise system-wide magic that macOS may not reliably allow.
5. **Clear restore model** — restore what the app changed when possible, and be explicit about limits.

## Target users

- freelancers
- consultants
- sales teams
- support teams
- recruiters
- trainers
- developers giving demos
- anyone who frequently shares their screen

## User stories

### As a user, I want to:

- launch the right set of apps for a meeting with one click
- hide private or distracting apps before sharing my screen
- open my brief, notes, or project page automatically
- display a clean screen before screen sharing starts
- restore my previous workflow after the meeting

## Main flows

### 1. Create a preset

A user creates a preset with:

- name
- icon
- apps to launch
- apps to hide
- URLs or files to open
- optional clean screen overlay
- optional checklist
- optional auto-restore timer

### 2. Start a session

When a user starts a preset, the app should:

1. create a lightweight session snapshot
2. launch the configured apps
3. hide the configured apps
4. open URLs and local files
5. activate the clean screen overlay if enabled
6. show the checklist
7. mark the session as active

### 3. Restore a session

When a user clicks restore, the app should:

1. close the clean screen overlay
2. quit or hide apps launched by the preset when appropriate
3. re-show apps hidden by the preset when appropriate
4. clear the active session state
5. return to idle state

## Recommended tech stack

- **Language:** Swift
- **UI:** SwiftUI
- **macOS integration:** AppKit where needed
- **App entry:** menu bar app using `MenuBarExtra`
- **Persistence:** UserDefaults for prototype, file-based JSON or SwiftData later if needed
- **Automation:** minimal and permission-aware
- **Target platform:** macOS only

## Suggested project structure

```text
MeetingMode/
├── MeetingModeApp.swift
├── Models/
│   ├── Preset.swift
│   ├── SessionSnapshot.swift
│   └── ChecklistItem.swift
├── Services/
│   ├── PresetStore.swift
│   ├── SessionRunner.swift
│   ├── RestoreService.swift
│   ├── OverlayService.swift
│   ├── PermissionService.swift
│   └── AppLauncherService.swift
├── Views/
│   ├── MenuBar/
│   ├── Presets/
│   ├── Onboarding/
│   ├── Session/
│   └── Settings/
├── Utilities/
└── Resources/
```

## Data model

### Preset

```swift
struct Preset: Identifiable, Codable {
    let id: UUID
    var name: String
    var iconName: String
    var appsToLaunch: [String]
    var appsToHide: [String]
    var urlsToOpen: [String]
    var localFilesToOpen: [String]
    var overlayEnabled: Bool
    var checklistItems: [ChecklistItem]
    var autoRestoreMinutes: Int?
    var createdAt: Date
    var updatedAt: Date
}
```

### SessionSnapshot

```swift
struct SessionSnapshot: Codable {
    let presetID: UUID
    let startedAt: Date
    let runningAppsBefore: [String]
    let launchedByMeetingMode: [String]
    let hiddenByMeetingMode: [String]
    let openedURLs: [String]
    let openedFiles: [String]
    let overlayEnabled: Bool
}
```

## UI outline

### Menu bar

The menu bar should let the user:

- see available presets
- start a preset
- restore an active session
- open settings
- quit the app

### Main configuration window

Sections:

- Presets list
- Preset editor
- Checklist editor
- Overlay options
- Keyboard shortcut settings
- About / support

### Active session panel

Show:

- current preset name
- elapsed time
- actions performed
- restore button
- panic button

## Permissions and system constraints

This project should respect macOS limitations instead of fighting them.

Important principles:

- do not assume full control of every app or window
- treat app automation as permission-sensitive
- avoid promising perfect restoration of windows, tabs, or desktop state
- keep the initial implementation conservative and reliable

## Build goals

### Milestone 1 — functional prototype

- menu bar app boots correctly
- presets can be created locally
- apps can be launched
- apps can be hidden
- URLs can be opened
- overlay can be shown and dismissed
- restore works in a basic way

### Milestone 2 — usable MVP

- onboarding flow
- better preset editing UX
- checklist support
- better error handling
- active session state
- keyboard shortcut
- polished restore flow

### Milestone 3 — launch-ready

- stable UX
- clean app icon
- app website / landing page
- pricing screen or licensing flow
- help and support docs
- release build and signing

## Non-goals

Meeting Mode is **not**:

- a full window manager
- a universal automation platform
- a calendar assistant
- a video conferencing client
- a note-taking app
- a remote collaboration suite

## Development guidelines

- keep files small and cohesive
- prefer simple state flows over clever abstractions
- ship the smallest working version first
- optimize for reliability, not feature count
- document system limitations in code comments where relevant
- favor explicit behavior over hidden automation

## Testing priorities

Focus on:

- preset persistence
- app launch / hide behavior
- overlay lifecycle
- restore correctness
- failure handling when apps or files are unavailable
- startup performance

## Release strategy

Recommended commercial strategy for the first release:

- one-time purchase
- no subscription in v1
- fast onboarding
- strong demo video
- clear before/after product messaging

## Roadmap ideas after v1

- multiple overlay styles
- preset duplication templates
- better restore reporting
- imported preset packs
- meeting countdown
- audio device reminders
- calendar launch hooks
- pro automation extensions

## Contributing

This repository prioritizes small, reviewable changes.

When contributing:

- avoid broad refactors unless necessary
- keep UX flows simple
- document tradeoffs in pull requests
- do not add speculative features without a concrete use case

## License

TBD

## Notes for AI coding agents

This README gives product context.

If this repository is meant to be used with Codex, repository-specific operating instructions should live in a dedicated `AGENTS.md` file at the repo root, covering:

- coding standards
- commands to run
- testing expectations
- review rules
- repository conventions

This keeps product documentation separate from agent instructions.
