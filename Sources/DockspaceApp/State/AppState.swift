import Foundation
import SwiftUI
import DockspaceCore
import DockspaceStorage

/// Source of truth for the running app.
///
/// Coordinates the `ProfileStore` (persistence) and the `DockSwapper`
/// (Dock mutation) and exposes them to SwiftUI via `@Observable`. UI
/// views read from `AppState` and call methods to mutate state; they
/// never touch storage or the swapper directly.
@MainActor
@Observable
public final class AppState {
    public private(set) var profiles: [Profile] = []
    public private(set) var activeProfileId: UUID?
    public private(set) var lastError: String?

    private let store: ProfileStore
    private let swapper: DockSwapper
    private let backup: BackupManager
    private let hotkeys: GlobalHotkeyManager

    public init(
        store: ProfileStore,
        swapper: DockSwapper,
        backup: BackupManager,
        hotkeys: GlobalHotkeyManager = GlobalHotkeyManager()
    ) {
        self.store = store
        self.swapper = swapper
        self.backup = backup
        self.hotkeys = hotkeys
        self.profiles = store.file.profiles
        self.activeProfileId = store.file.activeProfileId
        registerHotkeys()
    }

    public var activeProfile: Profile? {
        guard let activeProfileId else { return nil }
        return profiles.first { $0.id == activeProfileId }
    }

    // MARK: - Persistence passthrough

    public func reload() {
        profiles = store.file.profiles
        activeProfileId = store.file.activeProfileId
        registerHotkeys()
    }

    public func createProfile(name: String, color: ProfileColor = .blue) throws -> Profile {
        let created = try store.create(Profile(name: name, color: color))
        reload()
        return created
    }

    public func updateProfile(_ profile: Profile) throws {
        try store.update(profile)
        reload()
    }

    public func deleteProfile(id: UUID) throws {
        try store.delete(id: id)
        reload()
    }

    // MARK: - Dock swap

    /// Switches the live Dock to the given profile. Snapshots the
    /// current Dock first so the user can roll back.
    public func switchTo(profile: Profile) {
        do {
            _ = try backup.snapshot()
            try swapper.swap(to: profile.snapshot())
            try store.setActive(id: profile.id)
            activeProfileId = profile.id
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Hotkey glue

    private func registerHotkeys() {
        let bindings: [UUID: Hotkey] = profiles.reduce(into: [:]) { acc, profile in
            if let hotkey = profile.hotkey {
                acc[profile.id] = hotkey
            }
        }
        hotkeys.setBindings(bindings) { [weak self] profileID in
            Task { @MainActor in
                guard let self,
                      let profile = self.profiles.first(where: { $0.id == profileID })
                else { return }
                self.switchTo(profile: profile)
            }
        }
    }
}
