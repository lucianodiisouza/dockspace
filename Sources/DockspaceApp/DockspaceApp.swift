import SwiftUI
import DockspaceCore
import DockspaceStorage

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
            self._state = State(initialValue: AppState(
                store: store,
                swapper: swapper,
                backup: backup,
                hotkeys: hotkeys
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
        .menuBarExtraStyle(.menu)
    }
}
