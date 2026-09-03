import Foundation

/// A single entry on the macOS Dock, in the order it appears.
///
/// Maps 1:1 to the dict structure the Dock plist stores under
/// `persistent-apps` (for `.app`) and `persistent-others` (for
/// `.spacer`, `.file`, `.url`).
public enum DockItem: Codable, Equatable, Hashable, Sendable {
  case app(AppEntry)
  case spacer(SpacerVariant)
  case file(FileEntry)
  case url(URLEntry)

  // MARK: - Convenience accessors

  public var app: AppEntry? {
    if case .app(let entry) = self { return entry }
    return nil
  }

  public var spacer: SpacerVariant? {
    if case .spacer(let variant) = self { return variant }
    return nil
  }

  public var file: FileEntry? {
    if case .file(let entry) = self { return entry }
    return nil
  }

  public var url: URLEntry? {
    if case .url(let entry) = self { return entry }
    return nil
  }

  /// Human-readable label used by the UI to identify this item.
  public var displayName: String {
    switch self {
    case .app(let entry):
      return entry.displayName ?? (entry.path as NSString).lastPathComponent
    case .spacer(let variant):
      switch variant {
      case .small: return "Small spacer"
      case .flex: return "Flex spacer"
      case .default: return "Spacer"
      }
    case .file(let entry):
      return entry.displayName ?? (entry.path as NSString).lastPathComponent
    case .url(let entry):
      return entry.displayName ?? entry.url
    }
  }
}
