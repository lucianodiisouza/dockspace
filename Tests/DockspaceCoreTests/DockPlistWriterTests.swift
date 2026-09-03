import XCTest

@testable import DockspaceCore

final class DockPlistWriterTests: XCTestCase {
  func test_write_persistsSnapshotAsValidPlistOnDisk() throws {
    let tempURL = makeTempURL()
    defer { try? FileManager.default.removeItem(at: tempURL) }

    let snapshot = DockSnapshot(
      apps: [
        .app(AppEntry(path: "/Applications/Slack.app", displayName: "Slack")),
        .spacer(.small),
        .app(AppEntry(path: "/Applications/Linear.app", displayName: "Linear")),
      ],
      others: [
        .file(FileEntry(path: "/Users/me/Downloads", displayName: "Downloads", isDirectory: true)),
        .url(URLEntry(url: "https://example.com", displayName: "Example")),
      ]
    )

    let writer = DockPlistWriter(url: tempURL)
    try writer.write(snapshot: snapshot)

    // File exists and parses back as a plist dictionary.
    let data = try Data(contentsOf: tempURL)
    let parsed = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    let root = try XCTUnwrap(parsed as? [String: Any])

    // Top-level keys are present.
    XCTAssertNotNil(root["persistent-apps"])
    XCTAssertNotNil(root["persistent-others"])

    // App count and first item path.
    let apps = try XCTUnwrap(root["persistent-apps"] as? [[String: Any]])
    XCTAssertEqual(apps.count, 3)
    let firstAppData = try XCTUnwrap(apps[0]["tile-data"] as? [String: Any])
    let firstAppFileData = try XCTUnwrap(firstAppData["file-data"] as? [String: Any])
    XCTAssertEqual(firstAppFileData["_CFURLString"] as? String, "/Applications/Slack.app")
  }

  func test_write_preservesOrientationAndOtherDockSettings() throws {
    let tempURL = makeTempURL()
    defer { try? FileManager.default.removeItem(at: tempURL) }

    // Seed a plist that already has user preferences the Dock relies
    // on: side orientation, a custom tile size, magnification, and
    // autohide. Also include a `persistent-apps` array we expect to be
    // replaced.
    let seed: [String: Any] = [
      "orientation": "left",
      "tilesize": 48,
      "magnification": true,
      "magsize": 96,
      "autohide": true,
      "show-process-indicators": true,
      "show-recents": false,
      "mouse-over-hilite-stack": true,
      "persistent-apps": [
        [
          "tile-data": [
            "file-data": [
              "_CFURLString": "/Applications/Old.app",
              "_CFURLStringType": 0,
            ]
          ],
          "tile-type": "file-tile",
        ]
      ],
    ]
    let seedData = try PropertyListSerialization.data(
      fromPropertyList: seed, format: .xml, options: 0
    )
    try seedData.write(to: tempURL, options: .atomic)

    // Write a new snapshot with different items.
    let snapshot = DockSnapshot(
      apps: [
        .app(AppEntry(path: "/Applications/Slack.app", displayName: "Slack"))
      ],
      others: []
    )
    let writer = DockPlistWriter(url: tempURL)
    try writer.write(snapshot: snapshot)

    // Read the plist back and verify.
    let data = try Data(contentsOf: tempURL)
    let parsed = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    let root = try XCTUnwrap(parsed as? [String: Any])

    // Dock preferences are still there.
    XCTAssertEqual(root["orientation"] as? String, "left")
    XCTAssertEqual(root["tilesize"] as? Int, 48)
    XCTAssertEqual(root["magnification"] as? Bool, true)
    XCTAssertEqual(root["magsize"] as? Int, 96)
    XCTAssertEqual(root["autohide"] as? Bool, true)
    XCTAssertEqual(root["show-process-indicators"] as? Bool, true)
    XCTAssertEqual(root["show-recents"] as? Bool, false)
    XCTAssertEqual(root["mouse-over-hilite-stack"] as? Bool, true)

    // The persistent-apps array was replaced with the new snapshot.
    let apps = try XCTUnwrap(root["persistent-apps"] as? [[String: Any]])
    XCTAssertEqual(apps.count, 1)
    let firstAppData = try XCTUnwrap(apps[0]["tile-data"] as? [String: Any])
    let firstAppFileData = try XCTUnwrap(firstAppData["file-data"] as? [String: Any])
    XCTAssertEqual(firstAppFileData["_CFURLString"] as? String, "/Applications/Slack.app")
  }

  func test_write_whenFileMissingStartsFromEmptyDict() throws {
    let tempURL = makeTempURL()
    defer { try? FileManager.default.removeItem(at: tempURL) }

    // No file exists yet — writer should still produce a valid plist
    // with just the two tile arrays.
    let snapshot = DockSnapshot(
      apps: [.app(AppEntry(path: "/Applications/Slack.app"))],
      others: []
    )
    let writer = DockPlistWriter(url: tempURL)
    try writer.write(snapshot: snapshot)

    let data = try Data(contentsOf: tempURL)
    let parsed = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    let root = try XCTUnwrap(parsed as? [String: Any])
    XCTAssertNotNil(root["persistent-apps"])
    XCTAssertNotNil(root["persistent-others"])
    XCTAssertEqual(root.count, 2, "no extraneous keys when starting fresh")
  }

  private func makeTempURL() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("dockspace-writer-\(UUID().uuidString).plist")
  }
}
