import Foundation

/// Resolves where Dockspace stores its own files inside
/// `~/Library/Application Support/Dockspace/`. Kept separate from the
/// Dock plist resolver because that one reads system state while this
/// one writes our own data.
public enum StoragePath {
    public static let appSupportDirectoryName = "Dockspace"
    public static let profilesFileName = "profiles.json"
    public static let backupsDirectoryName = "backups"

    /// Returns the URL to the Dockspace folder under Application
    /// Support, creating it if necessary.
    public static func appSupportDirectory(create: Bool = true) throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: create
        )
        let dir = base.appendingPathComponent(appSupportDirectoryName, isDirectory: true)
        if create {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    public static func profilesFileURL() throws -> URL {
        try appSupportDirectory().appendingPathComponent(profilesFileName)
    }

    public static func backupsDirectory() throws -> URL {
        let dir = try appSupportDirectory().appendingPathComponent(backupsDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
