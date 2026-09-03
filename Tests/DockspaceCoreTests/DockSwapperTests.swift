import XCTest

@testable import DockspaceCore

final class DockSwapperTests: XCTestCase {
  func test_snapshot_returnsCurrentStateFromReader() throws {
    let tempURL = makeTempPlist()
    defer { try? FileManager.default.removeItem(at: tempURL) }

    // Seed the file with a known snapshot.
    let seed = DockSnapshot(
      apps: [.app(AppEntry(path: "/Applications/Safari.app", displayName: "Safari"))],
      others: []
    )
    try DockPlistWriter(url: tempURL).write(snapshot: seed)

    let swapper = DockSwapper(
      reader: DockPlistReader(url: tempURL),
      writer: DockPlistWriter(url: tempURL),
      reloader: NoOpDockReloader()
    )

    let snapshot = try swapper.snapshot()
    // Compare items only — capturedAt uses Date() with sub-ms
    // precision so two snapshots taken back-to-back compare unequal
    // even when their content is identical.
    XCTAssertEqual(snapshot.apps, seed.apps)
    XCTAssertEqual(snapshot.others, seed.others)
  }

  func test_swap_writesNewStateAndInvokesReloader() throws {
    let tempURL = makeTempPlist()
    defer { try? FileManager.default.removeItem(at: tempURL) }

    // Start with one app, swap to a different one.
    let initial = DockSnapshot(apps: [.app(AppEntry(path: "/Applications/Notes.app"))], others: [])
    try DockPlistWriter(url: tempURL).write(snapshot: initial)

    let reloader = NoOpDockReloader()
    let swapper = DockSwapper(
      reader: DockPlistReader(url: tempURL),
      writer: DockPlistWriter(url: tempURL),
      reloader: reloader
    )

    let target = DockSnapshot(
      apps: [
        .app(AppEntry(path: "/Applications/Slack.app", displayName: "Slack")),
        .spacer(.small),
        .app(AppEntry(path: "/Applications/Linear.app")),
      ],
      others: []
    )
    try swapper.swap(to: target)

    // Reloader was called exactly once.
    XCTAssertEqual(reloader.callCount, 1)

    // The on-disk state matches the target.
    let onDisk = try DockPlistReader(url: tempURL).read()
    XCTAssertEqual(onDisk.apps, target.apps)
  }

  private func makeTempPlist() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("dockspace-swapper-\(UUID().uuidString).plist")
  }
}
