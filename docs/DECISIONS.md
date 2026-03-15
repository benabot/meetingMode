# Decisions

## 2026-03-15

### Rebuild Strategy

- Reused the existing Xcode template only as a container.
- Renamed every project path derived from `Sujet : Préparer landing page, pricing et plan de lancement`.
- Removed generated test targets to keep the foundation small and focused.

### App Shape

- macOS only.
- SwiftUI only for the current scaffold.
- `MenuBarExtra` plus `Settings` scene.
- One active session modelled at a time.
- App launches as a background-only menu bar app, with no main window.

### Menu Bar Behavior

- Kept `.menuBarExtraStyle(.window)` for now because the current content behaves like a compact panel, not a plain menu list.
- Added an explicit empty state instead of showing an empty picker.
- Removed built-in demo presets from production startup.
- `Start Session` is only shown when a preset is selectable.
- `Restore Session` remains visible but disabled while no session is active.

### Session Behavior

- Session flow stays intentionally small: `inactive -> active -> inactive`.
- `SessionRunner` keeps only one active snapshot at a time.
- Restore remains best effort only and does not promise a full system restore.

### Permissions Messaging

- `PermissionService` does not fake `granted` or `pending` states.
- Current permission UI says only that permissions are not checked or requested yet.
- Settings copy avoids implying that a system permission is already required when it is not.

### Local Data Source

- `PresetStore` now reads presets from a simple local JSON file in Application Support.
- Missing or unreadable preset data falls back to an empty list rather than shipping demo data.
- Preview data stays local to SwiftUI previews and is not used by the app at runtime.

### Architecture

- Kept a flat, explicit structure: `Models`, `Services`, `Views`, `Utilities`, `Resources`, `docs`.
- Services are stubs with narrow responsibilities.
- No persistence, no third-party dependencies, no architectural framework.

### Deferred Decisions

- Real permission acquisition.
- App sandbox and distribution tradeoffs once automation is implemented.
- Local persistence format.
- Whether `MenuBarExtra` should move from `.window` to `.menu` if the UI becomes a simple action list later.
