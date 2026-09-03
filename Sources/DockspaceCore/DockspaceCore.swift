// DockspaceCore
//
// Pure Swift layer: no UI, no AppKit. Holds:
//   - Models (DockProfile, DockItem, AppInfo, etc.)
//   - DockPlistReader / DockPlistWriter (the heart of the app)
//   - DockSwapper (orchestrates write + cfprefsd notification)
//   - FocusModeMonitor, HotkeyManager (later phases)
//
// Hard rule: this target must never import SwiftUI, AppKit, or anything UI.
// If you find yourself reaching for UI types here, the code belongs in
// DockspaceApp instead.
