import DockspaceCore
import DockspaceStorage
import SwiftUI

/// Entry point of the Dockspace menu bar app.
///
/// Defines the menu bar status item (driven imperatively by
/// `MenuBarController` for click-routing reliability) plus the
/// secondary `Window` scenes (profile editor, settings, new-profile
/// sheet) that open via `openWindow(id:)` from the popover content.
@main
struct DockspaceApp: App {
  @State private var state: AppState

  /// Strong reference so the controller — and therefore the status
  /// item and popover — survives the entire app lifetime. SwiftUI
  /// owns this property and will not release it.
  private let menuBarController: MenuBarController

  init() {
    let initialState: AppState
    do {
      initialState = try AppState.live()
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
      initialState = AppState(
        store: store,
        swapper: swapper,
        backup: backup,
        hotkeys: hotkeys,
        focus: focus,
        focusProvider: focusProvider
      )
    }
    self._state = State(initialValue: initialState)
    self.menuBarController = MenuBarController(state: initialState)
  }

  var body: some Scene {
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

/// Stable identifiers for the app's secondary windows. The popover
/// content opens these via `@Environment(\.openWindow)`.
enum AppWindow: String {
  case editor = "dockspace.editor"
  case newProfile = "dockspace.new-profile"
  case settings = "dockspace.settings"
}
