import XCTest
@testable import DockspaceCore

final class DockPlistReaderErrorTests: XCTestCase {
    func test_read_throwsNotFoundWhenPlistDoesNotExist() {
        let reader = DockPlistReader(url: URL(fileURLWithPath: "/tmp/does-not-exist-\(UUID().uuidString).plist"))
        XCTAssertThrowsError(try reader.read()) { error in
            guard case DockError.plistNotFound = error else {
                return XCTFail("expected plistNotFound, got \(error)")
            }
        }
    }

    func test_read_throwsMalformedOnInvalidData() {
        let tempURL = makeTempPlist(contents: "not a plist at all")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let reader = DockPlistReader(url: tempURL)
        XCTAssertThrowsError(try reader.read()) { error in
            guard case DockError.plistMalformed = error else {
                return XCTFail("expected plistMalformed, got \(error)")
            }
        }
    }

    func test_read_throwsUnsupportedOnUnknownTileType() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0"><dict>
            <key>persistent-apps</key>
            <array>
                <dict>
                    <key>tile-type</key>
                    <string>future-tile-we-do-not-know</string>
                </dict>
            </array>
        </dict></plist>
        """
        let tempURL = makeTempPlist(contents: xml)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let reader = DockPlistReader(url: tempURL)
        XCTAssertThrowsError(try reader.read()) { error in
            guard case DockError.unsupportedItemType(let type) = error else {
                return XCTFail("expected unsupportedItemType, got \(error)")
            }
            XCTAssertEqual(type, "future-tile-we-do-not-know")
        }
    }

    // MARK: - Helpers

    private func makeTempPlist(contents: String) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dockspace-test-\(UUID().uuidString).plist")
        try? contents.data(using: .utf8)?.write(to: url)
        return url
    }
}
