import Foundation
import DockspaceCore

/// Reads and writes the user profile collection to disk.
///
/// Holds a single `ProfilesFile` envelope in memory and persists it
/// atomically on every mutation. Methods are not thread-safe — call
/// them from a single actor (e.g. `@MainActor AppState`).
public final class ProfileStore {
    public let url: URL

    private(set) public var file: ProfilesFile

    public init(url: URL) throws {
        self.url = url
        if FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.file = try decoder.decode(ProfilesFile.self, from: data)
        } else {
            self.file = .empty
        }
    }

    /// Persists the current state to disk atomically.
    public func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(file)
        try data.write(to: url, options: .atomic)
    }
}
