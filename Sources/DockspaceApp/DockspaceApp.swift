import DockspaceCore
import DockspaceStorage
import SwiftUI

/// Entry point of the Dockspace menu bar app.
///
/// Builds a single `AppState` and injects it into the SwiftUI
/// environment. All menu bar items and editor windows read from the
/// same observable.
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
    // on @Environment(AppState.self), @State bindings, and
    // .sheet presentations — none of which work with the .menu
    // style (which flattens the body into NSMenuItems and only
    // honors target/action).
    .menuBarExtraStyle(.window)
  }
}
