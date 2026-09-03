import Foundation

/// A regular file (not a `.app` bundle) shown on the Dock as a stack or
/// directly. Used for entries under `persistent-others`.
public struct FileEntry: Codable, Equatable, Hashable, Sendable {
    public let path: String
    public let displayName: String?
    public let isDirectory: Bool

    public init(path: String, displayName: String? = nil, isDirectory: Bool = false) {
        self.path = path
        self.displayName = displayName
        self.isDirectory = isDirectory
    }
}
