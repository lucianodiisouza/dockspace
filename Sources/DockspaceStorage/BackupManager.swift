import DockspaceCore
import Foundation

/// Writes timestamped copies of the current Dock plist into the
/// `backups/` subdirectory of Dockspace's Application Support folder.
///
/// The intent is to let users roll back if a profile swap goes wrong.
/// Backups are plain plist files named with an ISO-8601 timestamp.
public struct BackupManager {
  public let directory: URL
  public let dockPlistURL: URL
  public let timestampFormatter: ISO8601DateFormatter

  public init(
    directory: URL = try! StoragePath.backupsDirectory(),
    dockPlistURL: URL = DockPlistPath.userDockPlistURL()
  ) {
    self.directory = directory
    self.dockPlistURL = dockPlistURL
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime]
    self.timestampFormatter = formatter
  }

  /// Copies the current Dock plist to a timestamped file inside the
  /// backups directory. Returns the URL of the created file. Throws
  /// if the plist is missing or the copy fails.
  @discardableResult
  public func snapshot() throws -> URL {
    guard FileManager.default.fileExists(atPath: dockPlistURL.path) else {
      throw DockError.plistNotFound(dockPlistURL)
    }

    let stamp = timestampFormatter.string(from: Date())
      .replacingOccurrences(of: ":", with: "-")
    let target = directory.appendingPathComponent("dock-\(stamp).plist")

    do {
      try FileManager.default.copyItem(at: dockPlistURL, to: target)
    } catch {
      throw DockError.plistWriteFailed(target, underlying: error.localizedDescription)
    }
    return target
  }

  /// Lists all backup files in chronological order (oldest first).
  public func listBackups() throws -> [URL] {
    let contents = try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: [.creationDateKey]
    )
    return
      contents
      .filter { $0.pathExtension == "plist" && $0.lastPathComponent.hasPrefix("dock-") }
      .sorted { lhs, rhs in
        let l = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
        let r = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
        return l < r
      }
  }
}
