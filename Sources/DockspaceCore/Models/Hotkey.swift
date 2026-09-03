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
        return prefix + Self.label(forKeyCode: keyCode)
    }

    /// Maps Carbon virtual key codes to display labels for the most
    /// common keys (letters, digits, a few symbols). Anything else
    /// renders as `Key N` so the binding is still inspectable.
    static func label(forKeyCode code: UInt16) -> String {
        let table: [UInt16: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
            0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
            0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
            0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=", 0x19: "9",
            0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
            0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P",
            0x25: "L", 0x26: "J", 0x27: "'", 0x28: "K", 0x29: ";",
            0x2A: "\\", 0x2B: ",", 0x2C: "/", 0x2D: "N", 0x2E: "M",
            0x2F: ".", 0x31: "Space", 0x33: "Delete", 0x35: "Escape",
            0x24: "Return", 0x30: "Tab", 0x7B: "←", 0x7C: "→",
            0x7D: "↓", 0x7E: "↑"
        ]
        return table[code] ?? "Key\(code)"
    }
}
