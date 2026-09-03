import Foundation

/// A named, color-tagged set of Dock items the user can switch to.
///
/// Profiles are the unit the user manages: each one is a saved
/// "what my Dock should look like" target. Switching is `snapshot →
/// swap(to: target)`.
public struct Profile: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var color: ProfileColor
    public var items: [DockItem]
    public var focusModeBinding: String?

    public init(
        id: UUID = UUID(),
        name: String,
        color: ProfileColor = .blue,
        items: [DockItem] = [],
        focusModeBinding: String? = nil
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.items = items
        self.focusModeBinding = focusModeBinding
    }

    /// Snapshot the profile is equivalent to. Used when swapping.
    public func snapshot() -> DockSnapshot {
        DockSnapshot(apps: items, others: [], capturedAt: Date())
    }
}

/// Curated palette. Hex values match the swatches shown in the menu bar
/// popover so the user gets a stable visual identity.
public enum ProfileColor: String, Codable, Equatable, Hashable, CaseIterable, Sendable {
    case blue
    case pink
    case orange
    case green
    case purple
    case graphite

    /// Hex string in `#RRGGBB` form, suitable for SwiftUI's `Color(hex:)`.
    public var hex: String {
        switch self {
        case .blue: return "#6670F5"
        case .pink: return "#E86A9F"
        case .orange: return "#F59E0B"
        case .green: return "#22C55E"
        case .purple: return "#A855F7"
        case .graphite: return "#6B7280"
        }
    }
}
