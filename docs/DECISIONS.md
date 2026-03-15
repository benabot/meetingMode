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

### Architecture

- Kept a flat, explicit structure: `Models`, `Services`, `Views`, `Utilities`, `Resources`, `docs`.
- Services are stubs with narrow responsibilities.
- No persistence, no third-party dependencies, no architectural framework.

### Deferred Decisions

- Real permission acquisition.
- App sandbox and distribution tradeoffs once automation is implemented.
- Local persistence format.
