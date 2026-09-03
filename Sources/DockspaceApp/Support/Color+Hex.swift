import SwiftUI

/// Bridges the `ProfileColor.hex` strings used in `DockspaceCore` to
/// SwiftUI's `Color`. Kept in the app layer so `DockspaceCore` stays
/// UI-free.
extension Color {
  /// Initializes a `Color` from a `#RRGGBB` hex string. Returns
  /// `.gray` on malformed input rather than crashing — colors are
  /// cosmetic, never mission critical.
  init(hex: String) {
    var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.hasPrefix("#") { trimmed.removeFirst() }

    guard trimmed.count == 6, let value = UInt32(trimmed, radix: 16) else {
      self = .gray
      return
    }

    let r = Double((value >> 16) & 0xFF) / 255.0
    let g = Double((value >> 8) & 0xFF) / 255.0
    let b = Double(value & 0xFF) / 255.0
    self = Color(red: r, green: g, blue: b)
  }
}
