import SwiftUI
import DockspaceCore
import DockspaceStorage

extension AppState {
    /// Builds the production `AppState` pointing at the live Dock plist
    /// and the user's Application Support folder. Throws if the
    /// Application Support directory cannot be created (rare — usually
    /// only on locked-down systems).
    public static func live() throws -> AppState {
        let profilesURL = try StoragePath.profilesFileURL()
        let backupsDir = try StoragePath.backupsDirectory()
        let store = try ProfileStore(url: profilesURL)
        let swapper = DockSwapper.live()
        let backup = BackupManager(directory: backupsDir)
        let hotkeys = GlobalHotkeyManager()
        return AppState(store: store, swapper: swapper, backup: backup, hotkeys: hotkeys)
    }
}
