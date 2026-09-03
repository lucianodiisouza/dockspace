import XCTest
@testable import DockspaceCore

final class DockChangeDetectorTests: XCTestCase {
    private let detector = DockChangeDetector()

    func test_diff_identicalSnapshotsReportNoChange() {
        let snapshot = DockSnapshot(
            apps: [.app(AppEntry(path: "/Applications/Slack.app"))],
            others: []
        )
        let report = detector.diff(previous: snapshot, current: snapshot)
        XCTAssertEqual(report, .noChange)
        XCTAssertFalse(report.hasChanges)
    }

    func test_diff_flagsItemsAddedByUser() {
        let previous = DockSnapshot(
            apps: [.app(AppEntry(path: "/Applications/Slack.app"))],
            others: []
        )
        let current = DockSnapshot(
            apps: [
                .app(AppEntry(path: "/Applications/Slack.app")),
                .app(AppEntry(path: "/Applications/Mail.app"))
            ],
            others: []
        )
        let report = detector.diff(previous: previous, current: current)
        XCTAssertEqual(report.added.count, 1)
        XCTAssertEqual(report.added.first?.app?.path, "/Applications/Mail.app")
        XCTAssertTrue(report.removed.isEmpty)
    }

    func test_diff_flagsItemsRemovedByUser() {
        let previous = DockSnapshot(
            apps: [
                .app(AppEntry(path: "/Applications/Slack.app")),
                .app(AppEntry(path: "/Applications/Mail.app"))
            ],
            others: []
        )
        let current = DockSnapshot(
            apps: [.app(AppEntry(path: "/Applications/Slack.app"))],
            others: []
        )
        let report = detector.diff(previous: previous, current: current)
        XCTAssertEqual(report.removed.count, 1)
        XCTAssertEqual(report.removed.first?.app?.path, "/Applications/Mail.app")
        XCTAssertTrue(report.added.isEmpty)
    }

    func test_diff_flagsReorderingWhenSetsAreEqual() {
        let previous = DockSnapshot(
            apps: [
                .app(AppEntry(path: "/Applications/Slack.app")),
                .app(AppEntry(path: "/Applications/Mail.app"))
            ],
            others: []
        )
        let current = DockSnapshot(
            apps: [
                .app(AppEntry(path: "/Applications/Mail.app")),
                .app(AppEntry(path: "/Applications/Slack.app"))
            ],
            others: []
        )
        let report = detector.diff(previous: previous, current: current)
        XCTAssertTrue(report.reordered)
        XCTAssertTrue(report.added.isEmpty)
        XCTAssertTrue(report.removed.isEmpty)
    }
}
