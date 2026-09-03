import Foundation

/// A URL pinned on the Dock (e.g. a folder shown as a stack via its
/// `file://` URL, or a webpage). Used for entries under
/// `persistent-others`.
public struct URLEntry: Codable, Equatable, Hashable, Sendable {
    public let url: String
    public let displayName: String?

    public init(url: String, displayName: String? = nil) {
        self.url = url
        self.displayName = displayName
    }
}
