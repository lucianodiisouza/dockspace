import Foundation

/// Errors thrown by the DockspaceCore layer.
///
/// All messages start with a verb (Failed/Cannot/Missing) so logs read
/// naturally when wrapped in `localizedDescription`.
public enum DockError: LocalizedError, Equatable {
  case plistNotFound(URL)
  case plistReadFailed(URL, underlying: String)
  case plistMalformed(URL, underlying: String)
  case plistWriteFailed(URL, underlying: String)
  case unsupportedItemType(String)
  case dockReloadFailed(String)
  case fileNotFound(String)
  case profileNotFound(String)

  public var errorDescription: String? {
    switch self {
    case .plistNotFound(let url):
      return "Failed to locate dock plist at \(url.path)"
    case .plistReadFailed(let url, let reason):
      return "Failed to read dock plist at \(url.path) because \(reason)"
    case .plistMalformed(let url, let reason):
      return "Failed to decode dock plist at \(url.path) because \(reason)"
    case .plistWriteFailed(let url, let reason):
      return "Failed to write dock plist at \(url.path) because \(reason)"
    case .unsupportedItemType(let type):
      return "Failed to handle dock item of type \(type) because it is not supported"
    case .dockReloadFailed(let reason):
      return "Failed to reload dock because \(reason)"
    case .fileNotFound(let path):
      return "Failed to find file at \(path)"
    case .profileNotFound(let id):
      return "Failed to find profile with id \(id)"
    }
  }
}
