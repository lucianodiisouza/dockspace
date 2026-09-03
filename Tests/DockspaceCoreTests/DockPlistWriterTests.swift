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
                .app(AppEntry(path: "/Applications/Linear.app", displayName: "Linear"))
            ],
            others: [
                .file(FileEntry(path: "/Users/me/Downloads", displayName: "Downloads", isDirectory: true)),
                .url(URLEntry(url: "https://example.com", displayName: "Example"))
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

    private func makeTempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("dockspace-writer-\(UUID().uuidString).plist")
    }
}
