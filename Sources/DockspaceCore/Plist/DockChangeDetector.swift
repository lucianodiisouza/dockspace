import Foundation

/// Compares two `DockSnapshot`s and reports the differences. Used to
/// detect when the user has edited the Dock manually between swaps
/// (e.g. dragged an app in or out) so the app can warn them before
/// overwriting the changes.
public struct DockChangeDetector {
    public init() {}

    public struct Report: Equatable, Sendable {
        public let added: [DockItem]
        public let removed: [DockItem]
        public let reordered: Bool

        public var hasChanges: Bool {
            !added.isEmpty || !removed.isEmpty || reordered
        }

        public static let noChange = Report(added: [], removed: [], reordered: false)
    }

    /// Compares the two snapshots. `previous` is what we expected to
    /// see on disk; `current` is what we just read.
    public func diff(previous: DockSnapshot, current: DockSnapshot) -> Report {
        let previousSet = Set(previous.apps)
        let currentSet = Set(current.apps)

        let added = current.apps.filter { !previousSet.contains($0) }
        let removed = previous.apps.filter { !currentSet.contains($0) }
        let reordered = previous.apps != current.apps
            && Set(previous.apps) == Set(current.apps)

        return Report(added: added, removed: removed, reordered: reordered)
    }
}
