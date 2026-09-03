import Foundation

/// One application pinned on the macOS Dock.
///
/// `path` is the absolute filesystem path to the `.app` bundle (the
/// canonical identifier inside the Dock plist). `bundleIdentifier` and
/// `displayName` are optional cached metadata so the UI can render
/// without re-reading every bundle every time.
public struct AppEntry: Codable, Equatable, Hashable, Sendable {
  public let path: String
  public let bundleIdentifier: String?
  public let displayName: String?

  public init(path: String, bundleIdentifier: String? = nil, displayName: String? = nil) {
    self.path = path
    self.bundleIdentifier = bundleIdentifier
    self.displayName = displayName
  }
}
