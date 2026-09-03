import Foundation

/// On-disk envelope for the profile collection. Wraps the array of
/// profiles with a schema version so we can migrate later without
/// breaking existing user files.
public struct ProfilesFile: Codable, Equatable, Sendable {
    /// Bump when the schema changes in a non-backward-compatible way.
    public static let currentVersion = 1

    public var version: Int
    public var activeProfileId: UUID?
    public var profiles: [Profile]

    public init(
        version: Int = ProfilesFile.currentVersion,
        activeProfileId: UUID? = nil,
        profiles: [Profile] = []
    ) {
        self.version = version
        self.activeProfileId = activeProfileId
        self.profiles = profiles
    }

    /// Empty file with the current schema version. The default for a
    /// user who has never opened the app.
    public static let empty = ProfilesFile()
}
