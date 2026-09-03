import Foundation

/// Frozen state of the Dock at a moment in time.
///
/// Used both for reading the current Dock and for representing the
/// target state a profile wants to switch to. `capturedAt` lets the UI
/// tell backups apart and lets the swapper detect "Dock changed since
/// last snapshot" scenarios.
public struct DockSnapshot: Codable, Equatable, Hashable, Sendable {
    public let apps: [DockItem]
    public let others: [DockItem]
    public let capturedAt: Date

    public init(apps: [DockItem], others: [DockItem], capturedAt: Date = Date()) {
        self.apps = apps
        self.others = others
        self.capturedAt = capturedAt
    }

    /// Empty snapshot — useful as a default state and in tests.
    public static let empty = DockSnapshot(apps: [], others: [])

    /// All items in the order the Dock renders them: apps first, then
    /// the `persistent-others` section.
    public var allItems: [DockItem] {
        apps + others
    }
}
