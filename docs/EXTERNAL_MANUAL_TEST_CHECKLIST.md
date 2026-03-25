# External Manual Test Checklist

Use this checklist to validate the current Release `.app` outside Xcode.

## 1. Preparation

- Locate the Release artifact at `~/Library/Developer/Xcode/DerivedData/.../Build/Products/Release/MeetingMode.app`.
- Copy `MeetingMode.app` into a normal test folder outside `DerivedData`.
- Launch the copied app from Finder.
- Expect macOS warnings if the app is not yet signed or notarized.

## 2. Basic Launch

- The app launches without crashing.
- The app name appears as `Meeting Mode`.
- The app icon looks correct in Finder and in the running app.
- The menu bar presence is correct and the app stays background-only.

## 3. Preset Editing

- Create a preset.
- Edit a preset.
- Verify the main action wording: `Préparer le Mac` and `Rétablir le Mac`.
- Verify the presentation background choices:
  - `Aucun`
  - `Fond uni`
  - `Image`

## 4. Session Behavior

- Start a session from a preset.
- Verify apps launch as expected.
- Verify a URL opens as expected.
- Verify a local file opens as expected.
- Verify the presentation background behaves as selected.
- Verify unrelated visible apps are hidden, including Finder if macOS allows it.
- Restore the session and check that the app returns to the expected state.

## 5. Restore Expectations

- Restore is strict and best effort.
- Apps launched by Meeting Mode should close.
- Files opened through apps launched by Meeting Mode should disappear when that app closes.
- Browser pages or files in apps that were already running may remain open by design.

## 6. What to Note

- Crash or no crash.
- Anything unexpectedly left visible.
- Wording that feels confusing.
- Permission prompts or system warnings.
- Gatekeeper or opening friction.
- Any mismatch between expected and actual restore behavior.
