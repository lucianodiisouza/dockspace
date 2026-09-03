import Foundation

/// Resolves where the macOS Dock stores its preferences plist.
///
/// The path is `~/Library/Preferences/com.apple.dock.plist`. Apple has
/// kept this location stable since at least 10.6, so the lookup is hard
/// coded rather than walking system preferences.
public enum DockPlistPath {
  /// Standard location of the per-user Dock plist.
  public static let userDockPlistFileName = "com.apple.dock.plist"

  /// Resolves the full URL to the user Dock plist, expanding `~`.
  public static func userDockPlistURL() -> URL {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return
      home
      .appendingPathComponent("Library", isDirectory: true)
      .appendingPathComponent("Preferences", isDirectory: true)
      .appendingPathComponent(userDockPlistFileName)
  }

  /// Same URL, but as a plain string. Convenient for logging.
  public static func userDockPlistPath() -> String {
    userDockPlistURL().path
  }
}
