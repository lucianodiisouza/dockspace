import Foundation

/// A user-defined keyboard shortcut the app recognizes globally.
///
/// `keyCode` is the Carbon virtual key code (matches `NSEvent.keyCode`
/// and `CGKeyCode`). We store the key code rather than the character
/// so layouts other than QWERTY still work.
public struct Hotkey: Codable, Equatable, Hashable, Sendable {
    public let keyCode: UInt16
    public let modifiers: HotkeyModifiers

    public init(keyCode: UInt16, modifiers: HotkeyModifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// Human-readable label suitable for display in menus and editors.
    /// Letter keys render uppercase; everything else falls back to the
    /// key code so the user can see the binding even when the symbol
    /// is unknown.
    public var displayString: String {
        let prefix = modifiers.displaySymbols
        let keyLabel: String
        if let scalar = UnicodeScalar(keyCode), (0x20...0x7E).contains(scalar.value) {
            keyLabel = String(Character(scalar)).uppercased()
        } else {
            keyLabel = "Key\(keyCode)"
        }
        return prefix + keyLabel
    }
}
