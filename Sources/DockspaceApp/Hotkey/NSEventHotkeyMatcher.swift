import AppKit
import DockspaceCore

/// Bridges real `NSEvent` instances to the codable `Hotkey` model used
/// in the Core layer. Used by the hotkey recorder UI in
/// `ProfileDetailView` and by `GlobalHotkeyManager` for matching.
enum HotkeyFromNSEvent {
    /// Builds a `Hotkey` from a real `NSEvent.keyDown`. Returns nil
    /// if the event is not a key down, or if it carries no modifier
    /// flags (we refuse to register plain letters as hotkeys since
    /// they would hijack regular typing).
    static func hotkey(from event: NSEvent) -> Hotkey? {
        guard event.type == .keyDown else { return nil }
        let keyCode = UInt16(event.keyCode)
        let mods = modifiers(from: event.modifierFlags)
        guard !mods.isEmpty else { return nil }
        return Hotkey(keyCode: keyCode, modifiers: mods)
    }

    static func modifiers(from flags: NSEvent.ModifierFlags) -> HotkeyModifiers {
        var result: HotkeyModifiers = []
        if flags.contains(.command) { result.insert(.command) }
        if flags.contains(.option)  { result.insert(.option) }
        if flags.contains(.control) { result.insert(.control) }
        if flags.contains(.shift)   { result.insert(.shift) }
        return result
    }
}
