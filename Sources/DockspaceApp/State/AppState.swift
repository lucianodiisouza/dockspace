import DockspaceCore
import DockspaceStorage
import Foundation
import SwiftUI
import os

private let appLog = Logger(subsystem: "app.dockspace", category: "app")

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
  private let focus: FocusModeMonitor
  private let focusProvider: FocusStatusProvider

  public init(
    store: ProfileStore,
    swapper: DockSwapper,
    backup: BackupManager,
    hotkeys: GlobalHotkeyManager,
    focus: FocusModeMonitor,
    focusProvider: FocusStatusProvider
  ) {
    self.store = store
    self.swapper = swapper
    self.backup = backup
    self.hotkeys = hotkeys
    self.focus = focus
    self.focusProvider = focusProvider
    self.profiles = store.file.profiles
    self.activeProfileId = store.file.activeProfileId
    appLog.info(
      "AppState init: fileExistedOnLoad=\(store.fileExistedOnLoad, privacy: .public) profiles=\(self.profiles.count, privacy: .public) active=\(self.activeProfileId?.uuidString ?? "nil", privacy: .public)"
    )
    seedFirstProfileIfNeeded()
    registerHotkeys()
    startFocusMonitor()
  }

  public var activeProfile: Profile? {
    guard let activeProfileId else { return nil }
    return profiles.first { $0.id == activeProfileId }
  }

  /// On a true first launch (the on-disk file did not exist yet) we
  /// snapshot whatever is currently in the Dock and save it as a single
  /// "Default" profile, marked active. This way the user starts with a
  /// real fallback they can always switch back to, and creating a new
  /// empty profile never silently nukes their existing dock.
  ///
  /// We only run this when the file did not exist at load time — if the
  /// user has ever opened the app before (even and deleted every
  /// profile), we respect that and start blank.
  private func seedFirstProfileIfNeeded() {
    guard !store.fileExistedOnLoad else {
      appLog.info("seed: skip (file existed on load)")
      return
    }
    guard profiles.isEmpty else {
      appLog.info("seed: skip (profiles already non-empty)")
      return
    }
    let snapshot: DockSnapshot
    do {
      snapshot = try swapper.snapshot()
    } catch {
      appLog.error("seed: snapshot failed: \(error.localizedDescription, privacy: .public)")
      return
    }
    guard !snapshot.allItems.isEmpty else {
      appLog.info("seed: skip (current dock is empty)")
      return
    }
    let seeded = Profile(
      name: "Default",
      color: .blue,
      items: snapshot.allItems
    )
    do {
      try store.create(seeded)
      try store.setActive(id: seeded.id)
      profiles = store.file.profiles
      activeProfileId = seeded.id
      appLog.info(
        "seed: created Default profile with \(seeded.items.count, privacy: .public) items")
    } catch {
      appLog.error("seed: persist failed: \(error.localizedDescription, privacy: .public)")
    }
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
      guard let self else { return }
      Task { @MainActor in
        guard let profile = self.profiles.first(where: { $0.id == profileID })
        else { return }
        self.switchTo(profile: profile)
      }
    }
  }

  // MARK: - Focus Mode glue

  private func startFocusMonitor() {
    focus.start { [weak self] isFocused in
      guard let self else { return }
      Task { @MainActor in
        self.handleFocusChange(isFocused: isFocused)
      }
    }
  }

  private func handleFocusChange(isFocused: Bool) {
    // A profile is "focus-bound" when its `focusModeBinding` is
    // non-nil. We only act on transitions:
    //   - focus turns ON  → activate the first focus-bound profile
    //   - focus turns OFF → activate the most recent non-bound profile
    if isFocused {
      if let bound = profiles.first(where: { $0.focusModeBinding != nil }) {
        switchTo(profile: bound)
      }
    } else {
      if let fallback = profiles.first(where: { $0.focusModeBinding == nil }) {
        switchTo(profile: fallback)
      }
    }
  }
}
