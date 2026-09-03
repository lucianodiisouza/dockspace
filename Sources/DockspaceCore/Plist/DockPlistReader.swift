import Foundation

/// Reads `com.apple.dock.plist` and produces a `DockSnapshot`.
///
/// Knows how to interpret the dict structure Apple uses for each tile
/// (file-tile, directory-tile, url-tile, spacer-tile variants) and
/// folds them into the typed `DockItem` enum used by the rest of the
/// app.
public struct DockPlistReader {
  public let url: URL

  public init(url: URL = DockPlistPath.userDockPlistURL()) {
    self.url = url
  }

  /// Reads the plist at `url` and returns a snapshot of its current
  /// state. Throws a typed `DockError` on any failure.
  public func read() throws -> DockSnapshot {
    guard FileManager.default.fileExists(atPath: url.path) else {
      throw DockError.plistNotFound(url)
    }

    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      throw DockError.plistReadFailed(url, underlying: error.localizedDescription)
    }

    let plist: Any
    do {
      plist = try PropertyListSerialization.propertyList(
        from: data,
        options: [],
        format: nil
      )
    } catch {
      throw DockError.plistMalformed(url, underlying: error.localizedDescription)
    }

    guard let root = plist as? [String: Any] else {
      throw DockError.plistMalformed(url, underlying: "root is not a dictionary")
    }

    let apps = try Self.decodeItems(from: root["persistent-apps"], kind: "app")
    let others = try Self.decodeItems(from: root["persistent-others"], kind: "other")

    return DockSnapshot(apps: apps, others: others)
  }

  // MARK: - Decoding helpers

  /// Decodes a `persistent-apps` or `persistent-others` array into
  /// typed `DockItem` values. Each entry in the array is a dict; the
  /// `tile-type` key decides which variant we produce.
  static func decodeItems(from raw: Any?, kind: String) throws -> [DockItem] {
    guard let raw else { return [] }
    guard let array = raw as? [[String: Any]] else {
      throw DockError.plistMalformed(
        DockPlistPath.userDockPlistURL(),
        underlying: "persistent-\(kind) is not an array of dicts"
      )
    }

    var items: [DockItem] = []
    for dict in array {
      items.append(try decodeItem(from: dict))
    }
    return items
  }

  private static func decodeItem(from dict: [String: Any]) throws -> DockItem {
    guard let tileType = dict["tile-type"] as? String else {
      throw DockError.plistMalformed(
        DockPlistPath.userDockPlistURL(),
        underlying: "tile is missing tile-type"
      )
    }

    switch tileType {
    case "file-tile":
      return try decodeApp(from: dict)
    case "directory-tile":
      return try decodeFile(from: dict, isDirectory: true)
    case "url-tile":
      return try decodeURL(from: dict)
    case "spacer-tile":
      return .spacer(.default)
    case "small-spacer-tile":
      return .spacer(.small)
    case "flex-spacer-tile":
      return .spacer(.flex)
    default:
      throw DockError.unsupportedItemType(tileType)
    }
  }

  private static func decodeApp(from dict: [String: Any]) throws -> DockItem {
    let path = try fileURLString(in: dict, context: "app tile")
    let label = label(in: dict)
    return .app(AppEntry(path: path, displayName: label))
  }

  private static func decodeFile(from dict: [String: Any], isDirectory: Bool) throws -> DockItem {
    let path = try fileURLString(in: dict, context: "file tile")
    let label = label(in: dict)
    return .file(FileEntry(path: path, displayName: label, isDirectory: isDirectory))
  }

  private static func decodeURL(from dict: [String: Any]) throws -> DockItem {
    guard
      let tileData = dict["tile-data"] as? [String: Any],
      let urlDict = tileData["url"] as? [String: Any],
      let urlString = urlDict["_CFURLString"] as? String
    else {
      throw DockError.plistMalformed(
        DockPlistPath.userDockPlistURL(),
        underlying: "url tile is missing tile-data.url._CFURLString"
      )
    }
    let label = tileData["label"] as? String
    return .url(URLEntry(url: urlString, displayName: label))
  }

  private static func fileURLString(in dict: [String: Any], context: String) throws -> String {
    guard
      let tileData = dict["tile-data"] as? [String: Any],
      let fileData = tileData["file-data"] as? [String: Any],
      let urlString = fileData["_CFURLString"] as? String
    else {
      throw DockError.plistMalformed(
        DockPlistPath.userDockPlistURL(),
        underlying: "\(context) is missing tile-data.file-data._CFURLString"
      )
    }
    return urlString
  }

  private static func label(in dict: [String: Any]) -> String? {
    guard let tileData = dict["tile-data"] as? [String: Any] else {
      return nil
    }
    return tileData["file-label"] as? String
  }
}
