import XCTest
@testable import DockspaceCore

final class HotkeyTests: XCTestCase {
    func test_matches_returnsTrueForSameKeyAndModifiers() {
        let hotkey = Hotkey(keyCode: 0x31 /* space */, modifiers: [.command, .shift])
        XCTAssertTrue(hotkey.matches(keyCode: 0x31, modifiers: [.command, .shift]))
    }

    func test_matches_returnsFalseForDifferentKey() {
        let hotkey = Hotkey(keyCode: 0x31, modifiers: [.command])
        XCTAssertFalse(hotkey.matches(keyCode: 0x32, modifiers: [.command]))
    }

    func test_matches_returnsFalseForDifferentModifiers() {
        let hotkey = Hotkey(keyCode: 0x31, modifiers: [.command])
        XCTAssertFalse(hotkey.matches(keyCode: 0x31, modifiers: [.command, .shift]))
    }

    func test_displayString_rendersModifiersInCanonicalOrder() {
        let hotkey = Hotkey(keyCode: 0x00 /* A */, modifiers: [.shift, .command, .option, .control])
        // Canonical order is control, option, shift, command.
        XCTAssertEqual(hotkey.displayString, "⌃⌥⇧⌘A")
    }

    func test_displayString_uppercasesLetterKeys() {
        let hotkey = Hotkey(keyCode: 0x1F /* O */, modifiers: [.command])
        XCTAssertEqual(hotkey.displayString, "⌘O")
    }
}
