import XCTest
@testable import DockspaceCore

final class DockPlistReaderTests: XCTestCase {
    func test_read_decodesAppsSpacersAndOthersFromFixture() throws {
        let reader = DockPlistReader(url: fixtureURL)
        let snapshot = try reader.read()

        // Two apps in persistent-apps.
        XCTAssertEqual(snapshot.apps.count, 4)
        XCTAssertEqual(snapshot.apps[0], .app(AppEntry(path: "/Applications/Safari.app", displayName: "Safari")))
        XCTAssertEqual(snapshot.apps[1], .app(AppEntry(path: "/Applications/Mail.app", displayName: "Mail")))

        // Then two spacers in order: legacy, then small.
        XCTAssertEqual(snapshot.apps[2], .spacer(.default))
        XCTAssertEqual(snapshot.apps[3], .spacer(.small))

        // One directory in persistent-others and one URL.
        XCTAssertEqual(snapshot.others.count, 2)
        XCTAssertEqual(snapshot.others[0], .file(FileEntry(path: "/Users/Shared/Documents", displayName: "Documents", isDirectory: true)))
        XCTAssertEqual(snapshot.others[1], .url(URLEntry(url: "https://example.com", displayName: "Example")))
    }

    // MARK: - Helpers

    var fixtureURL: URL {
        // The plist fixture lives in the test bundle's resources.
        let bundle = Bundle(for: type(of: self))
        if let url = bundle.url(forResource: "sample-dock", withExtension: "plist") {
            return url
        }
        // Fallback for `swift test` runs that don't auto-copy resources.
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/sample-dock.plist")
    }
}
