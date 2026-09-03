import Foundation
import ServiceManagement

/// User-toggleable app preferences. Currently just "launch at login";
/// new toggles can be added without breaking the on-disk format
/// because the JSON is a dictionary.
public final class AppPreferences: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "app.dockspace.preferences"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var launchAtLogin: Bool {
        get { defaults.bool(forKey: "\(key).launchAtLogin") }
        set {
            defaults.set(newValue, forKey: "\(key).launchAtLogin")
            applyLaunchAtLogin(newValue)
        }
    }

    /// Reflects the preference in macOS's "Login Items" list. The
    /// service must be registered in the bundle's Info.plist under
    /// `SMAppService` for this to work outside development; in dev
    /// we just log the intent.
    private func applyLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Best-effort: log and move on. The preference is
                // still saved so it can be retried on next launch.
                print("[Dockspace] failed to update login item: \(error)")
            }
        }
    }
}
