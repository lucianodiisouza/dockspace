import DockspaceCore
import DockspaceStorage
import SwiftUI

/// Entry point of the Dockspace menu bar app.
///
/// Defines the `MenuBarExtra` popover plus three secondary `Window`
/// scenes (profile editor, settings, new-profile sheet) that open via
/// `openWindow(id:)` from the popover. Sheets inside a menu bar popover
/// are unreliable — the popover typically closes before the sheet can
/// attach, and macOS does not always give the sheet a parent window.
/// Real `Window` scenes are stable.
@main
struct DockspaceApp: App {
  @State private var state: AppState

  init() {
    do {
      self._state = State(initialValue: try AppState.live())
    } catch {
      // If we cannot build the live state (e.g. Application
      // Support is unwritable) we fall back to an empty state so
      // the menu bar still appears and can show the error.
      let store = try! ProfileStore(url: URL(fileURLWithPath: "/dev/null"))
      let swapper = DockSwapper.live()
      let backup = BackupManager(directory: URL(fileURLWithPath: "/dev/null"))
      let hotkeys = GlobalHotkeyManager()
      let focusProvider = SystemFocusStatusProvider()
      let focus = FocusModeMonitor(provider: focusProvider)
      self._state = State(
        initialValue: AppState(
          store: store,
          swapper: swapper,
          backup: backup,
          hotkeys: hotkeys,
          focus: focus,
          focusProvider: focusProvider
        ))
    }
  }

  var body: some Scene {
    MenuBarExtra {
      MenuBarContentView()
        .environment(state)
    } label: {
      Image(systemName: "dock.rectangle")
    }
    // `.window` renders a real SwiftUI popover panel rather than a
    // native NSMenu. We need this because the menu content depends
    // on @Environment(AppState.self), @State bindings, and open
    // window actions — none of which work reliably with the .menu
    // style (which flattens the body into NSMenuItems).
    .menuBarExtraStyle(.window)

    Window("Dockspace", id: AppWindow.editor.rawValue) {
      ProfileEditorView()
        .environment(state)
        .frame(minWidth: 640, minHeight: 420)
    }
    .windowResizability(.contentMinSize)
    .defaultSize(width: 720, height: 480)

    Window("New profile", id: AppWindow.newProfile.rawValue) {
      NewProfileSheet()
        .environment(state)
        .frame(width: 380, height: 280)
    }
    .windowResizability(.contentSize)
    .defaultSize(width: 380, height: 280)

    Window("Dockspace Settings", id: AppWindow.settings.rawValue) {
      SettingsView()
        .frame(width: 420, height: 320)
    }
    .windowResizability(.contentSize)
    .defaultSize(width: 420, height: 320)
  }
}

/// Stable identifiers for the app's secondary windows. The menu bar
/// popover opens these via `@Environment(\.openWindow)`.
enum AppWindow: String {
  case editor = "dockspace.editor"
  case newProfile = "dockspace.new-profile"
  case settings = "dockspace.settings"
}
