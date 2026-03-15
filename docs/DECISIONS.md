# Decisions

## 2026-03-15

### Rebuild Strategy

- Reused the existing Xcode template only as a container.
- Renamed every project path derived from `Sujet : Préparer landing page, pricing et plan de lancement`.
- Removed generated test targets to keep the foundation small and focused.

### App Shape

- macOS only.
- SwiftUI first, with small AppKit bridges only where macOS behavior requires them.
- `NSStatusItem` plus `NSPopover`, and a `Settings` scene.
- One active session modelled at a time.
- App launches as a background-only menu bar app, with no main window.
- App Sandbox is currently disabled for the MVP target so launch and restore flows can operate on other local apps during development.

### MVP Sequencing

- The first testable MVP flow includes preset selection, a visible `Start Session`, a simple clean screen, and a simple restore.
- Clean screen and restore are part of the current MVP execution path, not deferred polish, because the menu bar UI already exposes `Start Session` and `Restore Session`.
- Later work starts only after that flow exists end-to-end: more precise permission messaging, stronger persistence, and UI polish.

### Menu Bar Behavior

- `MenuBarExtra(.window)` was dropped because its auxiliary scene was failing at runtime on click.
- `MenuBarExtra(.menu)` was not kept because it removed the compact graphical panel needed for the MVP flow.
- The current menu bar implementation uses `NSStatusItem` plus `NSPopover` to keep the compact graphical UI with predictable click behavior.
- The popover content width is kept smaller than the declared popover width so the panel does not overflow the right edge of the screen.
- The popover is intentionally compact and split into three short zones: `Preset`, `Plan` or `Session`, and `Actions`.
- Secondary copy was reduced on purpose so the session state is readable at a glance.
- `Settings...` closes the popover first, then opens a dedicated settings window, because relying on the default SwiftUI settings action was not reliable enough in a background-only menu bar app.
- Added an explicit empty state instead of showing an empty picker.
- Removed built-in demo presets from production startup.
- `Start Session` is only shown when a preset is selectable.
- `Restore Session` remains visible but disabled while no session is active.
- Preset editing stays lightweight and is presented from the graphical menu bar flow rather than a separate heavy preferences-style surface.

### Hotkey Strategy

- Hotkeys are handled by one small dedicated `HotkeyService`.
- Only two configurable shortcuts are in scope: `Start Session` and `Restore Session`.
- Shortcut capture lives in `Settings`, not in a separate editor surface.
- Shortcut storage stays local via `UserDefaults`.
- The service allows set, change, and clear for both shortcuts.
- Only the obvious local conflict is blocked: `Start Session` and `Restore Session` cannot share the same shortcut.
- No broader global shortcut management is attempted in this pass.
- Hotkeys trigger the same start and restore entry points as the popover buttons, so there is no parallel session logic.
- If no preset is selectable, the Start shortcut fails cleanly through the same session messaging path.
- If no session is active, the Restore shortcut does nothing destructive and leaves the app in a safe state.

### Session Behavior

- Session flow stays intentionally small: `inactive -> active -> restored`.
- `SessionRunner` keeps only one active snapshot at a time.
- Restore remains best effort only and does not promise a full system restore.
- The menu bar now exposes explicit `Inactive`, `Active`, and `Restored` states.
- Preset selection and editing are locked while a session is active to avoid ambiguous state changes.
- A second start request is ignored while another session is already active.
- The active UI switches from preset intent to snapshot tracking so restore scope stays explicit.
- Outside a session, the menu summarizes what the selected preset intends to do. During a session, it summarizes only the actions actually applied and tracked.

### Visibility Strategy

- Visibility management is handled by a small dedicated `AppVisibilityService`.
- Only `regular` macOS apps are candidates for hiding.
- `MeetingMode` itself is always excluded from hiding.
- Apps that belong to the active preset stay visible.
- Everything else is only hidden in best effort.
- If an app cannot be hidden, Meeting Mode keeps going and reports the limit in session messaging instead of pretending the hide succeeded.
- Real-machine probing on Safari and Notes showed that hide requests can complete only after control returns to the main event loop, so hidden apps are confirmed after a short deferred phase instead of being snapshotted immediately in the same blocking call.
- Restore only targets apps that were actually confirmed hidden after that deferred phase.
- Real-machine probing also showed that unhide / activate requests can succeed only after the restore call yields back to the event loop, so restore visibility is confirmed asynchronously instead of being judged too early in the same blocking call.
- If a tracked app remains hidden after that deferred restore confirmation, Meeting Mode tries a simple targeted `openApplication` fallback on that same bundle. This is still not advanced window restoration.
- This deferred confirmation strategy is now also validated in the real menu bar flow with `Safari` and `Notes`, not only in an isolated probe.

### Session Snapshot

- `SessionSnapshot` stores only minimal restore-oriented data: preset identity, started time, launched apps, actually hidden apps, tracked URLs, tracked files, and clean screen state.
- The snapshot is meant to capture only changes triggered by Meeting Mode, not system state outside the app.
- URLs and local files are recorded in the snapshot only when their opening actually succeeds.
- The snapshot also keeps the bundle identifiers of apps that were not already running before the session, so restore can ask only those apps to quit.
- The snapshot also keeps only the exact app instances that were actually hidden with success, keyed by process identifier with bundle identifier fallback for older data.
- The snapshot is not a promise of perfect restore; it is only a best-effort ledger of Meeting Mode actions.

### Opening Strategy

- Opening stays on native macOS APIs only: `NSWorkspace` for apps, URLs, and local files.
- App lookup stays simple on purpose: Meeting Mode resolves app names in standard application directories instead of adding a more complex discovery layer.
- Invalid app names, malformed URLs, and missing file paths do not block the session; they only increase a failure count shown in the session state.
- Opening URLs and files does not imply that Meeting Mode can later close or fully restore them.

### Overlay Strategy

- Clean screen uses one borderless `NSWindow` only, created from `OverlayService`.
- The overlay is constrained to the main screen `visibleFrame` so the menu bar remains accessible for restore.
- The overlay stays visually simple: one SwiftUI view, no multi-screen support, no complex animation, no advanced window choreography.
- The overlay is explicitly shown without activating the menu bar app, so `Start Session` produces a visible effect without intentionally changing the active app.
- The overlay is independent from any specific app. It is not an exception system where some apps are expected to stay above it through fragile window-level behavior.
- The visible session behavior should come mainly from app visibility rules: preset apps stay accessible because they are kept visible, and non-preset apps are hidden in best effort.
- The overlay is intentionally kept below regular app windows so it behaves as a clean visual background, not as a global blocker that needs per-app exceptions.
- Explicit `NSApplication.activate` calls were removed from the overlay path to avoid unwanted app activation side effects during session start.
- If the overlay cannot be created, the session still starts and reports `clean screen unavailable` instead of failing hard.

### Permissions Messaging

- `PermissionService` does not fake `granted` or `pending` states.
- Current permission UI says only that permissions are not checked or requested yet.
- Settings copy avoids implying that a system permission is already required when it is not.

### Local Data Source

- `PresetStore` now reads presets from a simple local JSON file in Application Support.
- If local preset storage is missing, the app seeds one functional `Quick Test` preset for end-to-end testing.
- `Quick Test` now uses `Calculator` instead of `TextEdit` so the default test flow stays visually deterministic and does not open a document chooser.
- Legacy local `Quick Test` data that still points to `TextEdit` is migrated automatically when it still matches the original seed shape.
- If local preset storage exists but cannot be decoded, the app falls back to an empty list rather than silently reseeding.
- If local preset storage exists and contains `[]`, the app keeps the empty state.
- The runtime seed remains intentionally minimal: one default preset only, with additional presets created by the user.
- The selected preset is stored separately in a tiny local preference so relaunches restore the user's last valid selection.
- If the previously selected preset no longer exists, selection falls back to the first available preset or to `nil`.
- Preview data stays local to SwiftUI previews and is not used by the app at runtime.

### Restore Strategy

- Restore is intentionally narrow and strictly limited to changes Meeting Mode triggered during the current session.
- Restore hides the clean screen overlay when the session had shown it.
- Restore re-shows only the apps that Meeting Mode actually hid during the current session.
- Restore targets those hidden apps by exact tracked process first, then falls back to bundle identifier matching only for older snapshots.
- Restore now sends unhide / activate requests first, then confirms the actual visible state after a short delay, because the runtime visibility change is not reliably observable inside the same synchronous call on this machine.
- If a tracked app still remains hidden after that delayed confirmation, restore retries through a targeted `openApplication` call on that app bundle only.
- Restore closes apps launched by the session before re-showing hidden apps, so the launched app does not immediately retake focus after the restore.
- Restore does not attempt to reconstruct pre-session window minimization or Space placement. It only tries to make tracked hidden apps visible again.
- Restore first sends a polite quit to apps launched by Meeting Mode during the session, then falls back to force quit if they remain open.
- Apps that were already running before the session are never included in the quit list.
- A polite quit request is not treated as proof that an app really closed. The UI now distinguishes between a confirmed close and an app that may still be open.
- The stronger fallback exists only for apps launched by the current session, not for apps that were already open before it.
- URLs and local files are opened in a simple way, but v1 restore does not attempt to close them.
- Restore still remains limited in scope and is not a promise of full system rollback.
- The post-restore UI keeps the last restore result visible, and while app visibility is still being confirmed it explicitly says `checking hidden apps` rather than presenting a clean success too early.
- Runtime validation is now split clearly in the docs: app visibility restore is validated on the current machine, while polite quit for document-based apps remains a separate best-effort topic.

### Preset Editing

- Preset creation and editing live in a lightweight SwiftUI sheet from the menu bar content.
- The editor is intentionally split into `Basics`, `What starts`, and `Checklist` so identity, start actions, and preparation steps are not mixed together.
- The validation rule is surfaced at the top of the sheet: a preset needs at least one app, link, file, or clean screen to be startable.
- Apps are no longer entered as free text. The sheet now uses `Add App…` with `NSOpenPanel`, then displays the selected apps as a removable list.
- Editing stays text-based only where it is still the smallest reasonable UI: links, local file paths, and checklist items.
- A preset must contain at least one startable action to be saved: app, URL, file, or clean screen.
- Checklist-only presets are deliberately blocked for now because checklist execution is not implemented yet.
- Saving rewrites the local JSON file atomically, without adding a heavier persistence layer.
- Preset deletion is intentionally minimal: one confirmation from the popover, then immediate removal with selection fallback.
- App hiding and richer checklist editing stay out of this pass.

### Preset Schema

- `Preset` keeps raw `String` arrays for links and local file paths at this stage.
- Apps are stored as small references with display name, bundle identifier, and bundle path so launch is more reliable than name-only matching.
- The schema remains backward-compatible with previously saved presets that stored apps as raw strings.
- Validation of URLs and local file paths is deferred to the future opening step, not the editor.

### Architecture

- Kept a flat, explicit structure: `Models`, `Services`, `Views`, `Utilities`, `Resources`, `docs`.
- Services are stubs with narrow responsibilities.
- No persistence, no third-party dependencies, no architectural framework.

### Deferred Decisions

- Real permission acquisition.
- App sandbox and distribution tradeoffs once automation is implemented.
- Local persistence format.
- Whether a pure SwiftUI menu bar implementation is worth revisiting later if the runtime behavior becomes reliable enough.
