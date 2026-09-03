import SwiftUI

/// Entry point of the Dockspace menu bar app.
///
/// Renders a `MenuBarExtra` with the list of profiles. The actual profile
/// editing UI lives in separate views and is opened from the menu bar.
@main
struct DockspaceApp: App {
    var body: some Scene {
        MenuBarExtra {
            // Placeholder content — replaced in Phase 3 (MVP UI).
            Text("Dockspace — bootstrap")
                .padding()
        } label: {
            Image(systemName: "dock.rectangle")
        }
        .menuBarExtraStyle(.menu)
    }
}
