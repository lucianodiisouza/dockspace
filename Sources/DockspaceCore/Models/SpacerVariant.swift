import Foundation

/// Variants of the spacer tile the macOS Dock supports.
///
/// Raw values match the `tile-type` strings used inside
/// `com.apple.dock.plist` so we can encode/decode without a translation
/// table.
public enum SpacerVariant: String, Codable, Equatable, Hashable, CaseIterable, Sendable {
    /// A fixed-width small spacer (introduced in macOS Ventura).
    case small = "small-spacer-tile"

    /// A flexible spacer that absorbs leftover space when the Dock is
    /// wider than the sum of its items.
    case flex = "flex-spacer-tile"

    /// Legacy default spacer kept for compatibility with older plists.
    case `default` = "spacer-tile"
}
