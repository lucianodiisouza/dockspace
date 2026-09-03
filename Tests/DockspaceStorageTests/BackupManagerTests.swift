import XCTest

@testable import DockspaceCore
@testable import DockspaceStorage

final class BackupManagerTests: XCTestCase {
  func test_snapshot_copiesPlistToTimestampedFileInBackupsDirectory() throws {
    let plistURL = makeTempPlist()
    let backupDir = makeTempDirectory()
    defer {
      try? FileManager.default.removeItem(at: plistURL)
      try? FileManager.default.removeItem(at: backupDir)
    }

    // Seed the source plist.
    let seed = DockSnapshot(apps: [.app(AppEntry(path: "/Applications/Safari.app"))], others: [])
    try DockPlistWriter(url: plistURL).write(snapshot: seed)

    let manager = BackupManager(directory: backupDir, dockPlistURL: plistURL)
    let backupURL = try manager.snapshot()

    XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
    XCTAssertEqual(backupURL.deletingLastPathComponent(), backupDir)
    XCTAssertTrue(backupURL.lastPathComponent.hasPrefix("dock-"))
    XCTAssertEqual(backupURL.pathExtension, "plist")

    // The backup's content matches the source.
    let sourceData = try Data(contentsOf: plistURL)
    let backupData = try Data(contentsOf: backupURL)
    XCTAssertEqual(sourceData, backupData)

    // listBackups includes it.
    let listed = try manager.listBackups()
    XCTAssertEqual(listed.count, 1)
    XCTAssertEqual(listed.first?.lastPathComponent, backupURL.lastPathComponent)
  }

  func test_snapshot_throwsNotFoundWhenPlistMissing() {
    let missingPlist = URL(fileURLWithPath: "/tmp/does-not-exist-\(UUID().uuidString).plist")
    let backupDir = makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: backupDir) }

    let manager = BackupManager(directory: backupDir, dockPlistURL: missingPlist)
    XCTAssertThrowsError(try manager.snapshot()) { error in
      guard case DockError.plistNotFound = error else {
        return XCTFail("expected plistNotFound, got \(error)")
      }
    }
  }

  // MARK: - Helpers

  private func makeTempPlist() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("dockspace-backup-src-\(UUID().uuidString).plist")
  }

  private func makeTempDirectory() -> URL {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("dockspace-backups-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }
}
