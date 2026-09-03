# Dockspace

[![CI](https://github.com/lucianodiisouza/dockspace/actions/workflows/ci.yml/badge.svg)](https://github.com/lucianodiisouza/dockspace/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blueviolet)](https://developer.apple.com/macos/)

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

The project ships a `Makefile` with the common commands. `make help` lists them all.

### As a proper `.app` bundle (recommended for development)

```bash
make dev
```

This is the **right way to test the menu bar UX**. `make dev` builds a release binary, assembles a `.app` bundle with `Info.plist` (including `LSUIElement=YES` so the app hides from the Dock and runs as a proper menu bar accessory), embeds entitlements, ad-hoc codesigns, and opens the result. Without the bundle, `swift run` will spawn the binary as a regular foreground app — the menu bar popover will misbehave because `LSUIElement` is missing.

### From terminal (fast iteration, limited)

```bash
make run
# or
swift run Dockspace
```

Use this only when iterating on pure code changes. The SwiftUI menu bar will be visible but popovers may not behave correctly without `LSUIElement=YES` and the embedded entitlements. When in doubt, run `make dev`.

### Building a bundle manually

```bash
make app
open ./build/Dockspace.app
```

`make app` only builds the bundle, `make dev` builds and opens it.

### Signed + notarized DMG (for distribution)

```bash
export DOCKSPACE_SIGN_IDENTITY="Developer ID Application: Luciano dii Souza (TEAMID)"
export DOCKSPACE_NOTARY_PROFILE="dockspace-notary"   # see xcrun notarytool store-credentials
make release
open ./build/release/Dockspace-0.2.0.dmg
```

The release script calls `Scripts/build-app.sh`, signs the bundle with `--options runtime`, submits it to Apple's notary service via `xcrun notarytool`, staples the ticket back onto the binary, and produces a `Dockspace-0.2.0.dmg` ready for GitHub Releases / Homebrew Cask.

### Tests

```bash
make test
# or
swift test
```

### Regenerate the placeholder icons

```bash
make icon
```

Renders 10 sizes of a coral placeholder icon into `Resources/Assets.xcassets/AppIcon.appiconset/`. Replace the generated PNGs with a real design when you have one.

## Project structure

```
dockspace/
├── Package.swift              # SPM manifest
├── Makefile                   # make build / test / app / release
├── Resources/                 # Assets, entitlements, future localized strings
├── Sources/
│   ├── DockspaceApp/          # SwiftUI MenuBarExtra + windows (UI)
│   ├── DockspaceCore/         # pure Swift: plist reader/writer, swapper, hotkey, focus
│   └── DockspaceStorage/      # profile persistence (JSON) + backups
├── Tests/
│   ├── DockspaceCoreTests/    # plist roundtrip, swapper, hotkey, focus, change detection
│   └── DockspaceStorageTests/ # ProfileStore, BackupManager
├── Scripts/
│   ├── build-app.sh           # builds .app bundle from swift build output
│   ├── release.sh             # signs + notarizes + packages DMG
│   └── generate-icon.py       # regenerates the placeholder app icons
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
