import Foundation

/// Modifier keys for a global hotkey. Wraps `NSEvent.ModifierFlags`
/// with a stable, `Codable`, `OptionSet` shape the rest of the app
/// can persist and reason about without importing AppKit.
public struct HotkeyModifiers: OptionSet, Codable, Equatable, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let command = HotkeyModifiers(rawValue: 1 << 0)
    public static let option  = HotkeyModifiers(rawValue: 1 << 1)
    public static let control = HotkeyModifiers(rawValue: 1 << 2)
    public static let shift   = HotkeyModifiers(rawValue: 1 << 3)

    /// Canonical ordering used when rendering the display string so
    /// ⌃⌥⌘⇧ always appears in the same order regardless of how the
    /// user assembled the set.
    public var displaySymbols: String {
        var symbols = ""
        if contains(.control) { symbols += "⌃" }
        if contains(.option)  { symbols += "⌥" }
        if contains(.shift)   { symbols += "⇧" }
        if contains(.command) { symbols += "⌘" }
        return symbols
    }
}
