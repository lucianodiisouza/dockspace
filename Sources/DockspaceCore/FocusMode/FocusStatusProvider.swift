import Foundation
import Intents

/// Read-only view of the current macOS Focus status. Defined as a
/// protocol so tests can inject a stub without pulling Intents into
/// the public module surface.
///
/// `isFocused` is `Bool?` because the system returns `nil` until the
/// user has granted `INFocusStatusCenter` authorization via the
/// Communication Notifications capability. We treat nil as "unknown"
/// and let the app decide whether to surface a prompt.
public protocol FocusStatusProvider: Sendable {
    var isFocused: Bool? { get }
    var isAuthorized: Bool { get }
}

/// Production implementation that bridges to `INFocusStatusCenter`.
public final class SystemFocusStatusProvider: FocusStatusProvider, @unchecked Sendable {
    public init() {}

    public var isFocused: Bool? {
        INFocusStatusCenter.default.focusStatus.isFocused
    }

    public var isAuthorized: Bool {
        INFocusStatusCenter.default.authorizationStatus == .authorized
    }
}
