# AGENTS.md

## Project

Meeting Mode is a macOS-only menu bar app that prepares a Mac for meetings, demos, interviews, and screen sharing.

Core product goal:
- start a reusable meeting preset in one click
- launch a small set of apps, URLs, and files
- hide distracting or private apps
- optionally show a clean screen overlay
- restore a practical working state afterward

Read `README.md` first for product context and scope.

## Scope guardrails

Treat the current project as a focused utility, not a general productivity suite.

In scope for the initial product:
- menu bar app
- preset creation and editing
- launching apps
- hiding apps
- opening URLs and local files
- clean screen overlay
- pre-call checklist
- practical restore flow
- local persistence

Explicitly out of scope unless asked:
- advanced window management
- perfect restoration of every window, tab, and desktop state
- cloud sync
- analytics platforms
- AI features
- calendar, Slack, Zoom, or Teams deep integrations
- large architectural rewrites

## Working rules for Codex

- Make the smallest correct change that solves the task.
- Preserve existing product scope.
- Prefer reliability over cleverness.
- Avoid adding dependencies unless clearly justified.
- Keep files cohesive and easy to review.
- Do not silently rename public types or reorganize the repo without a concrete reason.
- Document meaningful tradeoffs in comments or commit/PR notes.

## Technical preferences

- Language: Swift
- UI: SwiftUI first
- Use AppKit only where SwiftUI is not sufficient
- App style: macOS menu bar app using `MenuBarExtra`
- Persistence: simple local persistence first
- Keep automation permission-aware and conservative

## Code style

- Prefer explicit names over abbreviations.
- Prefer simple state flows over abstraction-heavy designs.
- Keep view code readable; extract helpers when a view becomes dense.
- Keep side effects inside dedicated services.
- Use structs for models unless reference semantics are clearly needed.
- Add comments only where behavior is non-obvious or macOS-specific.

## Suggested architecture

Expected high-level areas:
- `Models/`
- `Services/`
- `Views/`
- `Utilities/`
- `Resources/`

Typical service responsibilities:
- `PresetStore`: load/save presets
- `SessionRunner`: execute preset actions
- `RestoreService`: revert actions performed by the session
- `OverlayService`: manage clean screen overlay windows
- `PermissionService`: centralize permission checks and user guidance
- `AppLauncherService`: launch, activate, or hide apps safely

## Safety and platform constraints

Design around macOS constraints instead of fighting them.

- Do not promise system-wide magic.
- Assume automation may require user consent.
- Treat app control as permission-sensitive.
- Be explicit when restore behavior is best-effort.
- Do not implement invasive behavior that risks App Store rejection unless the task explicitly targets direct distribution.

## Build and test commands

If the Xcode project already exists, prefer these commands from the repo root.
If names differ, discover them first with `xcodebuild -list`.

### Discover project and scheme

```bash
xcodebuild -list
```

### Build

```bash
xcodebuild -scheme MeetingMode -destination 'platform=macOS' build
```

### Test

```bash
xcodebuild -scheme MeetingMode -destination 'platform=macOS' test
```

### Format/lint

If SwiftFormat or SwiftLint are present in the repository, use them. Do not add them just for style unless requested.

## Expected workflow per task

1. Read the relevant files before editing.
2. Stay inside the requested scope.
3. Apply a minimal patch.
4. Run the narrowest useful validation.
5. Report exactly what changed, what was verified, and any remaining limits.

## When implementing UI

- Favor fast, obvious interactions.
- Keep the number of steps low.
- Prefer simple panels and forms over complex multi-window flows.
- The active session state should always make restore easy to find.

## When implementing restore logic

- Track only what the app changed.
- Prefer a practical restore over a fragile “perfect restore”.
- Surface limits clearly in code and UI copy where relevant.

## When asked to add features

Default response in code should be to preserve the MVP shape.
Before adding a feature that expands the product surface area, check whether it belongs in post-v1 roadmap instead.

## Pull request / review expectations

When summarizing work, include:
- what changed
- why it changed
- what was validated
- any macOS limitation or permission caveat
- any follow-up that should happen later instead of now
