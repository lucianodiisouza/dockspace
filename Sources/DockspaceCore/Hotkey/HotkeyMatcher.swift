import Foundation

/// Strategy that decides whether a given keystroke matches a
/// `Hotkey`. Defined as a protocol so tests can inject a stub without
/// pulling AppKit into the Core layer.
public protocol HotkeyMatcher: Sendable {
    func matches(keyCode: UInt16, modifiers: HotkeyModifiers) -> Bool
}

extension Hotkey {
    /// Returns true if this hotkey matches the supplied key code and
    /// modifier set.
    public func matches(keyCode otherCode: UInt16, modifiers otherModifiers: HotkeyModifiers) -> Bool {
        return keyCode == otherCode && modifiers == otherModifiers
    }
}
