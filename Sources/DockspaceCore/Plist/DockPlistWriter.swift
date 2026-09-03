import Foundation

/// Encodes a `DockSnapshot` back into the `com.apple.dock.plist` format.
///
/// Mirrors `DockPlistReader`: it produces the exact dict structure the
/// Dock expects, with a minimal but valid set of keys. Unknown keys from
/// the original plist are not preserved — we treat the plist as a
/// structured output, not a roundtripped document.
public struct DockPlistWriter {
  public let url: URL

  public init(url: URL = DockPlistPath.userDockPlistURL()) {
    self.url = url
  }

  /// Writes the snapshot to `url` as XML. Replaces any existing
  /// content. Throws `DockError.plistWriteFailed` on I/O or encoding
  /// failure.
  public func write(snapshot: DockSnapshot) throws {
    let root: [String: Any] = [
      "persistent-apps": snapshot.apps.map(encodeItem),
      "persistent-others": snapshot.others.map(encodeItem),
    ]

    let data: Data
    do {
      data = try PropertyListSerialization.data(
        fromPropertyList: root,
        format: .xml,
        options: 0
      )
    } catch {
      throw DockError.plistWriteFailed(url, underlying: error.localizedDescription)
    }

    do {
      try data.write(to: url, options: .atomic)
    } catch {
      throw DockError.plistWriteFailed(url, underlying: error.localizedDescription)
    }
  }

  // MARK: - Encoding

  func encodeItem(_ item: DockItem) -> [String: Any] {
    switch item {
    case .app(let entry):
      return encodeApp(entry)
    case .spacer(let variant):
      return ["tile-type": variant.rawValue]
    case .file(let entry):
      return encodeFile(entry)
    case .url(let entry):
      return encodeURL(entry)
    }
  }

  private func encodeApp(_ entry: AppEntry) -> [String: Any] {
    var tileData: [String: Any] = [
      "file-data": encodeFileData(path: entry.path)
    ]
    if let label = entry.displayName {
      tileData["file-label"] = label
    }
    return [
      "tile-data": tileData,
      "tile-type": "file-tile",
    ]
  }

  private func encodeFile(_ entry: FileEntry) -> [String: Any] {
    var tileData: [String: Any] = [
      "file-data": encodeFileData(path: entry.path)
    ]
    if let label = entry.displayName {
      tileData["file-label"] = label
    }
    if entry.isDirectory {
      tileData["file-type"] = 2
    }
    return [
      "tile-data": tileData,
      "tile-type": entry.isDirectory ? "directory-tile" : "file-tile",
    ]
  }

  private func encodeURL(_ entry: URLEntry) -> [String: Any] {
    var tileData: [String: Any] = [
      "url": [
        "_CFURLString": entry.url,
        "_CFURLStringType": 15,
      ]
    ]
    if let label = entry.displayName {
      tileData["label"] = label
    }
    return [
      "tile-data": tileData,
      "tile-type": "url-tile",
    ]
  }

  private func encodeFileData(path: String) -> [String: Any] {
    [
      "_CFURLString": path,
      "_CFURLStringType": 0,
    ]
  }
}
