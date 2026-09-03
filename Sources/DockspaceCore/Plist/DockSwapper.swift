import Foundation

/// Coordinates the read → write → reload sequence that changes the
/// Dock to a new profile.
///
/// Holds a reader, a writer, and a reloader. Splits responsibilities so
/// each step is independently testable and the production code path
/// (reader + writer + system reloader) can be assembled in one place.
public struct DockSwapper {
    public let reader: DockPlistReader
    public let writer: DockPlistWriter
    public let reloader: DockReloader

    public init(
        reader: DockPlistReader,
        writer: DockPlistWriter,
        reloader: DockReloader
    ) {
        self.reader = reader
        self.writer = writer
        self.reloader = reloader
    }

    /// Convenience initializer targeting the live Dock plist with the
    /// system reloader. Use for production. Tests should pass an
    /// explicit reloader.
    public static func live() -> DockSwapper {
        DockSwapper(
            reader: DockPlistReader(),
            writer: DockPlistWriter(),
            reloader: SystemDockReloader()
        )
    }

    /// Reads the current state of the Dock.
    public func snapshot() throws -> DockSnapshot {
        try reader.read()
    }

    /// Replaces the Dock state with `newState` and signals the Dock
    /// to reload. The order matters: write first, reload second.
    public func swap(to newState: DockSnapshot) throws {
        try writer.write(snapshot: newState)
        try reloader.reload()
    }
}
