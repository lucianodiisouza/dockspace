import XCTest

@testable import DockspaceCore

final class DockPlistRoundtripTests: XCTestCase {
  func test_roundtrip_preservesAppsSpacersFilesAndUrls() throws {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("dockspace-roundtrip-\(UUID().uuidString).plist")
    defer { try? FileManager.default.removeItem(at: tempURL) }

    let original = DockSnapshot(
      apps: [
        .app(AppEntry(path: "/Applications/Slack.app", displayName: "Slack")),
        .spacer(.default),
        .spacer(.small),
        .spacer(.flex),
        .app(AppEntry(path: "/Applications/Linear.app")),
      ],
      others: [
        .file(FileEntry(path: "/Users/me/Downloads", displayName: "Downloads", isDirectory: true)),
        .url(URLEntry(url: "https://example.com", displayName: "Example")),
      ]
    )

    let writer = DockPlistWriter(url: tempURL)
    try writer.write(snapshot: original)

    let reader = DockPlistReader(url: tempURL)
    let restored = try reader.read()

    // Apps: paths and displayNames survive. Spacers come out in the
    // order they went in.
    XCTAssertEqual(restored.apps.count, original.apps.count)
    for (lhs, rhs) in zip(restored.apps, original.apps) {
      XCTAssertEqual(lhs, rhs)
    }

    // Others roundtrip exactly.
    XCTAssertEqual(restored.others, original.others)
  }
}
