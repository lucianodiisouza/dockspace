import Foundation
import Intents

/// Read-only view of the current macOS Focus status. Defined as a
/// protocol so tests can inject a stub without pulling Intents into
/// the public module surface.
public protocol FocusStatusProvider: Sendable {
    var isFocused: Bool { get }
    var focusIdentifier: String? { get }
}

/// Production implementation that bridges to `INFocusStatusCenter`.
public final class SystemFocusStatusProvider: FocusStatusProvider, @unchecked Sendable {
    public init() {}

    public var isFocused: Bool {
        INFocusStatusCenter.default.focusStatus.isFocused
    }

    public var focusIdentifier: String? {
        INFocusStatusCenter.default.focusStatus.focusedActivityIdentifier
    }
}
