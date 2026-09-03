# Dockspace

> A different Dock for whatever you're doing.

Dockspace is a tiny macOS menu bar app that saves the apps and spacers in your Dock, and lets you switch the whole setup in one click. 100% local, no account, no analytics.

Inspired by [Dockset](https://dockset.app/) — built as an open-source alternative.

## Features

- ♾️ Unlimited named Dock profiles (Work, Personal, Gaming, ...)
- 🎨 Each profile gets a name and color
- 🔄 One-click switching via menu bar
- 💾 Changes auto-save
- 🔒 Local-only — no cloud, no telemetry, no account
- ⌨️ Optional global hotkeys per profile (planned for v0.2)
- 🧘 macOS Focus Mode integration (planned for v0.2)

## Requirements

- macOS 14 Sonoma or later
- Xcode 15+ / Swift 5.9+ (for building from source)

## Build & Run

### From terminal (fast iteration)

```bash
swift run Dockspace
```

Opens a SwiftUI menu bar app. May show a Dock icon in dev mode (release builds hide it).

### As a proper `.app` bundle (recommended for daily use)

The app needs a real `.app` bundle with `Info.plist` (`LSUIElement=YES` to hide from Dock, entitlements, etc.). Generate it via the bundled script:

```bash
./Scripts/build-app.sh
open ./build/Dockspace.app
```

### Tests

```bash
swift test
```

## Project structure

```
dockspace/
├── Package.swift              # SPM manifest
├── Sources/
│   ├── DockspaceApp/          # SwiftUI MenuBarExtra + windows (UI)
│   ├── DockspaceCore/         # pure Swift: plist reader/writer, swapper
│   └── DockspaceStorage/      # profile persistence (JSON)
├── Tests/
│   └── DockspaceCoreTests/    # plist roundtrip, swapper logic
├── Scripts/
│   └── build-app.sh           # builds .app bundle from swift build output
└── docs/                      # design docs, ADRs
```

## How it works (the dirty truth)

macOS doesn't expose a public API for editing the Dock. Dockspace reads and writes `~/Library/Preferences/com.apple.dock.plist` directly, then signals `cfprefsd` and `Dock` to reload. This is the same technique used by every Mac admin tool (`dockutil`, `docklib`, etc.) for the last 15+ years. The only side effect: minimized windows come back to normal on switch (unavoidable with `killall Dock`).

## Status

🚧 Pre-alpha v0.2. The first two slices are in place:

**Core (v0.1)**
- ✅ Read & write the live `com.apple.dock.plist`
- ✅ Swap the Dock to a saved snapshot (with `NoOpDockReloader` for tests)
- ✅ Profile CRUD with JSON persistence in `~/Library/Application Support/Dockspace/`
- ✅ Timestamped backups before every swap
- ✅ Menu bar popover with profile list, switch, and active checkmark
- ✅ Profile editor sheet with rename, recolor, item list, reorder, add app, add spacer

**v0.2**
- ✅ Global hotkeys per profile (⌘⌥⇧⌃ + key, recorded from the editor)
- ✅ Focus Mode auto-switch (polls `INFocusStatusCenter`)
- ✅ Change detection — diff between expected and current Dock before swap
- ✅ Settings sheet (launch at login via `SMAppService`)
- ✅ Quit menu item
- ✅ CI on macOS-14 (build + test + swift-format lint)

Still TODO before a public release: signed/notarized DMG, Homebrew Cask, icon assets, public website. See `AGENTS.md` for the full roadmap.

## License

MIT — see [LICENSE](./LICENSE).
