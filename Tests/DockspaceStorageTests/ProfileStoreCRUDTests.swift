import XCTest

@testable import DockspaceCore
@testable import DockspaceStorage

final class ProfileStoreCRUDTests: XCTestCase {
  func test_crud_roundtrip_createReadUpdateDelete() throws {
    let url = makeTempURL()
    defer { try? FileManager.default.removeItem(at: url) }

    let store = try ProfileStore(url: url)
    XCTAssertTrue(store.file.profiles.isEmpty)

    // Create.
    let profile = Profile(
      name: "Work",
      color: .blue,
      items: [
        .app(AppEntry(path: "/Applications/Slack.app", displayName: "Slack")),
        .spacer(.small),
      ]
    )
    try store.create(profile)
    XCTAssertEqual(store.file.profiles.count, 1)

    // Read after persistence (re-open from disk).
    let reopened = try ProfileStore(url: url)
    XCTAssertEqual(reopened.file.profiles.count, 1)
    XCTAssertEqual(reopened.file.profiles.first?.name, "Work")
    XCTAssertEqual(reopened.file.profiles.first?.items.count, 2)

    // Update.
    var updated = try XCTUnwrap(reopened.file.profiles.first)
    updated.name = "Work v2"
    updated.items.append(.app(AppEntry(path: "/Applications/Linear.app")))
    try reopened.update(updated)
    XCTAssertEqual(reopened.file.profiles.first?.name, "Work v2")
    XCTAssertEqual(reopened.file.profiles.first?.items.count, 3)

    // Active profile lifecycle.
    try reopened.setActive(id: updated.id)
    let reopenedAgain = try ProfileStore(url: url)
    XCTAssertEqual(reopenedAgain.file.activeProfileId, updated.id)

    // Delete.
    try reopenedAgain.delete(id: updated.id)
    XCTAssertTrue(reopenedAgain.file.profiles.isEmpty)
    XCTAssertNil(
      reopenedAgain.file.activeProfileId,
      "activeProfileId clears when the active profile is deleted")
  }

  func test_create_replacesEmptyNameWithUntitled() throws {
    let url = makeTempURL()
    defer { try? FileManager.default.removeItem(at: url) }

    let store = try ProfileStore(url: url)
    let profile = Profile(name: "   ")
    try store.create(profile)
    XCTAssertEqual(store.file.profiles.first?.name, "Untitled")
  }

  func test_update_throwsWhenProfileIdIsUnknown() throws {
    let url = makeTempURL()
    defer { try? FileManager.default.removeItem(at: url) }

    let store = try ProfileStore(url: url)
    let ghost = Profile(name: "Ghost", items: [])
    XCTAssertThrowsError(try store.update(ghost)) { error in
      guard case DockError.profileNotFound = error else {
        return XCTFail("expected profileNotFound, got \(error)")
      }
    }
  }

  func test_fileExistedOnLoad_isFalseWhenFileIsMissing() throws {
    let url = makeTempURL()
    defer { try? FileManager.default.removeItem(at: url) }

    let store = try ProfileStore(url: url)
    XCTAssertFalse(store.fileExistedOnLoad)
  }

  func test_fileExistedOnLoad_isTrueAfterFirstWrite() throws {
    let url = makeTempURL()
    defer { try? FileManager.default.removeItem(at: url) }

    let first = try ProfileStore(url: url)
    try first.create(Profile(name: "Work"))
    XCTAssertFalse(first.fileExistedOnLoad)

    let reopened = try ProfileStore(url: url)
    XCTAssertTrue(reopened.fileExistedOnLoad)
  }

  private func makeTempURL() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("dockspace-store-\(UUID().uuidString).json")
  }
}
